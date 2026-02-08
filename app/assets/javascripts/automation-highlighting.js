// frozen_string_literal: true

// Copyright the Linux Foundation and the
// OpenSSF Best Practices badge contributors
// SPDX-License-Identifier: MIT

// Progressive enhancement for automation highlighting
// Auto-expands panels containing automated/overridden fields
// and scrolls to first overridden field (orange highlight)

document.addEventListener('DOMContentLoaded', function() {
  // Auto-expand panels containing highlighted fields
  const highlightedFields = document.querySelectorAll('.highlight-automated, .highlight-overridden');

  highlightedFields.forEach(function(field) {
    // Find parent panel-collapse and expand it
    const panel = field.closest('.panel-collapse');
    if (panel && !panel.classList.contains('in')) {
      panel.classList.add('in');

      // Also expand all parent panels (for nested panels)
      let currentElement = panel.parentElement;
      while (currentElement) {
        const parentPanel = currentElement.closest('.panel-collapse');
        if (parentPanel && !parentPanel.classList.contains('in')) {
          parentPanel.classList.add('in');
        }
        currentElement = parentPanel ? parentPanel.parentElement : null;
      }
    }
  });

  // Scroll to first overridden field (orange) if URL has anchor
  // Overridden fields are more important than automated fields
  if (window.location.hash) {
    setTimeout(function() {
      const targetId = 'criterion-' + window.location.hash.substring(1);
      const target = document.getElementById(targetId);
      if (target && target.classList.contains('highlight-overridden')) {
        target.scrollIntoView({ behavior: 'smooth', block: 'center' });

        // Set focus for keyboard navigation
        const focusable = target.querySelector('input, select, textarea');
        if (focusable) {
          focusable.focus();
        }
      }
    }, 500); // Delay to allow panel expansion animation
  }
});
