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

// The field names are from a spec, so we need to allow snake format here.
// jscs : disable requireCamelCaseOrUpperCaseIdentifiers
FIELD_CATEGORIES = {
  // Omitted: project_url : "MUST",
  // Omitted: project_url_https : "SUGGESTED",
  description_sufficient: 'MUST',
  interact: 'MUST',
  contribution: 'MUST',
  contribution_criteria: 'SHOULD',
  license_location: 'MUST',
  oss_license: 'MUST',
  oss_license_osi: 'SUGGESTED',
  documentation_basics: 'MUST',
  documentation_interface: 'MUST',
  repo_url: 'MUST',
  repo_track: 'MUST',
  repo_interim: 'MUST',
  repo_distributed: 'SUGGESTED',
  version_unique: 'MUST',
  version_semver: 'SUGGESTED',
  version_tags: 'SUGGESTED',
  changelog: 'MUST',
  changelog_vulns: 'MUST',
  report_tracker: 'SUGGESTED',
  report_process: 'MUST',
  report_responses: 'MUST',
  enhancement_responses: 'SHOULD',
  report_archive: 'MUST',
  vulnerability_report_process: 'MUST',
  vulnerability_report_private: 'MUST',
  vulnerability_report_response: 'MUST',
  build: 'MUST',
  build_common_tools: 'SUGGESTED',
  build_oss_tools: 'SHOULD',
  test: 'MUST',
  test_invocation: 'SHOULD',
  test_most: 'SUGGESTED',
  test_continuous_integration: 'SUGGESTED',
  test_policy: 'MUST',
  tests_are_added: 'MUST',
  tests_documented_added: 'SUGGESTED',
  warnings: 'MUST',
  warnings_fixed: 'MUST',
  warnings_strict: 'SUGGESTED',
  know_secure_design: 'MUST',
  know_common_errors: 'MUST',
  crypto_published: 'MUST',
  crypto_call: 'MUST',
  crypto_oss: 'MUST',
  crypto_keylength: 'MUST',
  crypto_working: 'MUST',
  crypto_weaknesses: 'SHOULD',
  crypto_alternatives: 'SHOULD',
  crypto_pfs: 'SHOULD',
  crypto_password_storage: 'MUST',
  crypto_random: 'MUST',
  delivery_mitm: 'MUST',
  delivery_unsigned: 'MUST',
  vulnerabilities_fixed_60_days: 'MUST',
  vulnerabilities_critical_fixed: 'SHOULD',
  static_analysis: 'MUST',
  static_analysis_common_vulnerabilities: 'SUGGESTED',
  static_analysis_fixed: 'MUST',
  static_analysis_often: 'SUGGESTED',
  dynamic_analysis: 'MUST',
  dynamic_analysis_unsafe: 'MUST',
  dynamic_analysis_enable_assertions: 'SUGGESTED',
  dynamic_analysis_fixed: 'MUST',
}
// jscs: : enable requireCamelCaseOrUpperCaseIdentifiers

MIN_SHOULD_LENGTH = 5;

function isEnough(criteria) {
  var criteriaStatus = '#project_' + criteria + '_status';
  if ($(criteriaStatus + '_na').is(':checked')) {
    return true;
  }
  if (FIELD_CATEGORIES[criteria] === 'MUST') {
    return ($(criteriaStatus + '_met').is(':checked'));
  } else if (FIELD_CATEGORIES[criteria] === 'SHOULD') {
    return ($(criteriaStatus + '_met').is(':checked') ||
           ($(criteriaStatus + '_unmet').is(':checked') &&
              $('#project_' + criteria + '_justification').val().length >=
              MIN_SHOULD_LENGTH));
  } else {
    return ($(criteriaStatus + '_met').is(':checked') ||
           $(criteriaStatus + '_unmet').is(':checked'));
  }
}

function resetProgressBar() {
  var total = 0;
  var enough = 0;
  $.each(FIELD_CATEGORIES, function(key, value) {
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
       (FIELD_CATEGORIES[criteria] === 'SHOULD') &&
       ($(criteriaJust).val().length < MIN_SHOULD_LENGTH)) {
    $(criteriaJust).addClass('required-data');
  } else {
    $(criteriaJust).removeClass('required-data');
  }

  if (isEnough(criteria)) {
    $('#' + criteria + '_enough').
        attr('src', $('#Thumbs_up_img').attr('src')).
        attr('alt', 'Enough for a badge!');
  } else {
    $('#' + criteria + '_enough').
        attr('src', $('#Thumbs_down_img').attr('src')).
        attr('alt', 'Not enough for a badge.');
  }
  resetProgressBar();
}

function updateCriteriaDisplay(criteria) {
  var criteriaJust = '#project_' + criteria + '_justification';
  var criteriaStatus = '#project_' + criteria + '_status';
  var justificationValue = document.getElementById('project_' +
                           criteria + '_justification').value;
  var placeholder = '';
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
    if ((FIELD_CATEGORIES[criteria] === 'MUST') ||
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
  changedJustificationText(criteria);
}

function setupProjectField(criteria) {
  updateCriteriaDisplay(criteria);
  $('input[name="project[' + criteria + '_status]"]').click(
      function() {updateCriteriaDisplay(criteria);});
  $('input[name="project[' + criteria + '_justification]"]').blur(
      function() {updateCriteriaDisplay(criteria);});
  $('input[name="project[' + criteria + '_justification]"]').on('input',
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


  if ($('#project_entry_form').length) {

    // Implement "press this button to make all crypto N/A"
    $('#all_crypto_na').click(function(e) {
        $.each(FIELD_CATEGORIES, function(key, value) {
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
        $.each(FIELD_CATEGORIES, function(key, value) {
          setupProjectField(key);
        })
        resetProgressBar();
      })
  }

  // Polyfill datalist (for Safari users)
  polyfillDatalist();
});
