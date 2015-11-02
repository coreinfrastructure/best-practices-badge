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


FIELD_CATEGORIES = {
  // "project_url" : "MUST",
  // "project_url_https" : "SUGGESTED",
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

MIN_SHOULD_LENGTH = 5;

function isEnough(criteria) {
  var criteria_status = '#project_' + criteria + '_status';
  if ($(criteria_status + '_na').is(':checked')) {
    return true;
  }
  if (FIELD_CATEGORIES[criteria] === 'MUST') {
    return ($(criteria_status + '_met').is(':checked'));
  } else if (FIELD_CATEGORIES[criteria] === 'SHOULD') {
    return ($(criteria_status + '_met').is(':checked') ||
           ($(criteria_status + '_unmet').is(':checked') &&
              $('#project_' + criteria + '_justification').val().length >= MIN_SHOULD_LENGTH));
  } else {
    return ($(criteria_status + '_met').is(':checked') ||
           $(criteria_status + '_unmet').is(':checked'));
  }
}

function reset_progress_bar() {
  var total = 0;
  var enough = 0;
  $.each(FIELD_CATEGORIES, function(key, value) {
    total++;
    if (isEnough(key)) {enough++;};
  })
  var percentage = enough / total;
  var percent_s =  Math.round(percentage * 100).toString() + '%'
  $('#badge-progress').attr('aria-valuenow', percentage).
                      text(percent_s).css('width', percent_s);
}

function changed_justification_text(criteria) {
  var criteria_just = '#project_' + criteria + '_justification';
  var criteria_status = '#project_' + criteria + '_status';
  if ($(criteria_status + '_unmet').is(':checked') &&
       (FIELD_CATEGORIES[criteria] === 'SHOULD') &&
       ($(criteria_just).val().length < MIN_SHOULD_LENGTH)) {
    $(criteria_just).addClass('required-data');
  } else {
    $(criteria_just).removeClass('required-data');
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
  reset_progress_bar();
}

function update_criteria_display(criteria) {
  var criteria_just = '#project_' + criteria + '_justification';
  var criteria_status = '#project_' + criteria + '_status';
  var justification_value = document.getElementById('project_' + criteria + '_justification').value;
  var placeholder = '';
  if ($(criteria_status + '_met').is(':checked')) {
    var criteria_met_placeholder = criteria + '_met_placeholder';
    $(criteria_just).
       attr('placeholder',
         $('#' + criteria_met_placeholder).html().trim());
    if (document.getElementById(criteria + '_met_suppress')) {
      $(criteria_just).hide('fast');
    } else {
      $(criteria_just).show('fast');
    }
  } else if ($(criteria_status + '_unmet').is(':checked')) {
    var criteria_unmet_placeholder = criteria + '_unmet_placeholder';
    $(criteria_just).
       attr('placeholder',
         $('#' + criteria_unmet_placeholder).html().trim());
    if ((FIELD_CATEGORIES[criteria] === 'MUST') ||
         (document.getElementById(criteria + '_unmet_suppress'))) {
      $(criteria_just).hide('fast');
    } else {
      $(criteria_just).show('fast');
    }
  } else if ($(criteria_status + '_na').is(':checked')) {
    var criteria_na_placeholder = criteria + '_na_placeholder';
    $(criteria_just).
       attr('placeholder',
         $('#' + criteria_na_placeholder).html().trim());
    if (document.getElementById(criteria + '_na_suppress')) {
      $(criteria_just).hide('fast');
    } else {
      $(criteria_just).show('fast');
    }
  } else if ($(criteria_status + '_').is(':checked')) {
    $(criteria_just).attr('placeholder', 'Please explain');
    $(criteria_just).hide('fast');
  }
  // If there's old justification text, force showing it even if it
  // no longer makes sense (so they can fix it or change their mind).
  if (justification_value.length > 0) {
    $(criteria_just).show('fast');
  }
  changed_justification_text(criteria);
}

function setup_field(criteria) {
  update_criteria_display(criteria);
  $('input[name="project[' + criteria + '_status]"]').click(
      function() {update_criteria_display(criteria);});
  $('input[name="project[' + criteria + '_justification]"]').blur(
      function() {update_criteria_display(criteria);});
  $('input[name="project[' + criteria + '_justification]"]').on('input',
      function() {changed_justification_text(criteria);});
}

function toggle_details(e) {
  var details_text_id = e.target.id.
                        replace('_details_toggler', '_details_text');
  $('#' + details_text_id).toggle('fast',
    function() {
      if ($('#' + details_text_id).is(':hidden')) {
        var button_text = 'Show details';
      } else {
        var button_text = 'Hide details';
      }
      $('#' + e.target.id).html(button_text);
    });
}

// Setup display as soon as page is ready
$(document).ready(function() {
  // By default, hide details.  We do the hiding in Javascript, so
  // those who disable Javascript will still see the text
  // (they'll have no way to later reveal it).
  $('.details-text').hide('fast');
  $('.details-toggler').html('Show details');
  $('.details-toggler').click(toggle_details);

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
          update_criteria_display(key);
        })
        reset_progress_bar();
      });

    // Use "imagesloaded" to wait for image load before displaying them
    imagesLoaded(document).on('always', function(instance) {
        // Set up the interactive displays of "enough".
        $.each(FIELD_CATEGORIES, function(key, value) {
          setup_field(key);
        })
        reset_progress_bar();
      })
  }

  // Polyfill datalist (for Safari users)
  polyfillDatalist();
});
