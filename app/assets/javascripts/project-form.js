// This Javascript supporting implementing the per project form used
// for showing and editing information about a project.

// Do a polyfill for datalist if it's not already supported
// (e.g., Safari fails to support polyfill at the time of this writing).
// See https://github.com/thgreasi/datalist-polyfill/blob/master/README.md
function polyfillDatalist() {
  var nativedatalist = !!('list' in document.createElement('input')) &&
      !!(document.createElement('datalist') && window.HTMLDataListElement);
  if (!nativedatalist) {
    $('input[list]').each(function() {
      var availableTags = $('#' + $(this).attr('list')).find('option').
                          map(function() {
        return this.value;
      }).get();
      $(this).autocomplete({ source: availableTags });
    });
  }
};

criterionCategoryValue = {}
criteriaMetUrlRequired = {};

MIN_SHOULD_LENGTH = 5;

function containsURL(justification) {
  if (!justification) {
    return false;
  } else {
    return !!justification.match(/https?:\/\/[^ ]{5,}/);
  }
}

// This must match the criteria implemented in Ruby to prevent confusion.
function isEnough(criteria) {
  var criteriaStatus = '#project_' + criteria + '_status';
  var justification = $('#project_' + criteria + '_justification').val();
  if (!justification) justification = '';
  if (criterionCategoryValue[criteria] === 'FUTURE') {
    return true;
  } else if ($(criteriaStatus + '_na').is(':checked')) {
    return true;
  } else if ($(criteriaStatus + '_met').is(':checked')) {
    return criteriaMetUrlRequired[criteria] ?
      containsURL(justification) : true;
  } else if (criterionCategoryValue[criteria] === 'SHOULD' &&
             $(criteriaStatus + '_unmet').is(':checked') &&
             justification.length >= MIN_SHOULD_LENGTH) {
    return true;
  } else if (criterionCategoryValue[criteria] === 'SUGGESTED' &&
            !($(criteriaStatus + '_').is(':checked'))) {
    return true;
  } else {
    return false;
  }
}

function resetProgressBar() {
  var total = 0;
  var enough = 0;
  $.each(criterionCategoryValue, function(key, value) {
    total++;
    if (isEnough(key)) {enough++;};
  })
  var percentage = enough / total;
  var percentAsString =  Math.round(percentage * 100).toString() + '%'
  $('#badge-progress').attr('aria-valuenow', percentage).
                      text(percentAsString).css('width', percentAsString);
}

function changedJustificationText(criteria) {
  var criteriaJust = '#project_' + criteria + '_justification';
  var criteriaStatus = '#project_' + criteria + '_status';
  if ($(criteriaStatus + '_unmet').is(':checked') &&
       (criterionCategoryValue[criteria] === 'SHOULD') &&
       ($(criteriaJust).val().length < MIN_SHOULD_LENGTH)) {
    $(criteriaJust).addClass('required-data');
  } else if ($(criteriaStatus + '_met').is(':checked') &&
           criteriaMetUrlRequired[criteria]  &&
           !containsURL($(criteriaJust).val())) {
    $(criteriaJust).addClass('required-data');
  } else {
    $(criteriaJust).removeClass('required-data');
  }

  if (isEnough(criteria)) {
    $('#' + criteria + '_enough').
        attr('src', $('#Thumbs_up_img').attr('src')).
        attr('width', 30).attr('height', 30).
        attr('alt', 'Enough for a badge!');
  } else {
    $('#' + criteria + '_enough').
        attr('src', $('#Thumbs_down_img').attr('src')).
        attr('width', 30).attr('height', 30).
        attr('alt', 'Not enough for a badge.');
  }
  resetProgressBar();
}

// If we should, hide the criteria that are "Met" and are enough.
// Do NOT hide 'met' criteria that aren't enough (e.g., missing required URL),
// and do NOT hide the last-selected-met criterion (so users can enter/edit
// justification text).
function hideMet() {
  $.each(criterionCategoryValue, function(key, value) {
    if ( global_hide_met_criteria && key !== global_last_selected_met &&
         $('#project_' + key + '_status_met').is(':checked') &&
         isEnough(key)) {
      $('#' + key).addClass('hidden');
    } else {
      $('#' + key).removeClass('hidden');
    }
  })
}

function updateCriteriaDisplay(criteria) {
  var criteriaJust = '#project_' + criteria + '_justification';
  var criteriaStatus = '#project_' + criteria + '_status';
  var justificationElement = document.getElementById('project_' +
                           criteria + '_justification');
  var justificationValue = '';
  var placeholder = '';
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
    global_last_selected_met = criteria;
  } else if ($(criteriaStatus + '_unmet').is(':checked')) {
    var criteriaUnmetPlaceholder = criteria + '_unmet_placeholder';
    $(criteriaJust).
       attr('placeholder',
         $('#' + criteriaUnmetPlaceholder).html().trim());
    if ((criterionCategoryValue[criteria] === 'MUST') ||
         (document.getElementById(criteria + '_unmet_suppress'))) {
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
  if (global_hide_met_criteria) {
    // If we're hiding met criteria, walk through and hide them.
    // We don't need to keep running this if we are NOT hiding them,
    // which is the normal case.
    hideMet();
  }
  changedJustificationText(criteria);
}

function ToggleHideMet(e) {
  global_hide_met_criteria = !global_hide_met_criteria;
  // Note that button text shows what WILL happen on click, so it
  // shows the REVERSED state (not the current state).
  if (global_hide_met_criteria) {
    $('#toggle-hide-met-criteria')
      .addClass('active').html('Show met criteria');
  } else {
    $('#toggle-hide-met-criteria')
      .removeClass('active').html('Hide met criteria');
  }
  hideMet();
}

function setupProjectField(criteria) {
  updateCriteriaDisplay(criteria);
  $('input[name="project[' + criteria + '_status]"]').click(
      function() {updateCriteriaDisplay(criteria);});
  $('input[name="project[' + criteria + '_justification]"]').blur(
      function() {updateCriteriaDisplay(criteria);});
  $('#project_' + criteria + '_justification').on('input',
      function() {changedJustificationText(criteria);});
  $('#project_' + criteria + '_justification').on('keyup',
      function() {changedJustificationText(criteria);});
}

function ToggleDetailsDisplay(e) {
  var detailsTextID = e.target.id.
                        replace('_details_toggler', '_details_text');
  $('#' + detailsTextID).toggle('fast',
    function() {
      if ($('#' + detailsTextID).is(':hidden')) {
        var buttonText = 'Show details';
      } else {
        var buttonText = 'Hide details';
      }
      $('#' + e.target.id).html(buttonText);
    });
}

// Global - name of criterion we last selected as 'met'.
// We don't want to hide this (yet), so users can enter a justification.
var global_last_selected_met = '';
var global_hide_met_criteria = false;

// Create mappings from criteria name to category and met_url_required.
// Eventually replace with just accessing classes directly via Javascript.
function SetupCriteriaStructures() {
  $('.status-chooser').each(
    function(index) {
      criterionName = $(this).find('.criterion-name').text();
      res = $(this).find('.criterion-met-url-required').text();
      val = 'true' === res;
      criteriaMetUrlRequired[criterionName] = val;
      criterionCategoryValue[criterionName] =
        $(this).find('.criterion-category').text();
    }
  )
}

// Setup display as soon as page is ready
$(document).ready(function() {
  // By default, hide details.  We do the hiding in Javascript, so
  // those who disable Javascript will still see the text
  // (they'll have no way to later reveal it).
  $('.details-text').hide('fast');
  $('.details-toggler').html('Show details');
  $('.details-toggler').click(ToggleDetailsDisplay);

  $('#show-all-details').click(function(e) {
      $('.details-text').show('fast');
      $('.details-toggler').html('Hide details');
    });
  $('#hide-all-details').click(function(e) {
      $('.details-text').hide('fast');
      $('.details-toggler').html('Show details');
    });

  $('#toggle-hide-met-criteria').click(function(e) {
    ToggleHideMet(e);
    });

  $('[data-toggle="tooltip"]').tooltip(); // Enable bootstrap tooltips
  $('textarea').autosize();

  if ($('#project_entry_form').length) {

    SetupCriteriaStructures();

    // Implement "press this button to make all crypto N/A"
    $('#all_crypto_na').click(function(e) {
        $.each(criterionCategoryValue, function(key, value) {
          if ((/^crypto/).test(key)) {
            $('#project_' + key + '_status_na').prop('checked', true);
          }
          updateCriteriaDisplay(key);
        })
        resetProgressBar();
      });

    // Use "imagesloaded" to wait for image load before displaying them
    imagesLoaded(document).on('always', function(instance) {
        // Set up the interactive displays of "enough".
        $.each(criterionCategoryValue, function(key, value) {
          setupProjectField(key);
        })
        resetProgressBar();
      })
  }

  // Polyfill datalist (for Safari users)
  polyfillDatalist();
});
