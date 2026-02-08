# Automation Implementation Details

Supplement to `automation-thoughts.md` with detailed implementation code.

## Controller Implementation: Overridden Field Handling

When save operations result in forced overrides (confidence >= 4), we must:
1. Save the overridden values
2. Redirect back to edit form
3. Highlight overridden fields
4. Scroll to first override
5. Show detailed flash message

### Tracking Overridden Fields

```ruby
# In projects_controller.rb update action

def update
  # ... existing setup ...

  changed_fields = project_params.keys.map(&:to_sym)

  # Capture original values before Chief analysis
  original_values = {}
  changed_fields.each do |field|
    original_values[field] = @project[field]
  end

  chief = Chief.new(@project, client_factory)
  proposed_changes = chief.propose_changes(
    level: @criteria_level,
    changed_fields: changed_fields
  )

  # Track which fields Chief is overriding with high confidence
  overridden_fields = []
  proposed_changes.each do |field, data|
    if data[:confidence] >= Chief::CONFIDENCE_OVERRIDE &&
       original_values[field] != data[:value] &&
       original_values[field].present? && # User explicitly set this
       original_values[field] != '?'      # User set something other than unknown
      overridden_fields << {
        field: field,
        old_value: original_values[field],
        new_value: data[:value],
        explanation: data[:explanation],
        confidence: data[:confidence]
      }
    end
  end

  # Apply changes (including forced overrides)
  chief.apply_changes(@project, proposed_changes)

  # Save and handle overrides
  if @project.save
    set_level_saved_flag(@criteria_level)

    if overridden_fields.any?
      handle_overridden_fields(overridden_fields)
    else
      # Normal save - exit to show page
      flash[:success] = t('projects.update.updated')
      redirect_to project_path(@project)
    end
  else
    # Validation errors - re-render edit form
    render :edit
  end
end

private

def set_level_saved_flag(level)
  flag_name = case level
              when 'passing' then :passing_saved
              when 'silver' then :silver_saved
              when 'gold' then :gold_saved
              when 'baseline-1' then :baseline_1_saved
              when 'baseline-2' then :baseline_2_saved
              when 'baseline-3' then :baseline_3_saved
              end
  @project.update_column(flag_name, true) if flag_name
end

def handle_overridden_fields(overridden_fields)
  # Build detailed flash message (neutral/informational tone)
  message = "We corrected #{overridden_fields.size} field(s) based on project analysis:\n"
  overridden_fields.each do |r|
    criterion = Criteria.find_by(name: r[:field].to_s.chomp('_status'))
    criterion_name = criterion&.title || r[:field].to_s.humanize
    message += "• '#{criterion_name}' changed from '#{r[:old_value]}' to '#{r[:new_value]}' (#{r[:explanation]})\n"
  end
  message += "\nPlease review these changes."

  # Use 'info' flash for helpful corrections, 'warning' for rejections
  # Actually, just use 'warning' for all to ensure visibility
  flash[:warning] = message

  # Redirect back to edit form with overridden field info
  first_overridden = overridden_fields.first[:field]
  redirect_to edit_project_path(
    @project,
    level: @criteria_level,
    anchor: first_overridden.to_s,
    overridden: overridden_fields.map { |r| r[:field].to_s }.join(',')
  )
end
```

## View Implementation: Highlighting and Scrolling

### Server-Side Highlighting (Works Without JavaScript)

**Critical**: CSS classes must be added server-side so highlights work even with JavaScript disabled.

#### Controller: Track Highlighted Fields

```ruby
# In edit action
def edit
  # ... existing setup ...

  # Check if this is first edit (automated fields)
  level_saved_flag = get_level_saved_flag(@criteria_level)

  if !@project[level_saved_flag]
    # Run automation and track what changed
    chief = Chief.new(@project, client_factory)
    changes = chief.propose_changes(level: @criteria_level)
    @automated_fields = changes.keys # Fields that were auto-filled
    chief.apply_changes(@project, changes)
  else
    @automated_fields = []
  end

  # Check for overridden fields from save redirect
  @overridden_fields = []
  if params[:overridden]
    # Parse and validate (security)
    @overridden_fields = params[:overridden].split(',').select do |field|
      field.match?(/\A[a-z_0-9]+\z/)
    end.map(&:to_sym)
  end

  # Make these available to view
  @automated_fields = @automated_fields.map(&:to_sym)
end

private

def get_level_saved_flag(level)
  case level
  when 'passing' then :passing_saved
  when 'silver' then :silver_saved
  when 'gold' then :gold_saved
  when 'baseline-1' then :baseline_1_saved
  when 'baseline-2' then :baseline_2_saved
  when 'baseline-3' then :baseline_3_saved
  end
end
```

#### View: Apply CSS Classes Directly in HTML

```erb
<!-- In app/views/projects/_criterion.html.erb or similar -->
<%
  field_name = :"#{criterion.name}_status"
  css_classes = ['criterion-data']

  # Add highlight classes based on server-side data
  if @automated_fields&.include?(field_name)
    css_classes << 'highlight-automated'
  end

  if @overridden_fields&.include?(field_name)
    css_classes << 'highlight-overridden'
  end
%>

<div class="<%= css_classes.join(' ') %>"
     data-criterion="<%= field_name %>"
     id="criterion-<%= field_name %>">
  <%= render_criterion_row(criterion, project) %>
</div>
```

**Result**: Yellow and orange highlights appear even with JavaScript disabled.

### JavaScript Enhancement (Progressive Enhancement)

JavaScript only provides **optional enhancements**:
- Auto-expand panels containing highlighted fields
- Smooth scroll to first overridden field
- Focus management for accessibility

```javascript
// Progressive enhancement - only runs if JavaScript enabled
document.addEventListener('DOMContentLoaded', function() {
  // Auto-expand panels with automated or overridden fields
  document.querySelectorAll('.highlight-automated, .highlight-overridden').forEach(field => {
    const panel = field.closest('.panel-collapse');
    if (panel) {
      panel.classList.add('show');
      // Also open parent panels if nested
      let currentElement = panel;
      while (currentElement) {
        const parentCollapse = currentElement.parentElement?.closest('.panel-collapse');
        if (parentCollapse) {
          parentCollapse.classList.add('show');
        }
        currentElement = parentCollapse;
      }
    }
  });

  // Scroll to first overridden field (from URL anchor)
  if (window.location.hash) {
    setTimeout(() => {
      const targetId = 'criterion-' + window.location.hash.substring(1);
      const target = document.getElementById(targetId);
      if (target) {
        target.scrollIntoView({ behavior: 'smooth', block: 'center' });

        // Set focus for keyboard navigation
        const focusable = target.querySelector('input, select, textarea');
        if (focusable) focusable.focus();
      }
    }, 500); // Delay for panel expansion
  }
});
```

**Graceful Degradation Without JavaScript**:
- ✅ Highlights still visible (server-rendered CSS classes)
- ✅ Users can see which fields were changed
- ❌ Panels might be collapsed (users must click to expand)
- ❌ No auto-scroll (users must find highlighted fields manually)
- ❌ URL anchor won't scroll automatically

### CSS for Overridden Field Styling

Add to `app/assets/stylesheets/projects.scss`:

```scss
// Overridden field highlighting (orange/amber theme - Chief changed user input)
.highlight-overridden {
  border-left: 4px solid #ff8c00 !important; // Dark orange
  background-color: #fff4e6; // Light orange background
  padding-left: 12px;
  animation: pulse-orange 2s ease-in-out 3; // Pulse 3 times
  transition: background-color 0.3s ease;

  &:hover {
    background-color: #ffe6cc; // Slightly darker on hover
  }

  &::before {
    content: "⚠️ ";
    font-size: 0.9em;
    opacity: 0.8;
  }
}

@keyframes pulse-orange {
  0%, 100% {
    background-color: #fff4e6;
    border-left-width: 4px;
  }
  50% {
    background-color: #ffe6cc;
    border-left-width: 6px;
  }
}

// Automated field highlighting (yellow theme) - for "before edit" automation
.highlight-automated {
  border-left: 4px solid #ffcc00 !important; // Gold
  background-color: #ffffcc; // Light yellow
  padding-left: 12px;

  &::before {
    content: "🤖 ";
    font-size: 0.8em;
    opacity: 0.7;
  }
}
```

### Alternative: CSS-Only Panel Expansion

For better no-JavaScript experience, use URL fragment and CSS `:target` pseudo-class:

```erb
<!-- Redirect with fragment pointing to overridden field -->
redirect_to edit_project_path(
  @project,
  level: @criteria_level,
  anchor: first_overridden.to_s,
  overridden: overridden_fields.map { |r| r[:field].to_s }.join(',')
)
```

```scss
// CSS to auto-expand panel containing targeted element
.panel-collapse:has(#criterion-#{$field}:target) {
  display: block !important; // Override Bootstrap collapse
}

// Or using more general selector
.criterion-data:target {
  scroll-margin-top: 100px; // Offset for fixed header

  // Ensure parent panel is visible
  .panel-collapse {
    display: block !important;
  }
}
```

**Browser support**: `:has()` is supported in modern browsers (2023+). For older browsers, JavaScript fallback still works.

## Testing Strategy

### Controller Tests

```ruby
# test/controllers/projects_controller_test.rb

test 'should override and redirect to edit when high confidence changes user input' do
  project = projects(:one)
  sign_in users(:admin_user)

  # Mock Chief to return forced overrides in multiple directions
  Chief.stub :new, MockChiefWithOverrides.new do
    patch project_url(project, locale: :en), params: {
      project: {
        floss_license_osi_status: 'Met',  # Will be overridden to Unmet
        contribution_status: '?'           # Will be overridden to Met
      },
      level: 'passing'
    }
  end

  # Should redirect to edit, not show
  assert_redirected_to edit_project_path(project, level: 'passing')

  # Should include overridden fields in URL
  assert_match /overridden=.*floss_license_osi_status/, @response.redirect_url
  assert_match /overridden=.*contribution_status/, @response.redirect_url

  # Should have warning flash
  assert_match /We corrected.*field/, flash[:warning]
  assert_match /changed from/, flash[:warning]

  # Should save both overrides
  project.reload
  assert_equal 'Unmet', project.floss_license_osi_status
  assert_equal 'Met', project.contribution_status
end

test 'should exit normally when no overrides made' do
  project = projects(:one)
  sign_in users(:admin_user)

  # Mock Chief to agree with user input
  Chief.stub :new, MockChiefWithoutOverrides.new do
    patch project_url(project, locale: :en), params: {
      project: { description_good_status: 'Met' },
      level: 'passing'
    }
  end

  # Should redirect to show page
  assert_redirected_to project_path(project)

  # Should have success flash
  assert_match /updated/i, flash[:success]
end

class MockChiefWithOverrides
  def initialize; end

  def propose_changes(level:, changed_fields:)
    {
      floss_license_osi_status: {
        value: 'Unmet',
        confidence: 5,
        explanation: 'Detected license (Proprietary) is not OSI-approved'
      },
      contribution_status: {
        value: 'Met',
        confidence: 5,
        explanation: 'CONTRIBUTING.md file found in repository'
      }
    }
  end

  def apply_changes(project, changes)
    changes.each { |field, data| project[field] = data[:value] }
  end
end

class MockChiefWithoutOverrides
  def initialize; end

  def propose_changes(level:, changed_fields:)
    {} # No changes proposed
  end

  def apply_changes(project, changes)
    # No-op
  end
end
```

### System Tests

```ruby
# test/system/automation_override_test.rb

class AutomationOverrideTest < ApplicationSystemTestCase
  test 'user sees overridden fields highlighted and scrolled to' do
    project = projects(:one)
    sign_in_as users(:admin_user)

    visit edit_project_path(project, locale: :en, level: 'passing')

    # User tries to claim OSI license
    choose 'project_floss_license_osi_status_met'
    click_button 'Save and Exit'

    # Should redirect back to edit (mocked Chief override)
    assert_current_path edit_project_path(project, level: 'passing')

    # Should show warning flash
    assert_text 'We corrected'
    assert_text 'changed from'

    # Should highlight overridden field
    overridden_field = find('[data-criterion="floss_license_osi_status"]')
    assert overridden_field[:class].include?('highlight-overridden')

    # Panel should be expanded
    panel = overridden_field.ancestor('.panel-collapse')
    assert panel[:class].include?('show')
  end

  test 'user exits normally when no overrides made' do
    project = projects(:one)
    sign_in_as users(:admin_user)

    visit edit_project_path(project, locale: :en, level: 'passing')

    # User sets value that Chief agrees with
    choose 'project_description_good_status_met'
    click_button 'Save and Exit'

    # Should go to show page
    assert_current_path project_path(project)

    # Should show success message
    assert_text 'updated'
  end
end
```

## Performance Considerations

### Avoiding N+1 Queries

When building flash message for overridden fields, preload criteria:

```ruby
def handle_overridden_fields(overridden_fields)
  # Preload all criteria to avoid N+1
  field_names = overridden_fields.map { |r| r[:field].to_s.chomp('_status') }
  criteria_map = Criteria.where(name: field_names).index_by(&:name)

  message = "We corrected #{overridden_fields.size} field(s):\n"
  overridden_fields.each do |r|
    criterion_name = r[:field].to_s.chomp('_status')
    criterion = criteria_map[criterion_name]
    title = criterion&.title || r[:field].to_s.humanize
    message += "• '#{title}' → #{r[:new_value]} (#{r[:explanation]})\n"
  end

  # ... rest of method
end
```

### Limiting URL Length

If many fields overridden, URL could get long. Consider:

```ruby
# Store overridden fields in session instead of URL
session[:overridden_fields] = overridden_fields
redirect_to edit_project_path(@project, level: @criteria_level, show_overridden: true)

# Then in edit action:
if params[:show_overridden] && session[:overridden_fields]
  @overridden_fields = session[:overridden_fields]
  session.delete(:overridden_fields)
end
```

## Accessibility Considerations

### Screen Reader Announcements

```erb
<!-- Add ARIA live region for flash messages -->
<div role="alert" aria-live="assertive" class="sr-only">
  <% if flash[:warning] %>
    <%= flash[:warning] %>
  <% end %>
</div>
```

### Keyboard Navigation

Ensure overridden fields can be reached via keyboard:

```javascript
// Set focus on first overridden field
const firstOverridden = document.querySelector('.highlight-overridden input, .highlight-overridden select');
if (firstOverridden) {
  firstOverridden.focus();
}
```

## Security Considerations

### Preventing Flash Message Injection

Always escape user input in flash messages:

```ruby
message += "• '#{ERB::Util.html_escape(criterion_name)}' → Unmet (#{ERB::Util.html_escape(r[:explanation])})\n"
```

### Validating Overridden Field Parameter

```ruby
def edit
  if params[:overridden]
    # Validate overridden field names to prevent injection
    overridden_fields = params[:overridden].split(',').select do |field|
      field.match?(/\A[a-z_]+\z/) # Only lowercase letters and underscores
    end
    @overridden_fields = overridden_fields
  end
end
```
