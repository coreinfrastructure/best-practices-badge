// Copyright 2015-2017, the Linux Foundation, IDA, and the
// CII Best Practices badge contributors
// SPDX-License-Identifier: MIT

// This JavaScript implements the per-project form used
// for showing and editing information about a project.

// This global constant is set in criteria.js ; let ESLint know about it.
/* global CRITERIA_HASH_FULL */
/* global TRANSLATION_HASH_FULL */

var MIN_SHOULD_LENGTH = 5;

// Global - name of criterion we last selected as 'met' or 'N/A'.
// Don't hide this criterion (yet), so that users can enter a justification.
var globalLastSelectedMetNA = '';
var globalHideMetnaCriteria = false;
var globalShowAllDetails = false;
var globalExpandAllPanels = false;
var globalIgnoreHashChange = false;
var globalCriteriaResultHash = {};
var globalisEditing = false;
var CRITERIA_HASH = {};
// Transllation hash for current locale.
var T_HASH = {};

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

// This gets the locale of the current page
function getLocale() {
  var localeFromUrl = location.pathname.split('/')[1];
  if (localeFromUrl.length >= 2 &&
      (localeFromUrl.length === 2 || localeFromUrl[2] === '-')) {
    return localeFromUrl;
  }
  var searchString = location.search.match('locale=([^\#\&]*)');
  if (searchString) {
    return searchString[1];
  } else {
    return 'en';
  }
}

// Return current level based upon parameters in location.search
function getLevel() {
  var levelFromUrl = location.pathname.match('projects/[0-9]*/([0-2])');
  if (levelFromUrl) {
    return levelFromUrl[1];
  }
  var searchString = location.search.match('criteria_level=([^\#\&]*)');
  if (searchString) {
    return searchString[1];
  } else {
    return '0';
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
  // string.startsWith('#') was causing a test failure on circleCI.
  // We are not sure why, but regex works fine so let's use that.
  var possibleComment = /^\/\/ /.exec(justification);
  if (!justification || (!!possibleComment && possibleComment.index === 0)) {
    return false;
  } else {
    return !!justification.match(/https?:\/\/[^ ]{5}/);
  }
}

// Return if criterion's value for key is true in CRITERIA_HASH (default false)
function criterionHashTrue(criterion, key) {
  return CRITERIA_HASH[criterion][key] === true;
}

function criterionStatus(criterion) {
  return globalCriteriaResultHash[criterion]['status'];
}

// Return true if the justification is good enough for a SHOULD criterion.
function justificationGood(justification) {
  // string.startsWith('#') was causing a test failure on circleCI.
  // We are not sure why, but regex works fine so let's use that.
  var possibleComment = /^\/\/ /.exec(justification);
  if (!justification || (!!possibleComment && possibleComment.index === 0)) {
    return false;
  } else {
    return justification.length >= MIN_SHOULD_LENGTH;
  }
}

// This function is mirrored in app/models/project.rb by "get_met_result"
// If you change this function change "get_met_result" accordingly.
function getMetResult(criterion, justification) {
  if (criterionHashTrue(criterion, 'met_url_required') &&
      !containsURL(justification)) {
    return 'criterion_url_required';
  } else if (criterionHashTrue(criterion, 'met_justification_required') &&
         !justificationGood(justification)) {
    return 'criterion_justification_required';
  } else {
    return 'criterion_passing';
  }
}

// This function is mirrored in app/models/project.rb by "get_na_result"
// If you change this function change "get_na_result" accordingly.
function getNAResult(criterion, justification) {
  if (criterionHashTrue(criterion, 'na_justification_required') &&
      !justificationGood(justification)) {
    return 'criterion_justification_required';
  } else {
    return 'criterion_passing';
  }
}

// This function is mirrored in app/models/project.rb by "get_unmet_result"
// If you change this function change "get_unmet_result" accordingly.
function getUnmetResult(criterion, justification) {
  if (CRITERIA_HASH[criterion]['category'] === 'SUGGESTED' ||
      (CRITERIA_HASH[criterion]['category'] === 'SHOULD' &&
       justificationGood(justification))) {
    return 'criterion_barely';
  } else if (CRITERIA_HASH[criterion]['category'] === 'SHOULD') {
    return 'criterion_justification_required';
  } else {
    return 'criterion_failing';
  }
}

// Determine result for a given criterion, which is one of the following:
//  criterion_passing, criterion_barely, criterion_justification_required
//  criterion_url_requrired, criterion_unknown, criterion_failing
//
// This function is mirrored in app/models/project.rb by "get_criterion_result"
// If you change this function change "get_criterion_result" accordingly.
function getCriterionResult(criterion) {
  var status = criterionStatus(criterion);
  var justification = $('#project_' + criterion + '_justification');
  if (justification.length > 0) {
    justification = $(justification)[0].value;
  }
  if (!justification) {
    justification = '';
  }
  if (status === '?') {
    return 'criterion_unknown';
  } else if (status === 'Met') {
    return getMetResult(criterion, justification);
  } else if (status === 'Unmet') {
    return getUnmetResult(criterion, justification);
  } else {
    return getNAResult(criterion, justification);
  }
}

// This function is mirrored in app/models/project.rb by "enough?"
// If you change this function change "enough?" accordingly.
function isEnough(criterion) {
  var result = globalCriteriaResultHash[criterion]['result'];
  return (result === 'criterion_passing' || result === 'criterion_barely');
}

// Set a panel's satisfaction level.
function setPanelSatisfactionLevel(panelID) {
  var total = 0;
  var enough = 0;
  $.each(CRITERIA_HASH, function(criterion, value) {
    if (panelID === globalCriteriaResultHash[criterion]['panelID']) {
      total++;
      if (isEnough(criterion)) {
        enough++;
      }
    }
  });
  var panel = $('#' + panelID);
  $(panel).find('.satisfaction-text')
                 .text(enough.toString() + '/' + total.toString());
  $(panel).find('.satisfaction-bullet')
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

function resetProgressAndSatisfaction(criterion) {
  setPanelSatisfactionLevel(globalCriteriaResultHash[criterion]['panelID']);
  resetProgressBar();
}

// The functionality of this function is mirrored in
// app/views/_status_chooser.html.erb
// If you change this function change that view accordingly.
function resetCriterionResult(criterion) {
  var result = globalCriteriaResultHash[criterion]['result'];
  var destination = $('#' + criterion + '_enough');
  if (result === 'criterion_passing') {
    destination.attr('src', $('#result_symbol_check_img').attr('src')).
      attr('width', 40).attr('height', 40).
      attr('alt', T_HASH['passing_alt']);
  } else if (result === 'criterion_barely') {
    destination.attr('src', $('#result_symbol_dash').attr('src')).
      attr('width', 40).attr('height', 40).
      attr('alt', T_HASH['barely_alt']);
  } else if (result === 'criterion_failing') {
    destination.attr('src', $('#result_symbol_x_img').attr('src')).
      attr('width', 40).attr('height', 40).
      attr('alt', T_HASH['failing_alt']);
  } else {
    destination.attr('src', $('#result_symbol_question').attr('src')).
      attr('width', 40).attr('height', 40).
      attr('alt', T_HASH['unknown_alt']);
  }
}

function changedJustificationText(criterion) {
  var criterionJust = '#project_' + criterion + '_justification';
  var result = globalCriteriaResultHash[criterion]['result'];
  if (result === 'criterion_justification_required' ||
      result === 'criterion_url_required') {
    $(criterionJust).addClass('required-data');
  } else {
    $(criterionJust).removeClass('required-data');
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

function fillCriteriaResultHash() {
  $.each(CRITERIA_HASH, function(key, value) {
    globalCriteriaResultHash[key] = {};
    globalCriteriaResultHash[key]['status'] = $('input[name="project[' + key +
                                                '_status]"]:checked')[0].value;
    globalCriteriaResultHash[key]['result'] = getCriterionResult(key);
    globalCriteriaResultHash[key]['panelID'] = value['major']
                                              .toLowerCase()
                                              .replace(/\s+/g, '');
  });
  $('#project_entry_form').trigger('criteriaResultHashComplete');
}

// If we should, hide the criteria that are "Met" or N/A and are enough.
// Do NOT hide 'met' criteria that aren't enough (e.g., missing required URL),
// and do NOT hide the last-selected-met criterion (so users can enter/edit
// justification text).
function hideMetNA() {
  if (globalisEditing) {
    $.each(CRITERIA_HASH, function(criterion, value) {
      var result = globalCriteriaResultHash[criterion]['result'];
      if (globalHideMetnaCriteria && criterion !== globalLastSelectedMetNA &&
          result === 'criterion_passing') {
        $('#' + criterion).addClass('hidden');
      } else {
        $('#' + criterion).removeClass('hidden');
      }
    });
  } else if (globalHideMetnaCriteria) {
    $('.criterion-data.criterion-passing').addClass('hidden');
  } else {
    $('.criterion-data.criterion-passing').removeClass('hidden');
  }
  $('.hidable-text-entry').each(function() {
    if (globalHideMetnaCriteria && hasFieldTextInside($(this))) {
      $(this).addClass('hidden');
    } else {
      $(this).removeClass('hidden');
    }
  });
}

function updateCriterionDisplay(criterion) {
  var criterionJust = '#project_' + criterion + '_justification';
  var status = criterionStatus(criterion);
  var justification = $(criterionJust).length > 0 ?
    $(criterionJust)[0].value : '';
  var criterionPlaceholder;
  var suppressJustificationDisplay;
  var locale = getLocale();
  if (status === 'Met') {
    if (CRITERIA_HASH[criterion]['met_placeholder']) {
      criterionPlaceholder =
        CRITERIA_HASH[criterion]['met_placeholder'][locale];
    }
    if (!criterionPlaceholder) {
      if (criterionHashTrue(criterion, 'met_url_required')) {
        criterionPlaceholder = T_HASH['met_url_placeholder'];
      } else if (criterionHashTrue(criterion, 'met_justification_required')) {
        criterionPlaceholder = T_HASH['met_justification_placeholder'];
      } else {
        criterionPlaceholder = T_HASH['met_placeholder'];
      }
    }
    suppressJustificationDisplay = criterionHashTrue(criterion, 'met_suppress');
  } else if (status === 'Unmet') {
    if (CRITERIA_HASH[criterion]['unmet_placeholder']) {
      criterionPlaceholder =
        CRITERIA_HASH[criterion]['unmet_placeholder'][locale];
    }
    if (!criterionPlaceholder) {
      criterionPlaceholder = T_HASH['unmet_placeholder'];
    }
    suppressJustificationDisplay =
      criterionHashTrue(criterion, 'unmet_suppress');
  } else if (status === 'N/A') {
    if (CRITERIA_HASH[criterion]['na_placeholder']) {
      criterionPlaceholder =
        CRITERIA_HASH[criterion]['na_placeholder'][locale];
    }
    if (!criterionPlaceholder) {
      if (criterionHashTrue(criterion, 'na_justification_required')) {
        criterionPlaceholder = T_HASH['na_justification_placeholder'];
      } else {
        criterionPlaceholder = T_HASH['na_placeholder'];
      }
    }
    suppressJustificationDisplay = criterionHashTrue(criterion, 'na_suppress');
  } else {
    criterionPlaceholder = T_HASH['unknown_placeholder'];
    suppressJustificationDisplay = true;
  }
  $(criterionJust).attr('placeholder', criterionPlaceholder);

  // If there's old justification text, force showing it even if it
  // no longer makes sense (so they can fix it or change their mind).
  if (justification.length > 0 || !suppressJustificationDisplay) {
    $(criterionJust).css({'display':''});
  } else {
    $(criterionJust).css({'display':'none'});
  }

  if (globalHideMetnaCriteria) {
    // If we're hiding met criterion, walk through and hide them.
    // We don't need to keep running this if we are NOT hiding them,
    // which is the normal case.
    hideMetNA();
  }
  changedJustificationText(criterion);
}

function updateCriterionDisplayAndUpdate(criterion) {
  updateCriterionDisplay(criterion);
  resetCriterionResult(criterion);
  resetProgressAndSatisfaction(criterion);
}

function changeCriterion(criterion) {
  // We could use criterionStatus here, but this is faster since
  // we do not care about any status except "Met" or "N/A".
  var status = criterionStatus(criterion);
  if (status === 'Met' || status === 'N/A') {
    globalLastSelectedMetNA = criterion;
  }
  updateCriterionDisplayAndUpdate(criterion);
}

function ToggleHideMet(e) {
  globalHideMetnaCriteria = !globalHideMetnaCriteria;
  // Note that button text shows what WILL happen on click, so it
  // shows the REVERSED state (not the current state).
  if (globalHideMetnaCriteria) {
    $('#toggle-hide-metna-criteria')
      .addClass('active').html(T_HASH['show_met_html'])
      .prop('title', T_HASH['show_met_title']); // Use & not &amp;
  } else {
    $('#toggle-hide-metna-criteria')
      .removeClass('active').html(T_HASH['hide_met_html'])
      .prop('title', T_HASH['hide_met_title']);
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
      .addClass('active').html(T_HASH['collapse_all'])
      .prop('title', T_HASH['collapse_all_title']);
  } else {
    $('#toggle-expand-all-panels')
      .removeClass('active').html(T_HASH['expand_all'])
      .prop('title', T_HASH['expand_all_title']);
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
  $('.can-collapse').find('em.glyphicon').addClass('glyphicon-chevron-up');
  var loc = window.location.hash;
  if (loc !== '#all') {
    var parentPanel = $(loc).parents('.panel');
    if (parentPanel.length) {
      $('.panel').not(parentPanel).find('.collapse').removeClass('in');
      $('.panel').not(parentPanel).find('.can-collapse').addClass('collapsed');
      $('.panel').not(parentPanel).find('.can-collapse').find('em.glyphicon')
        .addClass('glyphicon-chevron-down')
        .removeClass('glyphicon-chevron-up');
      showHash();
    } else {
      $('.remove-in').removeClass('in');
      $('.close-by-default').addClass('collapsed');
      $('.close-by-default').find('em.glyphicon')
        .addClass('glyphicon-chevron-down')
        .removeClass('glyphicon-chevron-up');
    }
  }
  // Set the satisfaction level in each panel
  $('.satisfaction-bullet').each(function(index) {
    $(this).css({ 'color' : $(this).attr('data-color')});
  });
}

// Implement "press this button to make all crypto N/A"
function setAllCryptoNA() {
  var panelsToSet = [];
  $.each(CRITERIA_HASH, function(criterion, value) {
    if ((/^crypto/).test(criterion)) {
      var major = value.major.toLowerCase().replace(/\s+/g, '');
      if ($.inArray(major, panelsToSet) === -1) {
        panelsToSet.push(major);
      }
      $('#project_' + criterion + '_status_na').prop('checked', true);
      globalCriteriaResultHash[criterion]['status'] = 'N/A';
      globalCriteriaResultHash[criterion]['result'] =
        getCriterionResult(criterion);
      updateCriterionDisplay(criterion);
      resetCriterionResult(criterion);
    }
  });
  $.each(panelsToSet, function(index, panelID) {
    setPanelSatisfactionLevel(panelID);
  });
  resetProgressBar();
}

// For a given event, return the criterion on which that event was
// triggered and the criterionResult for that criterion.
function getCriterionAndResult(event) {
  var criterion = $(event.target).parents('.criterion-data').attr('id');
  if (event.target.name === 'project[' + criterion + '_status]') {
    globalCriteriaResultHash[criterion]['status'] = event.target.value;
  }
  var result = getCriterionResult(criterion);
  globalCriteriaResultHash[criterion]['result'] = result;
  return criterion;
}

function setupProjectFields() {
  $.each(CRITERIA_HASH, function(key, value) {
    updateCriterionDisplay(key);
  });
  $('.edit_project').on('click', function(e) {
    if ($(e.target).is(':radio')) {
      var criterion = getCriterionAndResult(e);
      changeCriterion(criterion);
    }
  });
  $('.edit_project').on('focusout', function(e) {
    if ($(e.target).hasClass('justification-text')) {
      var criterion = getCriterionAndResult(e);
      updateCriterionDisplayAndUpdate(criterion);
    }
  });
  $('.edit_project').on('input keyup', function(e) {
    if ($(e.target).hasClass('justification-text')) {
      var criterion = getCriterionAndResult(e);
      changedJustificationTextAndUpdate(criterion);
    }
  });
}

function ToggleDetailsDisplay(e) {
  var detailsTextID = e.target.id.
                        replace('_details_toggler', '_details_text');
  var buttonText;
  if ($('#' + detailsTextID).css('display') !== 'none') {
    buttonText = T_HASH['show_details'];
    $('#' + detailsTextID).css({'display':'none'});
  } else {
    buttonText = T_HASH['hide_details'];
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
      .addClass('active').html(T_HASH['hide_all_details']);
    $('.details-text').css({'display':''});
    $('.details-toggler').html(T_HASH['hide_details'])
      .prop('title', T_HASH['hide_all_details']);
  } else {
    $('#toggle-show-all-details')
      .removeClass('active').html(T_HASH['show_all_details']);
    $('.details-text').css({'display':'none'});
    $('.details-toggler').html(T_HASH['show_details'])
      .prop('title', T_HASH['show_all_details']);
  }
}

function TogglePanel(e) {
  var $this;
  if ($(e.target).hasClass('can-collapse')) {
    $this = $(e.target);
  } else {
    $this = $(e.target).closest('.can-collapse');
  }
  if ($this.hasClass('collapsed')) {
    $this.closest('.panel').find('.panel-collapse').collapse('show');
    $this.removeClass('collapsed');
    $this.find('em.glyphicon').removeClass('glyphicon-chevron-down')
      .addClass('glyphicon-chevron-up');
    if (!globalIgnoreHashChange) {
      var origId = $this.attr('id');
      // prevent scrolling on panel open
      $this.attr('id', origId + '-tmp');
      location.hash = '#' + origId;
      $this.attr('id', origId);
    }
  } else {
    $this.closest('.panel').find('.panel-collapse').collapse('hide');
    $this.addClass('collapsed');
    $this.find('em.glyphicon').removeClass('glyphicon-chevron-up')
      .addClass('glyphicon-chevron-down');
  }
}

function setupProjectForm() {
  // We're told progress, so don't recalculate - just display it.
  T_HASH = TRANSLATION_HASH_FULL[getLocale()];
  var percentageScaled = $('#badge-progress').attr('aria-valuenow');
  var percentAsString = percentageScaled.toString() + '%';
  $('#badge-progress').css('width', percentAsString);


  // By default, hide details.  We do the hiding in JavaScript, so
  // those who disable JavaScript will still see the text
  // (they'll have no way to later reveal it).
  $('.details-text').css({'display':'none'});
  $('.details-toggler').html(T_HASH['show_details']);

  // Force these values on page reload
  globalShowAllDetails = false;
  globalLastSelectedMetNA = '';
  globalHideMetnaCriteria = false;
  globalExpandAllPanels = false;
  globalCriteriaResultHash = {};
  globalisEditing = $('#project_name').is(':not(:disabled)');

  // Set up click event listeners
  $('body').on('click', function(e) {
    var target = $(e.target);
    if (target.hasClass('details-toggler')) {
      ToggleDetailsDisplay(e);
    } else if (target.hasClass('can-collapse') ||
               target.parents('.can-collapse').length) {
      TogglePanel(e);
    // Implement "press this button to make all crypto N/A"
    } else if (e.target.id === 'all_crypto_na') {
      setAllCryptoNA();
    } else if (e.target.id === 'toggle-show-all-details') {
      ToggleAllDetails(e);
    } else if (e.target.id === 'toggle-hide-metna-criteria') {
      ToggleHideMet(e);
    } else if (e.target.id === 'toggle-expand-all-panels') {
      ToggleExpandAllPanels(e);
    }
  });

  if (globalisEditing) {
    CRITERIA_HASH = CRITERIA_HASH_FULL[getLevel()];
    $('#project_entry_form').on('criteriaResultHashComplete', function(e) {
      setupProjectFields();
      resetProgressBar();
    });
    fillCriteriaResultHash();
  }

  getAllPanelsReady();

  $(window).on('hashchange', function(e) {
    if (!globalIgnoreHashChange && $(window.location.hash).length) {
      showHash();
    }
  });
}

// Setup display as soon as page is ready
// NOTE: With turbolinks we'd do:
// > document.addEventListener('turbolinks:load', function() {
// TODO: Instead of attaching many listeners, attach a few to the whole doc.
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
