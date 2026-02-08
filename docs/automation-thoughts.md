# Automation thoughts

The best practices badge system has long had an automation system,
where a "Chief" coordinates various "Detectives".
However, now that we have two series of badges (metal and baseline),
where users might never see one series or the other,
it's time to improve how we handle automation.

## Overview

There are three distinct use cases for automation:

1. **Before edit**: Help the human fill in the form for a badge level
   by auto-analyzing when first editing that level
2. **Before save**: Validate user input and counter clearly-false information,
   including security validation of direct API calls (POST/PATCH)
3. **Periodic verification**: Cron job to detect capability loss across all
   badges and force corrections after multiple verification failures

**Key principle**: Humans should always have a chance to review automation results
before they're saved, except for high-confidence (4-5) overrides that prevent
clearly false information.

**Current problem**: The existing system may modify values users have never seen,
doesn't clearly show what it proposed, and runs all detectives even when
analyzing a single badge level.

**Terminology**: "Level" refers to badge levels (passing, silver, gold,
baseline-1, baseline-2, baseline-3), not subsections within a level.

## Database Changes

Add boolean fields to track whether each badge level has been saved:

- `passing_saved` (default: false)
- `silver_saved` (default: false)
- `gold_saved` (default: false)
- `baseline_1_saved` (default: false)
- `baseline_2_saved` (default: false)
- `baseline_3_saved` (default: false)

**Migration**:

```ruby
class AddLevelSavedFlags < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :passing_saved, :boolean, default: false, null: false
    add_column :projects, :silver_saved, :boolean, default: false, null: false
    add_column :projects, :gold_saved, :boolean, default: false, null: false
    add_column :projects, :baseline_1_saved, :boolean, default: false, null: false
    add_column :projects, :baseline_2_saved, :boolean, default: false, null: false
    add_column :projects, :baseline_3_saved, :boolean, default: false, null: false
  end
end
```

## Use Case 1: Before Edit (First Time)

**Goal**: Auto-fill initial values when user first edits a badge level

**Trigger**: User navigates to edit form for a level (e.g., `/en/projects/123/edit?level=passing`)

**Behavior**:

1. Check `passing_saved` flag
2. If false (never saved before):
   - Display message: "Analyzing project data..."
   - Run Chief with `level: 'passing'` parameter
   - Chief analyzes ONLY criteria in passing level (~60 criteria)
   - Skips detectives that don't produce passing-level outputs
   - Apply results with normal confidence rules (override `?` always, override filled values only if confidence >= 4)
   - Display edit form with automated fields highlighted (see UI section)
3. If true (previously saved):
   - Skip automation
   - Display edit form immediately (faster UX)

**Performance**: ~20-30% faster than analyzing all levels (skips irrelevant detectives)

## UI: Highlighting Automated Fields

**Goal**: Make it obvious which fields were auto-filled so users can review them

**Implementation** (Server-Side for Accessibility):

1. **Track automated fields**: When Chief runs before edit, store changed fields in controller:
   ```ruby
   @automated_fields = [:description_good_status, :interact_status, ...]
   ```

2. **Apply CSS classes in view template** (not JavaScript):
   ```erb
   <%
     field_name = :"#{criterion.name}_status"
     css_classes = ['criterion-data']
     css_classes << 'highlight-automated' if @automated_fields&.include?(field_name)
   %>
   <div class="<%= css_classes.join(' ') %>" data-criterion="<%= field_name %>">
     <%= render_criterion_row(criterion, project) %>
   </div>
   ```

3. **Highlight with CSS**:
   ```scss
   .highlight-automated {
     background-color: #ffffcc; // Light yellow
     border-left: 4px solid #ffcc00; // Gold border
     padding-left: 8px;
     
     &::before {
       content: "🤖 ";
       font-size: 0.8em;
       opacity: 0.7;
     }
   }
   ```

4. **Optional JavaScript enhancement**: Auto-expand panels containing automated fields:
   ```javascript
   // Progressive enhancement only
   document.querySelectorAll('.highlight-automated').forEach(field => {
     const panel = field.closest('.panel-collapse');
     if (panel) panel.classList.add('show');
   });
   ```

5. **No-JavaScript fallback**: Highlights visible, users manually expand panels

**Note**: Automated field list is NOT stored in database (ephemeral data).
It only exists during the edit session. If user navigates away and comes back,
no highlighting (they've already reviewed once).

## Chief Optimization: Topological Sort

**Current problem**: Chief runs ALL detectives sequentially even when analyzing
a single badge level. Wastes CPU and network calls on irrelevant detectives.

**Solution**: Use detective INPUTS/OUTPUTS declarations to:

1. Determine which fields need analyzing (based on level parameter)
2. Work backwards to find required detectives (including dependencies)
3. Topologically sort by dependencies (ensures correct order)
4. Run ONLY the needed detectives

**Benefits**:

- **Passing level**: Skip ~2-3 detectives (e.g., BaselineDetective) = 20-30% reduction
- **Baseline levels**: Skip ~5-6 detectives (e.g., silver/gold-only detectives) = 50-60% reduction
- **Whole project**: Run all detectives (same as before) but in correct dependency order
- **Foundation for parallelization**: Independent detectives can run concurrently in future

**API**:

```ruby
# Analyze only passing-level criteria
Chief.new(project, client_factory).autofill(level: 'passing')

# Analyze only specific changed fields (for save validation)
Chief.new(project, client_factory).autofill(
  level: 'passing',
  changed_fields: [:description_good_status, :homepage_url]
)

# Analyze everything (for cron job)
Chief.new(project, client_factory).autofill(level: nil, changed_fields: nil)
```

**Implementation**: See `,chief-topological-sort.md` for detailed algorithm,
code examples, and testing strategy.

## Use Case 2: Before Save (Validation)

**Goal**: Validate user input and prevent clearly false information,
including security validation of direct API calls

**Trigger**: User clicks "Save and Continue" or "Save and Exit"
(or sends direct PATCH/POST to API)

**Current behavior**: Chief already runs on every save (projects_controller.rb:561)

**Proposed changes**:

### Chief Analysis on Save

Run Chief with two parameters:

1. **level**: The badge level being edited (e.g., 'passing')
   Note that if the API for JSON is being posted to, we won't have this
   information; we'd have to pass `nil` or some other value in this case
   to indicate we don't have it.
2. **changed_fields**: Fields user modified in this save (for security validation)
   In the HTML interface this would typically be a subset of the criteria
   of the given badge level (which we *would* know), but it's possible for
   it to be something else.

The chief must trace back to verify that the values are valid for:

(1) all criteria of the badge level, if we are given one, AND
(2) all the criteria which are being proposed to be changed, which
    might not even all be in the badge level even when one is given
    (though they usually would be).

```ruby
def update
  # ... existing code ...
  
  changed_fields = project_params.keys.map(&:to_sym)
  
  Chief.new(@project, client_factory).autofill(
    level: @criteria_level,
    changed_fields: changed_fields
  )
  
  # ... continue with save ...
end
```

**Why changed_fields?** Security. A user could send direct PATCH/POST to API
bypassing the web form. We must validate those fields even if they're not
in the current level. Example:

```
PATCH /projects/123
{ "silver_test_status": "Met" }  # User not editing via form
```

We must run detectives that produce `silver_test_status` to validate this claim,
even if user isn't editing the silver level via web form.

### Save Button Behavior

**Current buttons**: "Save and Continue", "Save and Exit"

**Key principle**: If we override ANY values with high confidence (4-5),
we ALWAYS re-open the edit form so users can see what was rejected and why.

#### "Save and Continue"

**Current name is fine** (or rename to "Save and Refresh" if preferred)

1. Run Chief analysis (level + changed_fields)
2. Apply ALL proposed changes (even confidence < 4)
3. Save to database
4. Set `{level}_saved = true`
5. Redirect back to edit form
6. Highlight all changed fields (yellow background)
7. Auto-expand panels containing changes
8. Flash message: "Saved. Re-analyzed X fields." (if any changes made)

**Use case**: User wants fresh automation suggestions after changing values

#### "Save and Exit"

1. Run Chief analysis (level + changed_fields)
2. Apply ONLY high-confidence changes (confidence >= 4)
3. **If ANY forced overrides were made** (Chief changed values user explicitly set):
   - Save to database WITH the forced overrides
   - Set `{level}_saved = true`
   - Redirect back to edit form (NOT to show page - ensure transparency)
   - **Ensure panels with overridden values start OPEN**
   - **Scroll to/focus on FIRST overridden value** (anchor link or JavaScript scroll)
   - Flash warning: "We corrected X fields based on project analysis. Please review."
   - List which fields were overridden, from what to what, and why with explanations
4. If no forced overrides:
   - Save to database
   - Set `{level}_saved = true`
   - Exit to project show page (normal behavior)

**Use case**: User wants to save and leave, but if we override ANY of their values with high confidence, we show them what changed and why.

**Example forced overrides** (multiple directions):

```
User sets: floss_license_osi_status = "Met"
           crypto_used_network_status = "N/A"
           contribution_status = "?"
           
Chief detects: 
  - License is "Proprietary" (confidence: 5) → Force "Unmet"
  - Crypto usage found in code (confidence: 4) → Force "Met"
  - CONTRIBUTING file exists (confidence: 5) → Force "Met"
                
Action: 
  1. Save with all three overrides applied
  2. Redirect to edit form (not show page)
  3. Open "Legal" panel (has floss_license_osi_status)
  4. Open "Security" panel (has crypto_used_network_status) 
  5. Open "Change Control" panel (has contribution_status)
  6. Scroll to first overridden field (floss_license_osi_status)
  7. Flash message (neutral tone, not error):
     "We corrected 3 fields based on project analysis:
      • 'OSI-approved license' changed from 'Met' to 'Unmet' 
        (Detected license 'Proprietary' is not OSI-approved)
      • 'Cryptography used' changed from 'N/A' to 'Met' 
        (Found network crypto usage in codebase)
      • 'Contributing file' changed from '?' to 'Met' 
        (CONTRIBUTING.md file found in repository)
     Please review these changes."
```

**Rationale**: Users should ALWAYS know when we override their explicit input, 
regardless of direction. Most overrides will be helpful ("?" → "Met"), but some
will be corrections ("Met" → "Unmet"). Consistent transparency builds trust.

## Use Case 3: Periodic Verification (Cron Job)

**Goal**: Detect capability loss across all criteria and force badge loss
if projects no longer meet requirements

**Status**: Design documented here, implementation deferred to Phase 2

**Why later**: Complex retry logic, false positive handling, notification system,
extensive testing needed. Not required for immediate UX improvements.

### Design

**Frequency**: Run nightly or weekly (configurable)

**Scope**: All projects with badges (passing, silver, gold, baseline-1/2/3)

**Process**:

1. **Iterate through projects**:
   ```ruby
   Project.where.not(badge_percentage_0: 0).find_each do |project|
     VerifyBadgeJob.perform_later(project.id)
   end
   ```

2. **For each project**:
   - Run Chief with `level: nil, changed_fields: nil` (analyze everything)
   - Compare Chief results to current values
   - Identify fields where Chief has confidence >= 4 and disagrees
   - Track failures in database

3. **Failure tracking**:
   - Add `verification_failures` JSON column to projects table
   - Store: `{ "floss_license_osi_status" => { count: 2, first_failed_at: "2026-02-01", last_checked_at: "2026-02-07" } }`
   - Increment failure count each time verification fails
   - Reset count to 0 if verification succeeds

4. **Force corrections after N failures**:
   - **Threshold**: 3 consecutive failures over 3+ days
   - **Action**: Apply high-confidence changes (confidence >= 4)
   - **Effect**: May cause badge loss if criteria no longer met
   - **Rationale**: Prevents false positives from temporary outages

5. **Notification**:
   - Email project owner: "Your [passing] badge has been revoked because..."
   - List which criteria failed and why
   - Provide link to re-apply
   - CC: Badge admin team (for monitoring)

### Retry Logic & False Positive Prevention

**Problem**: Temporary outages (GitHub down, website timeout) shouldn't cause badge loss

**Solutions**:

1. **Multiple verification attempts** (3 failures required)
2. **Exponential backoff**: Check day 1, day 3, day 7 before forcing
3. **Ignore transient errors**:
   - HTTP 5xx errors: Don't count as failure (server problem)
   - Timeouts: Don't count as failure (network problem)
   - Only count 4xx errors or successful checks that show "Unmet"
4. **Grace period**: Don't force changes within 30 days of badge achievement
   (gives projects time to stabilize)
5. **Manual override**: Admins can reset failure counts if needed

### Performance Considerations

**Problem**: Analyzing all criteria for all projects is expensive

**Mitigations**:

1. **Run overnight**: Non-peak hours (2-6 AM UTC)
2. **Batch processing**: Process N projects per hour, not all at once
3. **Skip active projects**: If edited in last 7 days, skip (human already reviewing)
4. **Rate limiting**: Add delays between GitHub API calls
5. **Job queue**: Use solid_queue with retry logic for failures
6. **Monitoring**: Track job duration, failure rates, API usage

**Acceptable runtime**: 4-6 hours for ~25,000 projects (6-7 projects/second)

### Database Schema Changes

```ruby
class AddVerificationTracking < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :verification_failures, :jsonb, default: {}, null: false
    add_column :projects, :last_verified_at, :datetime
    add_column :projects, :verification_enabled, :boolean, default: true, null: false
    
    add_index :projects, :last_verified_at
    add_index :projects, :verification_enabled
  end
end
```

### Rake Task

```ruby
# lib/tasks/verify_badges.rake
namespace :badges do
  desc 'Verify all badge claims and force corrections for persistent failures'
  task verify_all: :environment do
    VerifyAllBadgesJob.perform_later
  end
end
```

### Cron Schedule (via Heroku Scheduler or similar)

```bash
# Run nightly at 2 AM UTC
0 2 * * * cd /app && bundle exec rake badges:verify_all
```

### Implementation Priority

**Phase 1 (8-12 hours)**: Chief optimization with topological sort - DO NOW
- Foundation for all three use cases
- Immediate performance benefits for human editing

**Phase 2 (10-15 hours)**: Before-edit automation and UI highlighting - DO NEXT
- Database migration for `*_saved` flags
- Controller logic for first-edit automation
- View highlighting with CSS/JavaScript
- Testing

**Phase 3 (8-12 hours)**: Save button differentiation - DO NEXT
- "Save and Continue" vs "Save and Exit" behavior
- Flash messages for forced changes
- Testing

**Phase 4 (24-40 hours)**: Periodic verification cron job - DO LATER
- Database migration for failure tracking
- VerifyBadgeJob implementation
- Retry logic and false positive prevention
- Email notifications
- Extensive staging testing (monitor for 2-4 weeks)
- Production rollout with feature flag

**Total estimated effort**: 50-79 hours

## Open Questions and Concerns

The following issues need decisions or clarification before implementation:

### 1. Direct API Calls (POST/PATCH) - Response Format

**Issue**: When users send direct API requests (not via web form), we validate 
`changed_fields` but haven't specified the response behavior.

Example:
```
PATCH /projects/123.json
{ "description_good_status": "Met" }
```

**Questions**:
- What JSON response when overrides occur?
- What HTTP status code? (200 OK? 422 Unprocessable?)
- Should we return override details in response body?

**Proposed behavior**:
```ruby
respond_to do |format|
  format.html { # existing redirect to edit logic }
  format.json {
    if overridden_fields.any?
      render json: {
        success: true,
        saved: true,
        overrides: overridden_fields.map { |f| 
          { field: f[:field], old: f[:old_value], new: f[:new_value], 
            reason: f[:explanation] }
        },
        message: "Saved with #{overridden_fields.size} correction(s)"
      }, status: :ok  # Or 422? Or 200?
    else
      render json: { success: true }, status: :ok
    end
  }
end
```

**Decision needed**: Is this the right approach? What status code?

**Answer**: Yes, this is the right approach.
The status code should be 200 (OK); anything else will confuse
naive clients, and specialized clients can look at the overrides.

### 2. "Save and Continue" - Highlight Color

**Issue**: "Save and Continue" applies ALL changes (even confidence < 4) and 
highlights them, but color scheme is unclear.

**Questions**:
- Should low-confidence suggestions (1-3) use yellow (like before-edit)?
- Should high-confidence overrides (4-5) use orange (like forced corrections)?
- Or should everything be yellow since user requested re-analysis?

**Proposal**: Use yellow for all "Save and Continue" changes (user asked for help)
vs orange only for "Save and Exit" forced overrides (system insisted on correction).

**Decision needed**: Confirm color scheme for "Save and Continue"

**Answer**: Use orange (override) only when there was a previous answer
other than '?' that was overridden. If the answer was unknown before,
there's no reason to use orange to call attention to it.

### 3. Database Migration - Backfill for Existing Projects

**Issue**: Migration sets all `*_saved` flags to `false` by default. This means
first edit of ~25,000 existing projects will run Chief automation, even for 
mature projects with all fields filled.

**Concern**: Wasted resources running automation on projects that don't need it.

**Proposed solution**:
```ruby
class AddLevelSavedFlags < ActiveRecord::Migration[7.0]
  def up
    add_column :projects, :passing_saved, :boolean, default: false, null: false
    # ... other columns ...
    
    # Backfill: If project has criteria filled, mark as already saved
    # (Assumes they've been through the editing process before)
    Project.where('badge_percentage_0 > 0').update_all(passing_saved: true)
    Project.where('badge_percentage_1 > 0').update_all(silver_saved: true)
    Project.where('badge_percentage_2 > 0').update_all(gold_saved: true)
    
    # For baseline series, check if any baseline criteria filled
    # (more complex - would need to query specific fields)
  end
end
```

**Alternative**: Accept the one-time cost on first edit post-deployment.

**Decision needed**: Should we backfill based on existing data?

**Answer**: You're right! If there's evidence that the user has
*already* edited the project at that badge level, then the value
of `_saved` should be true. The database migration for `_saved` should include
code to set `_saved` to true in those cases.
Note that some criteria cross multiple badge levels; only count a
form as `saved` at the level if there's at least one criteria set to
a value other than `?` that confirmed this level was edited.

### 4. Accessibility - ARIA Labels for Screen Readers

**Issue**: Yellow/orange highlights rely on color. Screen reader users need 
text alternatives.

**Current**: Icons provide some indication (🤖, ⚠️) but emoji might not be read clearly.

**Proposed addition**:
```erb
<div class="<%= css_classes.join(' ') %>" 
     aria-label="<%= aria_label_for_field(field_name) %>"
     role="<%= 'alert' if overridden %>">
     
<%
def aria_label_for_field(field_name)
  if @overridden_fields&.include?(field_name)
    "This field was corrected by automated analysis"
  elsif @automated_fields&.include?(field_name)
    "This field was automatically filled. Please review."
  end
end
%>
```

**Decision needed**: Is this sufficient? Any other a11y concerns?

**Answer**: Let's use color, icons, *and* aria text when generating HTML.
That should fully resolve accessibility concerns.
Since these will all be generated server-side, we can fully control this.

I'm not worried about the JSON.
JSON is typically for computers not humans, and is
fully accessible through pretty printers anyway.

### 5. Internationalization (i18n) of Messages

**Issue**: Flash messages and UI text are currently hardcoded in English:
```ruby
message = "We corrected #{overridden_fields.size} field(s) based on project analysis:"
```

**Proposed solution**: Use Rails i18n:
```ruby
message = t('projects.update.overridden_fields_intro', count: overridden_fields.size)
overridden_fields.each do |r|
  message += t('projects.update.override_detail',
               criterion: criterion_name,
               old_value: r[:old_value],
               new_value: r[:new_value],
               explanation: r[:explanation])
end
message += t('projects.update.please_review')
```

**Decision needed**: Should we implement i18n from the start or defer to later?

**Answer**: Let's implement i18n from the start, and put it in the HTML flash.
Our current approach was because we didn't implement a "flash" to
report problems, and we instead stuffed the information into the data fields
themselves. In retrospect, that was a workaround we should stop using.
Let's stop doing that, and provide proper flash messages
instead, which enables us to stop working around "not adding text to the
justification" too.

We don't have a locale for the JSON, so let's use the English in all cases
for the message for consistency. In the future I guess we could add an
option for locales for JSON, but I doubt it would be used.

### 6. Error Handling - Chief Failures During Save

**Issue**: If Chief raises exception during save, current rescue silently fails.
User might not know automation didn't run, could save invalid data without validation.

**Current behavior** (in chief.rb):
```ruby
rescue @intercept_exception => e
  log_detective_failure(...)  # Just logs, continues
end
```

**Proposed enhancement** (in controller):
```ruby
begin
  chief.autofill(level: @criteria_level, changed_fields: changed_fields)
rescue StandardError => e
  Rails.logger.error "Chief analysis failed during save: #{e}"
  flash[:info] = "Saved. Automated analysis temporarily unavailable."
  # Continue with save - don't block user
end
```

**Decision needed**: Is this the right balance? Should we block save on Chief failure?

**Answer**: This is definitely a problem, and answers aren't easy.
If an attacker can easily make our analysis fail, they could create false
answers. On the other hand, we don't want to lose data.
It's a good question.

In reality, our automation doesn't have the confidence to override most
criteria. So let's have the detectives report which criteria
(of the ones they generate) that *might* override human answers.
Maybe we should have 2 lists that detectives report:
the ones they report that MIGHT override
and the ones they report that will never override.

If the Chief or detectives raise exceptions, let's catch that, and do the
following: save all data (justifications, descriptions, most status values)
*except* for the proposed changes in status that *might* be overridden.

If we're replying HTML, reply with an edit field, flash noting what wasn't
saved, and highlighting in orange the ones not saved... while still keeping
their values submitted. If the problem is intermittent, they can wait a
moment and try to save again, and at least they'll know there was a problem.

If we're replying JSON, handle it like other errors, reporting the
fields that the user *tried* to change but were not changed.

### 7. Monitoring and Metrics

**Issue**: No instrumentation to track:
- How often we override user input (success rate)
- Which detectives find the most issues (effectiveness)
- Performance impact of Chief optimization
- False positive rate for periodic verification

**Proposed solution**: Add ActiveSupport instrumentation:
```ruby
# In controller when overrides occur
ActiveSupport::Notifications.instrument('chief.override',
  project_id: @project.id,
  field: field,
  old_value: old_value,
  new_value: new_value,
  confidence: confidence,
  detective: detective_name
)

# Subscribe in initializer
ActiveSupport::Notifications.subscribe('chief.override') do |name, start, finish, id, payload|
  # Send to metrics system (StatsD, etc.)
  # Or store in database for analysis
end
```

**Decision needed**: Should we add instrumentation now or later? What metrics matter most?

**Answer**: If we override a user answer,
create a short Rails log noting the project#, user editing, and fields
overridden. We don't need to track more at this time.

### 8. User Option to Skip Re-analysis

**Issue**: If user knows automation is wrong (e.g., private repo Chief can't access),
they have no way to save without triggering re-analysis and overrides.

**Proposed solutions**:

**Option A**: Third save button
- "Save and Exit" (current behavior)
- "Save and Continue" (re-analyze)
- "Save Without Analysis" (skip Chief entirely)

**Option B**: Checkbox on form
```erb
<%= check_box_tag 'skip_automation', '1', false, 
    id: 'skip_automation' %>
<label for="skip_automation">
  Skip automated checks (I will provide justification)
</label>
```

**Concern**: Could be abused to bypass validation. Maybe admin-only?

**Decision needed**: Do we need this? If yes, which approach? Any restrictions?

**Answer**: No special mechanism needed for now.
We might allow an admit to override in the future.
For now, we hope the messages will help users fix the problem.
System admins can always override an answer with SQL :-).

### 9. Show Confidence Levels in UI

**Issue**: Users see that fields were automated/overridden but not how confident
the system is.

**Proposed enhancement**: Display confidence in UI:
```erb
<span class="automation-confidence">
  <% if @automated_fields&.include?(field_name) %>
    🤖 Auto-filled (confidence: <%= get_confidence(field_name) %>/5)
  <% elsif @overridden_fields&.include?(field_name) %>
    ⚠️ Corrected (confidence: <%= get_confidence(field_name) %>/5)
  <% end %>
</span>
```

**Alternative**: Just show "High confidence" vs "Medium confidence" (simpler for users)

**Decision needed**: Is this helpful or too technical? Skip for now?

**Answer**: Skip for now. The confidence levels are really just to help
adjudicate internally.

### 10. Automation History/Audit Log

**Issue**: No historical record of automation changes. Hard to debug disputes or
understand why a badge was lost.

**Proposed solution**: Add `automation_log` JSONB column:
```ruby
automation_log: [
  {
    timestamp: "2026-02-08T01:00:00Z",
    action: "auto_filled",
    field: "floss_license_osi_status",
    value: "Met",
    confidence: 5,
    detective: "FlossLicenseDetective"
  },
  {
    timestamp: "2026-02-10T14:30:00Z",
    action: "user_override",
    field: "floss_license_osi_status",
    value: "Unmet",
    justification: "License changed to proprietary"
  },
  {
    timestamp: "2026-02-12T02:00:00Z",
    action: "cron_verified",
    field: "floss_license_osi_status",
    value: "Unmet",
    confidence: 4,
    detective: "FlossLicenseDetective"
  }
]
```

**Concern**: Could grow large over time. Maybe limit to last 50 entries?

**Decision needed**: Implement now or defer? How much history to keep?

**Answer**: Don't do this until we have a cron job.
At that point, we should send emails if we override values,
and send a bcc copy of that email to a trusted endpoint,
and use that as our logs.
Our system is already overwhelmed, we routinely lose parts of logs
because there's too much activitgy. I worry recording all that will
overwhelm the system further. Storing emails on a separate system
seems safer.

### 11. Phased Rollout Strategy

**Issue**: Current plan implements everything at once. If problems occur,
hard to identify which component is failing.

**Proposed phased approach**:

**Phase 1** (Week 1-2): Chief optimization only
- Implement topological sort
- Monitor performance improvements
- No UI changes yet
- Feature flag: `CHIEF_OPTIMIZED=true`

**Phase 2** (Week 3-4): Before-edit automation
- Add `*_saved` flags
- Yellow highlights for first-edit automation
- Feature flag: `AUTOMATION_FIRST_EDIT=true`

**Phase 3** (Week 5-6): Save overrides
- Orange highlights for forced corrections
- Redirect to edit on override
- Feature flag: `AUTOMATION_OVERRIDES=true`

**Phase 4** (Month 3-4): Periodic verification
- Cron job implementation
- Extensive staging testing
- Feature flag: `AUTOMATION_CRON=true`

**Benefit**: Can disable individual features if issues arise. Easier to monitor
impact of each change.

**Decision needed**: All-at-once or phased? If phased, which schedule?

### 12. Testing Strategy for Periodic Verification

**Issue**: Cron job will affect ~25,000 projects. Testing is critical but complex.

**Concerns**:
- False positives from temporary outages
- Performance impact (can it complete overnight?)
- Email volume (if many badges lost at once)
- Edge cases (private repos, expired tokens, etc.)

**Proposed staging test plan**:
1. Run on 100 test projects in staging
2. Monitor for false positives over 2 weeks
3. Run on 1,000 random projects in staging
4. Monitor performance (can it scale?)
5. Gradual production rollout: 100/day, then 1000/day, then all

**Decision needed**: Is 2-4 weeks of staging testing sufficient? What metrics
indicate readiness?

**Answer**:
We already do something similar with email reminders to projects
which haven't completed the passing badge.

First, we should change that "reminder" email process.
Currently we stop sending it
if they have the passing badge; now, if they have the passing *or* baseline-1
badge, it should stop being sent.

Second, like the reminder process, we should process up to X
entries per day (determined by an environment variable), and record the
datetime when we process it.
Review the process we use for reminder emails.
Then create a process using that as an example (though with different
environment variable names and database field names).

## Next Steps

Please review these concerns and provide decisions/guidance by editing this document.
Add your responses inline under each concern, or create a new section with decisions.

Once decisions are made, implementation can proceed with confidence.
