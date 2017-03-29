// This JavaScript supporting implementing the per project form used
// for showing and editing information about a project.

// This global constant is set in criteria.js ; let ESLint know about it.
/* global CRITERIA_HASH */

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

// Return if criterion's value for key is true in CRITERIA_HASH (default false)
function criterionHashTrue(criterion, key) {
  return CRITERIA_HASH[criterion][key] === true;
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
    if (!criterionHashTrue(criterion, 'na_justification_required') ||
        justification.length >= MIN_SHOULD_LENGTH) {
      return 'passing';
    } else {
      return 'question';
    }
  } else if ($(criterionStatus + '_met').is(':checked')) {
    if ((criterionHashTrue(criterion, 'met_url_required') &&
          !containsURL(justification)) ||
        (criterionHashTrue(criterion, 'met_justification_required') &&
         justification.length <= MIN_SHOULD_LENGTH)) {
      // Odd case: met is claimed, but we're still missing information.
      return 'question';
    } else {
      return 'passing';
    }
  } else if ($(criterionStatus + '_unmet').is(':checked')) {
    if (CRITERIA_HASH[criterion]['category'] === 'SUGGESTED' ||
        (CRITERIA_HASH[criterion]['category'] === 'SHOULD' &&
         justification.length >= MIN_SHOULD_LENGTH)) {
      return 'barely';
    } else if (CRITERIA_HASH[criterion]['category'] === 'SHOULD') {
      return 'question';
    } else {
      return 'failing';
    }
  } else {
    return 'question';
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
  $.each(CRITERIA_HASH, function(criterion, value) {
    if (!criterionHashTrue(criterion, 'future')) { // Ignore "future" criteria
      total++;
      if (isEnough(criterion)) {
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
  var destination = $('#' + criterion + '_enough');
  if (result === 'passing') {
    destination.attr('src', $('#result_symbol_check_img').attr('src')).
      attr('width', 40).attr('height', 40).
      attr('alt', 'Enough for a badge!');
  } else if (result === 'barely') {
    destination.attr('src', $('#result_symbol_dash').attr('src')).
      attr('width', 40).attr('height', 40).
      attr('alt', 'Barely enough for a badge.');
  } else if (result === 'question') {
    destination.attr('src', $('#result_symbol_question').attr('src')).
      attr('width', 40).attr('height', 40).
      attr('alt', 'Unknown required information, not enough for a badge.');
  } else {
    destination.attr('src', $('#result_symbol_x_img').attr('src')).
      attr('width', 40).attr('height', 40).
      attr('alt', 'Not enough for a badge.');
  }
}

function changedJustificationText(criteria) {
  var criteriaJust = '#project_' + criteria + '_justification';
  var criteriaStatus = '#project_' + criteria + '_status';
  if ($(criteriaStatus + '_unmet').is(':checked') &&
       (CRITERIA_HASH[criteria]['category'] === 'SHOULD') &&
       ($(criteriaJust).val().length < MIN_SHOULD_LENGTH)) {
    $(criteriaJust).addClass('required-data');
  } else if ($(criteriaStatus + '_met').is(':checked') &&
             ((criterionHashTrue(criteria, 'met_url_required') &&
               !containsURL($(criteriaJust).val())) ||
              (criterionHashTrue(criteria, 'met_justification_required') &&
               $(criteriaJust).val().length < MIN_SHOULD_LENGTH))) {
    $(criteriaJust).addClass('required-data');
  } else if ($(criteriaStatus + '_na').is(':checked') &&
       criterionHashTrue(criteria, 'na_justification_required') &&
       ($(criteriaJust).val().length < MIN_SHOULD_LENGTH)) {
    $(criteriaJust).addClass('required-data');
  } else {
    $(criteriaJust).removeClass('required-data');
  }
}

function changedJustificationTextAndUpdate(criterion) {
  changedJustificationText(criterion);
  resetCriterionResult(criterion);
  resetProgressAndSatisfaction(criterion);
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
  $.each(CRITERIA_HASH, function(criterion, value) {
    if (globalHideMetnaCriteria && criterion !== globalLastSelectedMet &&
        ($('#project_' + criterion + '_status_met').is(':checked') ||
         $('#project_' + criterion + '_status_na').is(':checked')) &&
        isEnough(criterion)) {
      $('#' + criterion).addClass('hidden');
    } else {
      $('#' + criterion).removeClass('hidden');
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

function updateCriteriaDisplay(criterion) {
  var criterionJust = '#project_' + criterion + '_justification';
  var criterionStatus = '#project_' + criterion + '_status';
  var justificationElement = document.getElementById('project_' +
                           criterion + '_justification');
  var justificationValue = '';
  var criterionPlaceholder;
  var suppressJustificationDisplay;
  if (justificationElement) {
    justificationValue = justificationElement.value;
  }
  if ($(criterionStatus + '_met').is(':checked')) {
    criterionPlaceholder = CRITERIA_HASH[criterion]['met_placeholder'];
    if (!criterionPlaceholder) {
      if (criterionHashTrue(criterion, 'met_url_required')) {
        criterionPlaceholder = '(URL required) Please explain how this ' +
          'is met, including 1+ key URLs.';
      } else if (criterionHashTrue(criterion, 'met_justification_required')) {
        criterionPlaceholder = '(Required) Please explain how this ' +
          'is met, possibly including 1+ key URLs.';
      } else {
        criterionPlaceholder = '(Optional) Please explain how this ' +
          'is met, possibly including 1+ key URLs.';
      }
    }
    suppressJustificationDisplay = criterionHashTrue(criterion, 'met_suppress');
  } else if ($(criterionStatus + '_unmet').is(':checked')) {
    criterionPlaceholder = CRITERIA_HASH[criterion]['unmet_placeholder'];
    if (!criterionPlaceholder) {
      criterionPlaceholder = 'Please explain why it\'s okay this ' +
        'is unmet, including 1+ key URLs.';
    }
    suppressJustificationDisplay =
      criterionHashTrue(criterion, 'unmet_suppress');
  } else if ($(criterionStatus + '_na').is(':checked')) {
    criterionPlaceholder = CRITERIA_HASH[criterion]['na_placeholder'];
    if (!criterionPlaceholder) {
      if (criterionHashTrue(criterion, 'na_justification_required')) {
        criterionPlaceholder = '(Required) Please explain why this ' +
          'is not applicable (N/A), possibly including 1+ key URLs.';
      } else {
        criterionPlaceholder = '(Optional) Please explain why this ' +
          'is not applicable (N/A), possibly including 1+ key URLs.';
      }
    }
    suppressJustificationDisplay = criterionHashTrue(criterion, 'na_suppress');
  } else if ($(criterionStatus + '_').is(':checked')) {
    criterionPlaceholder = 'Please explain';
    suppressJustificationDisplay = true;
  }
  $(criterionJust).attr('placeholder', criterionPlaceholder);

  // If there's old justification text, force showing it even if it
  // no longer makes sense (so they can fix it or change their mind).
  if (justificationValue.length > 0) {
    $(criterionJust).css({'display':''});
  } else if (suppressJustificationDisplay) {
    $(criterionJust).css({'display':'none'});
  } else {
    $(criterionJust).css({'display':''});
  }
  if (globalHideMetnaCriteria) {
    // If we're hiding met criterion, walk through and hide them.
    // We don't need to keep running this if we are NOT hiding them,
    // which is the normal case.
    hideMetNA();
  }
  changedJustificationText(criterion);
}

function updateCriteriaDisplayAndUpdate(criterion) {
  updateCriteriaDisplay(criterion);
  resetCriterionResult(criterion);
  resetProgressAndSatisfaction(criterion);
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
      .addClass('active').html('Show met &amp; N/A')
      .prop('title', 'Show met & N/A criteria'); // Use & not &amp;
  } else {
    $('#toggle-hide-metna-criteria')
      .removeClass('active').html('Hide met &amp; N/A')
      .prop('title', 'Hide met & N/A criteria (leaving unmet and unknown');
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
      .addClass('active').html('Collapse panels');
  } else {
    $('#toggle-expand-all-panels')
      .removeClass('active').html('Expand panels');
  }
  expandAllPanels();
}

function scrollToHash() {
  var offset = $(window.location.hash).offset();
  if (offset) {
    var scrollto = offset.top - 100; // minus fixed header height
    $('html, body').animate({scrollTop:scrollto}, 0);
  }
}

function showHash() {
  if ($(window.location.hash).length) {
    var parentPane = $(window.location.hash).parents('.panel');
    if (parentPane.length) {
      var loc = $(parentPane).find('.can-collapse');
      if ($(loc).hasClass('collapsed')) {
        globalIgnoreHashChange = true;
        loc.click();
        globalIgnoreHashChange = false;
        // We need to wait a bit for animations to finish before scrolling.
        $(parentPane).find('.panel-collapse')
          .on('shown.bs.collapse', function() {
            scrollToHash();
          });
      } else {
        // This helps Chrome scroll to the right place on page load
        setTimeout(function() {
          scrollToHash();
        }, 0);
      }
    }
  }
}

function getAllPanelsReady() {
  $('.can-collapse').addClass('clickable');
  $('.can-collapse').find('i.glyphicon').addClass('glyphicon-chevron-up');
  var loc = window.location.hash;
  if (loc !== '#all') {
    var parentPanel = $(loc).parents('.panel');
    if (parentPanel.length) {
      $('.panel').not(parentPanel).find('.collapse').removeClass('in');
      $('.panel').not(parentPanel).find('.can-collapse').addClass('collapsed');
      $('.panel').not(parentPanel).find('.can-collapse').find('i.glyphicon')
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
  var buttonText;
  if ($('#' + detailsTextID).css('display') !== 'none') {
    buttonText = 'Show details';
    $('#' + detailsTextID).css({'display':'none'});
  } else {
    buttonText = 'Hide details';
    $('#' + detailsTextID).css({'display':''});
  }
  $('#' + e.target.id).html(buttonText);
}

function ToggleAllDetails(e) {
  globalShowAllDetails = !globalShowAllDetails;
  // Note that button text shows what WILL happen on click, so it
  // shows the REVERSED state (not the current state).
  if (globalShowAllDetails) {
    $('#toggle-show-all-details')
      .addClass('active').html('Hide all details');
    $('.details-text').css({'display':''});
    $('.details-toggler').html('Hide details')
      .prop('title', 'Hide all detailed text');
  } else {
    $('#toggle-show-all-details')
      .removeClass('active').html('Show all details');
    $('.details-text').css({'display':'none'});
    $('.details-toggler').html('Show details')
      .prop('title', 'Show all detailed text');
  }
}

function setupProjectForm() {
  // We're told progress, so don't recalculate - just display it.
  var percentageScaled = $('#badge-progress').attr('aria-valuenow');
  var percentAsString = percentageScaled.toString() + '%';
  $('#badge-progress').css('width', percentAsString);

  // By default, hide details.  We do the hiding in JavaScript, so
  // those who disable JavaScript will still see the text
  // (they'll have no way to later reveal it).
  $('.details-text').css({'display':'none'});
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

  // Implement "press this button to make all crypto N/A"
  $('#all_crypto_na').click(function(e) {
    $.each(CRITERIA_HASH, function(criterion, value) {
      if ((/^crypto/).test(criterion)) {
        $('#project_' + criterion + '_status_na').prop('checked', true);
      }
      updateCriteriaDisplay(criterion);
      resetCriterionResult(criterion);
    });
    setPanelSatisfactionLevel($('#all_crypto_na').parents('.panel'));
    resetProgressBar();
  });

  $.each(CRITERIA_HASH, function(key, value) {
    setupProjectField(key);
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
