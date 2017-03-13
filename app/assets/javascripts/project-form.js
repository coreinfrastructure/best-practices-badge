// This JavaScript supporting implementing the per project form used
// for showing and editing information about a project.

var criterionCategoryValue = {};
var criteriaMetUrlRequired = {};
var criteriaMetJustificationRequired = {};
var criteriaNAJustificationRequired = {};
var criterionFuture = {};
var MIN_SHOULD_LENGTH = 5;

// Global - name of criterion we last selected as 'met'.
// Don't hide this criterion (yet), so that users can enter a justification.
var globalLastSelectedMet = '';
var globalHideMetnaCriteria = false;
var globalShowAllDetails = false;
var globalExpandAllPanels = false;
var globalIgnoreHashChange = false;

// Do a polyfill for datalist if it's not already supported
// (e.g., Safari fails to support polyfill at the time of this writing).
// See https://github.com/thgreasi/datalist-polyfill/blob/master/README.md
function polyfillDatalist() {
  var nativedatalist = !!('list' in document.createElement('input')) &&
      !!(document.createElement('datalist') && window.HTMLDataListElement);
  if (!nativedatalist) {
    $('input[list]').each(function() {
      var availableTags = $('#' + $(this).attr('list')).find('option').map(
        function() {
          return this.value;
        }).get();
      $(this).autocomplete({ source: availableTags });
    });
  }
}

// This gives a color based upon value from 0 to 1 going from
// red to green.  Based upon code from user jongobar at
// http://jsfiddle.net/jongobar/sNKWK/
// See also jongo45's answer at:
// http://stackoverflow.com/questions/7128675/
// from-green-to-red-color-depend-on-percentage
function getColor(value) {
  //value from 0 to 1
  var hue = (value * 120).toString(10);
  return ['hsl(', hue, ', 100%, 50%)'].join('');
}

// Note: This regex needs to be logically the same as the one used in
// the server-side badge calculation, or it may confuse some users.
// See app/models/project.rb function "contains_url?".
function containsURL(justification) {
  if (!justification) {
    return false;
  } else {
    return !!justification.match(/https?:\/\/[^ ]{5}/);
  }
}

// Determine result for a given criterion, which is one of
// passing, barely, failing, or question.
// The result calculation here must match the equivalent routine
// implemented on the server to prevent confusion.
function criterionResult(criterion) {
  var criterionStatus = '#project_' + criterion + '_status';
  var justification = $('#project_' + criterion + '_justification').val();
  if (!justification) {
    justification = '';
  }
  if ($(criterionStatus + '_na').is(':checked')) {
    if (!criteriaNAJustificationRequired[criterion] ||
        justification.length >= MIN_SHOULD_LENGTH) {
      return 'passing';
    } else {
      return 'question';
    }
  } else if ($(criterionStatus + '_met').is(':checked')) {
    if ((criteriaMetUrlRequired[criterion] && !containsURL(justification)) ||
        (criteriaMetJustificationRequired[criterion] &&
         justification.length <= MIN_SHOULD_LENGTH)) {
      // Odd case: met is claimed, but we're still missing information.
      return 'question';
    } else {
      return 'passing';
    }
  } else if (criterionCategoryValue[criterion] === 'SHOULD' &&
             $(criterionStatus + '_unmet').is(':checked') &&
             justification.length >= MIN_SHOULD_LENGTH) {
    return 'barely';
  } else if (criterionCategoryValue[criterion] === 'SUGGESTED' &&
            !($(criterionStatus + '_').is(':checked'))) {
    return 'barely';
  } else if ($(criterionStatus + '_').is(':checked')) {
    return 'question';
  } else {
    return 'failing';
  }
}

// This must match the criteria implemented in Ruby to prevent confusion.
function isEnough(criterion) {
  var result = criterionResult(criterion);
  return (result === 'passing' || result === 'barely');
}

// Set a panel's satisfaction level.
function setPanelSatisfactionLevel(panel) {
  var total = 0;
  var enough = 0;
  $(panel).find('.criterion-name').each(function(index) {
    var criterion = $(this).text();
    total++;
    if (isEnough(criterion)) {
      enough++;
    }
  });
  var satisfaction = $(panel).find('.satisfaction');
  $(satisfaction).find('.satisfaction-text')
                 .text(enough.toString() + '/' + total.toString());
  $(satisfaction).find('.satisfaction-bullet')
                 .css({ 'color' : getColor(enough / total) });
}

function resetProgressBar() {
  var total = 0;
  var enough = 0;
  var percentage;
  var percentAsString;
  $.each(criterionCategoryValue, function(key, value) {
    if (!criterionFuture[key]) { // Only include non-future values
      total++;
      if (isEnough(key)) {
        enough++;
      }
    }
  });
  percentage = enough / total;
  percentAsString = Math.round(percentage * 100).toString() + '%';
  $('#badge-progress').attr('aria-valuenow', percentage)
                      .text(percentAsString).css('width', percentAsString);
}

function resetProgressAndSatisfaction(criteria) {
  var criteriaJust = '#project_' + criteria + '_justification';
  setPanelSatisfactionLevel($(criteriaJust).parents('.panel'));
  resetProgressBar();
}

function resetCriterionResult(criterion) {
  var result = criterionResult(criterion);
  if (result === 'passing') {
    $('#' + criterion + '_enough').
        attr('src', $('#result_symbol_check_img').attr('src')).
        attr('width', 40).attr('height', 40).
        attr('alt', 'Enough for a badge!');
  } else if (result === 'barely') {
    $('#' + criterion + '_enough').
        attr('src', $('#result_symbol_dash').attr('src')).
        attr('width', 40).attr('height', 40).
        attr('alt', 'Not enough for a badge.');
  } else if (result === 'question') {
    $('#' + criterion + '_enough').
        attr('src', $('#result_symbol_question').attr('src')).
        attr('width', 40).attr('height', 40).
        attr('alt', 'Not enough for a badge.');
  } else {
    $('#' + criterion + '_enough').
        attr('src', $('#result_symbol_x_img').attr('src')).
        attr('width', 40).attr('height', 40).
        attr('alt', 'Not enough for a badge.');
  }
}

function changedJustificationText(criteria) {
  var criteriaJust = '#project_' + criteria + '_justification';
  var criteriaStatus = '#project_' + criteria + '_status';
  if ($(criteriaStatus + '_unmet').is(':checked') &&
       (criterionCategoryValue[criteria] === 'SHOULD') &&
       ($(criteriaJust).val().length < MIN_SHOULD_LENGTH)) {
    $(criteriaJust).addClass('required-data');
  } else if ($(criteriaStatus + '_met').is(':checked') &&
             ((criteriaMetUrlRequired[criteria] &&
               !containsURL($(criteriaJust).val())) ||
              (criteriaMetJustificationRequired[criteria] &&
               $(criteriaJust).val().length < MIN_SHOULD_LENGTH))) {
    $(criteriaJust).addClass('required-data');
  } else if ($(criteriaStatus + '_na').is(':checked') &&
       (criteriaNAJustificationRequired[criteria]) &&
       ($(criteriaJust).val().length < MIN_SHOULD_LENGTH)) {
    $(criteriaJust).addClass('required-data');
  } else {
    $(criteriaJust).removeClass('required-data');
  }
  resetCriterionResult(criteria);
}

function changedJustificationTextAndUpdate(criteria) {
  changedJustificationText(criteria);
  resetProgressAndSatisfaction(criteria);
}

// Do we have any text in this field region?  Handle the variations.
function hasFieldTextInside(e) {
  var i;
  i = e.find('input[type="text"]');
  if (i && i.val()) {
    return true;
  }
  i = e.find('textarea');
  if (i && i.val()) {
    return true;
  }
  i = e.find('.discussion-markdown');
  if (i && i.text()) {
    return true;
  }
  return false;
}

// If we should, hide the criteria that are "Met" or N/A and are enough.
// Do NOT hide 'met' criteria that aren't enough (e.g., missing required URL),
// and do NOT hide the last-selected-met criterion (so users can enter/edit
// justification text).
function hideMetNA() {
  $.each(criterionCategoryValue, function(key, value) {
    if (globalHideMetnaCriteria && key !== globalLastSelectedMet &&
        ($('#project_' + key + '_status_met').is(':checked') ||
         $('#project_' + key + '_status_na').is(':checked')) &&
        isEnough(key)) {
      $('#' + key).addClass('hidden');
    } else {
      $('#' + key).removeClass('hidden');
    }
  });
  $('.hidable-text-entry').each(function() {
    if (globalHideMetnaCriteria && hasFieldTextInside($(this))) {
      $(this).addClass('hidden');
    } else {
      $(this).removeClass('hidden');
    }
  });
}

function updateCriteriaDisplay(criteria) {
  var criteriaJust = '#project_' + criteria + '_justification';
  var criteriaStatus = '#project_' + criteria + '_status';
  var justificationElement = document.getElementById('project_' +
                           criteria + '_justification');
  var justificationValue = '';
  if (justificationElement) {
    justificationValue = justificationElement.value;
  }
  if ($(criteriaStatus + '_met').is(':checked')) {
    var criteriaMetPlaceholder = criteria + '_met_placeholder';
    $(criteriaJust).
       attr('placeholder',
         $('#' + criteriaMetPlaceholder).html().trim());
    if (document.getElementById(criteria + '_met_suppress')) {
      $(criteriaJust).hide('fast');
    } else {
      $(criteriaJust).show('fast');
    }
  } else if ($(criteriaStatus + '_unmet').is(':checked')) {
    var criteriaUnmetPlaceholder = criteria + '_unmet_placeholder';
    $(criteriaJust).
       attr('placeholder',
         $('#' + criteriaUnmetPlaceholder).html().trim());
    if (document.getElementById(criteria + '_unmet_suppress')) {
      $(criteriaJust).hide('fast');
    } else {
      $(criteriaJust).show('fast');
    }
  } else if ($(criteriaStatus + '_na').is(':checked')) {
    var criteriaNaPlaceholder = criteria + '_na_placeholder';
    $(criteriaJust).
       attr('placeholder',
         $('#' + criteriaNaPlaceholder).html().trim());
    if (document.getElementById(criteria + '_na_suppress')) {
      $(criteriaJust).hide('fast');
    } else {
      $(criteriaJust).show('fast');
    }
  } else if ($(criteriaStatus + '_').is(':checked')) {
    $(criteriaJust).attr('placeholder', 'Please explain');
    $(criteriaJust).hide('fast');
  }
  // If there's old justification text, force showing it even if it
  // no longer makes sense (so they can fix it or change their mind).
  if (justificationValue.length > 0) {
    $(criteriaJust).show('fast');
  }
  if (globalHideMetnaCriteria) {
    // If we're hiding met criteria, walk through and hide them.
    // We don't need to keep running this if we are NOT hiding them,
    // which is the normal case.
    hideMetNA();
  }
  changedJustificationText(criteria);
}

function updateCriteriaDisplayAndUpdate(criteria) {
  updateCriteriaDisplay(criteria);
  resetProgressAndSatisfaction(criteria);
}


function changeCriterion(criterion) {
  var criterionStatus = '#project_' + criterion + '_status';
  if ($(criterionStatus + '_met').is(':checked')) {
    globalLastSelectedMet = criterion;
  }
  updateCriteriaDisplayAndUpdate(criterion);
}

function ToggleHideMet(e) {
  globalHideMetnaCriteria = !globalHideMetnaCriteria;
  // Note that button text shows what WILL happen on click, so it
  // shows the REVERSED state (not the current state).
  if (globalHideMetnaCriteria) {
    $('#toggle-hide-metna-criteria')
      .addClass('active').html('Show met and N/A criteria');
  } else {
    $('#toggle-hide-metna-criteria')
      .removeClass('active').html('Hide met or N/A criteria');
  }
  hideMetNA();
}

function expandAllPanels() {
  if (globalExpandAllPanels) {
    globalIgnoreHashChange = true;
    $('.can-collapse.collapsed').click();
    location.hash = '#all';
    globalIgnoreHashChange = false;
  } else {
    $('.can-collapse:not(.collapsed)').click();
    location.hash = '';
  }
}

function ToggleExpandAllPanels(e) {
  globalExpandAllPanels = !globalExpandAllPanels;
  // Note that button text shows what WILL happen on click, so it
  // shows the REVERSED state (not the current state).
  if (globalExpandAllPanels) {
    $('#toggle-expand-all-panels')
      .addClass('active').html('Collapse all panels');
  } else {
    $('#toggle-expand-all-panels')
      .removeClass('active').html('Expand all panels');
  }
  expandAllPanels();
}

function showHash() {
  if ($(window.location.hash).length) {
    var parentPane = $(window.location.hash).parents('.panel');
    if (parentPane) {
      var loc = $(parentPane).find('.can-collapse');
      globalIgnoreHashChange = true;
      if ($(loc).hasClass('collapsed')) {
        loc.click();
      }
      globalIgnoreHashChange = false;
      // We need to wait a bit for animations to finish before scrolling.
      $(parentPane).find('.panel-collapse')
        .on('shown.bs.collapse', function() {
          var offset = $(window.location.hash).offset();
          if (offset) {
            var scrollto = offset.top - 100; // minus fixed header height
            $('html, body').animate({scrollTop:scrollto}, 0);
          }
        });
    }
  }
}

function getAllPanelsReady() {
  $('.can-collapse').addClass('clickable');
  $('.can-collapse').find('i.glyphicon').addClass('glyphicon-chevron-up');
  var loc = window.location.hash;
  if (loc !== '#all') {
    if (loc !== null && loc !== '' && $(loc).length !== 0 &&
        $(loc).parents('.panel') !== null) {
      $('.collapse').removeClass('in');
      $('.can-collapse').addClass('collapsed');
      $('.can-collapse').find('i.glyphicon')
        .addClass('glyphicon-chevron-down')
        .removeClass('glyphicon-chevron-up');
      showHash();
    } else {
      $('.remove-in').removeClass('in');
      $('.close-by-default').addClass('collapsed');
      $('.close-by-default').find('i.glyphicon')
        .addClass('glyphicon-chevron-down')
        .removeClass('glyphicon-chevron-up');
    }
  }
  // Set the satisfaction level in each panel
  $('.satisfaction-bullet').append('&#9679;');
  $('.panel').each(function(index) {
    setPanelSatisfactionLevel(this);
  });
}

function setupProjectField(criteria) {
  updateCriteriaDisplay(criteria);
  $('input[name="project[' + criteria + '_status]"]').click(
      function() {
        changeCriterion(criteria);
      });
  $('input[name="project[' + criteria + '_justification]"]').blur(
      function() {
        updateCriteriaDisplayAndUpdate(criteria);
      });
  $('#project_' + criteria + '_justification').on('input',
      function() {
        changedJustificationTextAndUpdate(criteria);
      });
  $('#project_' + criteria + '_justification').on('keyup',
      function() {
        changedJustificationTextAndUpdate(criteria);
      });
}

function ToggleDetailsDisplay(e) {
  var detailsTextID = e.target.id.
                        replace('_details_toggler', '_details_text');
  $('#' + detailsTextID).toggle('fast',
    function() {
      var buttonText;
      if ($('#' + detailsTextID).is(':hidden')) {
        buttonText = 'Show details';
      } else {
        buttonText = 'Hide details';
      }
      $('#' + e.target.id).html(buttonText);
    });
}

function ToggleAllDetails(e) {
  globalShowAllDetails = !globalShowAllDetails;
  // Note that button text shows what WILL happen on click, so it
  // shows the REVERSED state (not the current state).
  if (globalShowAllDetails) {
    $('#toggle-show-all-details')
      .addClass('active').html('Hide all detailed text');
    $('.details-text').show('fast');
    $('.details-toggler').html('Hide details');
  } else {
    $('#toggle-show-all-details')
      .removeClass('active').html('Show all detailed text');
    $('.details-text').hide('fast');
    $('.details-toggler').html('Show details');
  }
}

// Create mappings from criteria name to category and met_url_required.
// Eventually replace with just accessing classes directly via JavaScript.
function SetupCriteriaStructures() {
  $('.status-chooser').each(
    function(index) {
      var criterionName = $(this).find('.criterion-name').text();
      var res = $(this).find('.criterion-met-justification-required').text();
      var val = 'true' === res;
      criteriaMetJustificationRequired[criterionName] = val;
      criteriaMetUrlRequired[criterionName] =
        $(this).find('.criterion-met-url-required').text() === 'true';
      criterionCategoryValue[criterionName] =
        $(this).find('.criterion-category').text();
      criterionFuture[criterionName] =
        $(this).find('.criterion-future').text() === 'true';
      criteriaNAJustificationRequired[criterionName] =
        $(this).find('.criterion-na-justification-required').text() === 'true';
    }
  );
}

function setupProjectForm() {
  // By default, hide details.  We do the hiding in JavaScript, so
  // those who disable JavaScript will still see the text
  // (they'll have no way to later reveal it).
  $('.details-text').hide('fast');
  $('.details-toggler').html('Show details');
  $('.details-toggler').click(ToggleDetailsDisplay);

  // Force these values on page reload
  globalShowAllDetails = false;
  $('#toggle-show-all-details').click(function(e) {
    ToggleAllDetails(e);
  });

  // Force these values on page reload
  globalLastSelectedMet = '';
  globalHideMetnaCriteria = false;
  $('#toggle-hide-metna-criteria').click(function(e) {
    ToggleHideMet(e);
  });

  SetupCriteriaStructures();

  // Implement "press this button to make all crypto N/A"
  $('#all_crypto_na').click(function(e) {
    $.each(criterionCategoryValue, function(key, value) {
      if ((/^crypto/).test(key)) {
        $('#project_' + key + '_status_na').prop('checked', true);
      }
      updateCriteriaDisplay(key);
      resetCriterionResult(key);
    });
    setPanelSatisfactionLevel($('#all_crypto_na').parents('.panel'));
    resetProgressBar();
  });

  // Use "imagesloaded" to wait for image load before displaying them
  imagesLoaded(document).on('always', function(instance) {
    // Set up the interactive displays of "enough".
    $.each(criterionCategoryValue, function(key, value) {
      setupProjectField(key);
    });
    resetProgressBar();
  });

  globalExpandAllPanels = false;
  $('#toggle-expand-all-panels').click(function(e) {
    ToggleExpandAllPanels(e);
  });

  $('.panel div.can-collapse').on('click', function(e) {
    var $this = $(this);
    if ($this.hasClass('collapsed')) {
      $this.parents('.panel').find('.panel-collapse').collapse('show');
      $this.removeClass('collapsed');
      $this.find('i.glyphicon').removeClass('glyphicon-chevron-down')
        .addClass('glyphicon-chevron-up');
      if (!globalIgnoreHashChange) {
        var origId = this.getAttribute('id');
        // prevent scrolling on panel open
        this.id = origId + '-tmp';
        location.hash = '#' + origId;
        this.id = origId;
      }
    } else {
      $this.parents('.panel').find('.panel-collapse').collapse('hide');
      $this.addClass('collapsed');
      $this.find('i.glyphicon').removeClass('glyphicon-chevron-up')
        .addClass('glyphicon-chevron-down');
    }
  });

  getAllPanelsReady();

  $(window).on('hashchange', function(e) {
    if (!globalIgnoreHashChange && $(window.location.hash).length) {
      showHash();
    }
  });
}

// Setup display as soon as page is ready
$(document).ready(function() {
  $('[data-toggle="tooltip"]').tooltip(); // Enable bootstrap tooltips

  // A form element with class onchange-submit automatically submits its
  // form whenever it is changed.
  $('.onchange-submit').change(function() {
    $(this).parents('form').submit();
  });

  if ($('#project_entry_form').length) {
    setupProjectForm();
  }

  // Polyfill datalist (for Safari users)
  polyfillDatalist();
});
