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
  def up
    add_column :projects, :passing_saved, :boolean, default: false, null: false
    add_column :projects, :silver_saved, :boolean, default: false, null: false
    add_column :projects, :gold_saved, :boolean, default: false, null: false
    add_column :projects, :baseline_1_saved, :boolean, default: false, null: false
    add_column :projects, :baseline_2_saved, :boolean, default: false, null: false
    add_column :projects, :baseline_3_saved, :boolean, default: false, null: false
    
    # Backfill: Mark as saved if level has non-'?' criteria filled
    # Indicates user has already edited this level
    
    # For passing: Check if any passing-only or shared criteria are non-'?'
    Project.where('badge_percentage_0 > 0').find_each do |project|
      # Only mark saved if at least one passing criteria is explicitly set
      has_passing_data = Criteria.active('passing').any? do |criterion|
        value = project.public_send(:"#{criterion.name}_status")
        value.present? && value != '?'
      end
      project.update_column(:passing_saved, true) if has_passing_data
    end
    
    # Similar for silver, gold, and baseline levels
    Project.where('badge_percentage_1 > 0').update_all(silver_saved: true)
    Project.where('badge_percentage_2 > 0').update_all(gold_saved: true)
    
    # Baseline is trickier - need to check specific baseline criteria
    # For now, mark baseline levels as saved if any baseline percentage > 0
    # (Can refine later if needed)
  end
  
  def down
    remove_column :projects, :baseline_3_saved
    remove_column :projects, :baseline_2_saved
    remove_column :projects, :baseline_1_saved
    remove_column :projects, :gold_saved
    remove_column :projects, :silver_saved
    remove_column :projects, :passing_saved
  end
end
```

**Note**: Backfilling prevents wasting resources on mature projects during first edit post-deployment.

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

**Highlighting Rules** (Decision #2):
- **Yellow** highlight: Field was '?' and is now filled (helpful suggestion)
- **Orange** highlight: Field had a non-'?' value that was overridden (correction)
- No highlight: Field unchanged or user didn't set it

**Implementation** (Server-Side for Accessibility - Decision #4):

1. **Track automated fields and their previous values**: When Chief runs, store changes in controller:
   ```ruby
   @automated_changes = {
     description_good_status: { old: '?', new: 'Met' },  # Yellow
     floss_license_osi_status: { old: 'Met', new: 'Unmet' }  # Orange
   }
   ```

2. **Apply CSS classes in view template** (not JavaScript):
   ```erb
   <%
     field_name = :"#{criterion.name}_status"
     css_classes = ['criterion-data']
     
     if @automated_changes&.key?(field_name)
       change = @automated_changes[field_name]
       if change[:old] == '?'
         css_classes << 'highlight-automated'  # Yellow
         aria_label = t('automation.filled_unknown')
       else
         css_classes << 'highlight-overridden'  # Orange
         aria_label = t('automation.overridden', 
                       old: change[:old], new: change[:new])
       end
     end
   %>
   <div class="<%= css_classes.join(' ') %>" 
        data-criterion="<%= field_name %>"
        <% if aria_label.present? %>
          aria-label="<%= aria_label %>"
          role="status"
        <% end %>>
     <%= render_criterion_row(criterion, project) %>
   </div>
   ```

3. **CSS styling**:
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
   
   .highlight-overridden {
     background-color: #fff4e6; // Light orange
     border-left: 4px solid #ff8c00; // Dark orange border
     padding-left: 8px;
     
     &::before {
       content: "⚠️ ";
       font-size: 0.9em;
       opacity: 0.8;
     }
   }
   ```

4. **i18n translations** (Decision #5):
   ```yaml
   # config/locales/en.yml
   en:
     automation:
       filled_unknown: "This field was automatically filled. Please review."
       overridden: "We changed this from '%{old}' to '%{new}' based on project analysis."
   ```

5. **Optional JavaScript enhancement**: Auto-expand panels containing highlighted fields:
   ```javascript
   // Progressive enhancement only
   document.querySelectorAll('.highlight-automated, .highlight-overridden').forEach(field => {
     const panel = field.closest('.panel-collapse');
     if (panel) panel.classList.add('show');
   });
   ```

**Note**: Automated field list is NOT stored in database (ephemeral data).
It only exists during the edit session.

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
we ALWAYS re-open the edit form so users can see what was changed and why.

#### "Save and Continue"

**Current name is fine** (or rename to "Save and Refresh" if preferred)

1. Run Chief analysis (level + changed_fields)
2. Apply ALL proposed changes (even confidence < 4)
3. Save to database
4. Set `{level}_saved = true`
5. Redirect back to edit form
6. Highlight changed fields:
   - **Yellow**: Was '?' → now filled
   - **Orange**: Had non-'?' value → overridden (Decision #2)
7. Auto-expand panels containing changes
8. Flash message (i18n): t('projects.update.reanalyzed', count: X) if changes made

**Use case**: User wants fresh automation suggestions after changing values

#### "Save and Exit"

1. Run Chief analysis (level + changed_fields)  
2. Apply ONLY high-confidence changes (confidence >= 4)
3. **If ANY forced overrides were made** (Chief changed non-'?' values user set):
   - Save to database WITH the forced overrides
   - Set `{level}_saved = true`
   - Redirect back to edit form (NOT to show page - ensure transparency)
   - **Ensure panels with overridden values start OPEN**
   - **Scroll to/focus on FIRST overridden value** (anchor link or JavaScript scroll)
   - Flash warning (i18n): List all overridden fields with old→new values and explanations
   - Log override (Decision #7): `Rails.logger.warn "Override: project=#{@project.id} user=#{current_user.id} fields=#{overridden_fields.map(&:to_s).join(',')}"`
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

Highlighting:
  - floss_license_osi_status: ORANGE (was 'Met', now 'Unmet')
  - crypto_used_network_status: ORANGE (was 'N/A', now 'Met')
  - contribution_status: YELLOW (was '?', now 'Met')
                
Action: 
  1. Save with all three overrides applied
  2. Redirect to edit form (not show page)
  3. Open "Legal" panel (has floss_license_osi_status)
  4. Open "Security" panel (has crypto_used_network_status) 
  5. Open "Change Control" panel (has contribution_status)
  6. Scroll to first overridden field (floss_license_osi_status)
  7. Flash message (i18n):
     t('projects.update.corrected_intro', count: 3)
     • t('projects.update.corrected_detail', 
         criterion: 'OSI-approved license', 
         old: 'Met', new: 'Unmet',
         reason: '...')
     • t('projects.update.corrected_detail', ...)
     • t('projects.update.corrected_detail', ...)
     t('projects.update.please_review')
```

**Rationale**: Users should ALWAYS know when we override their explicit input, 
regardless of direction. Most overrides will be helpful ("?" → "Met"), but some
will be corrections ("Met" → "Unmet"). Consistent transparency builds trust.

### API Responses (JSON) - Decision #1

For API calls (format.json), handle overrides differently since we can't redirect to edit form:

```ruby
respond_to do |format|
  format.html { 
    # Redirect to edit if overrides, or show page if clean save
  }
  format.json {
    if @project.save
      if overridden_fields.any?
        render json: {
          success: true,
          saved: true,
          overrides: overridden_fields.map { |f| 
            { 
              field: f[:field], 
              old_value: f[:old_value], 
              new_value: f[:new_value], 
              reason: f[:explanation]  # English only for JSON
            }
          },
          message: "Saved with #{overridden_fields.size} correction(s)"
        }, status: :ok  # 200 OK - data was saved successfully
      else
        render json: { success: true }, status: :ok
      end
    else
      render json: { errors: @project.errors }, status: :unprocessable_content
    end
  }
end
```

**Rationale**: Return 200 OK because save succeeded. Clients can inspect `overrides` array to see what was changed.

### Error Handling: Chief Failures (Decision #6)

**Problem**: If Chief or detectives crash during save, we could:
- Lose all user data (if we don't save anything)
- Allow invalid data (if we save everything without validation)

**Solution**: Detective Architecture Change + Selective Saving

#### 1. Detective Declaration of Overridable Outputs

Each detective must declare which outputs CAN override human input:

```ruby
class FlossLicenseDetective < Detective
  INPUTS = [:license].freeze
  OUTPUTS = %i[floss_license_osi_status floss_license_status
               osps_le_03_01_status osps_le_03_02_status].freeze
  
  # NEW: Outputs that can have confidence >= 4 and override user input
  OVERRIDABLE_OUTPUTS = %i[floss_license_osi_status floss_license_status
                           osps_le_03_01_status osps_le_03_02_status].freeze
end

class NameFromUrlDetective < Detective
  INPUTS = %i[repo_url homepage_url].freeze
  OUTPUTS = [:name].freeze
  OVERRIDABLE_OUTPUTS = [].freeze  # Never overrides with high confidence
end
```

**Rationale**: Allows controller to know which fields are "safe" to save even if Chief fails.

#### 2. Controller Error Handling

```ruby
def update
  # ... existing setup ...
  
  changed_fields = project_params.keys.map(&:to_sym)
  
  # Determine which fields might be overridden by Chief
  potentially_overridable_fields = find_overridable_fields(
    @criteria_level, 
    changed_fields
  )
  
  begin
    chief = Chief.new(@project, client_factory)
    proposed_changes = chief.propose_changes(
      level: @criteria_level,
      changed_fields: changed_fields
    )
    chief.apply_changes(@project, proposed_changes)
    
    # Normal save path
    if @project.save
      # ... handle overrides or exit normally ...
    end
    
  rescue StandardError => e
    # Chief failed - save selectively
    Rails.logger.error "Chief analysis failed during save: #{e.class} #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Revert potentially overridable fields to original values
    potentially_overridable_fields.each do |field|
      if @project[field] != project_params[field]
        @project[field] = project_params[field]  # Keep user input
      end
    end
    
    # Try to save (all non-overridable fields + user input for overridable fields)
    if @project.save
      flash[:warning] = t('projects.update.analysis_failed',
                         count: potentially_overridable_fields.size,
                         fields: potentially_overridable_fields.join(', '))
      render :edit  # Show edit form with fields they tried to change
    else
      flash[:alert] = t('projects.update.save_failed')
      render :edit
    end
  end
end

private

def find_overridable_fields(level, changed_fields)
  # Union of: fields in this level + explicitly changed fields
  relevant_fields = []
  relevant_fields += Criteria.active(level).map { |c| :"#{c.name}_status" } if level
  relevant_fields += changed_fields
  relevant_fields.uniq!
  
  # Filter to only those that detectives can override
  overridable = Set.new
  Chief::ALL_DETECTIVES.each do |detective_class|
    overridable.merge(detective_class::OVERRIDABLE_OUTPUTS)
  end
  
  relevant_fields.select { |f| overridable.include?(f) }
end
```

**Behavior on Chief failure**:
- HTML: Re-render edit form with flash warning listing which fields weren't validated
- JSON: Return error with list of fields that couldn't be validated

**Rationale**: Prevents data loss while maintaining security. User knows validation failed and can retry.

## Use Case 3: Periodic Verification (Cron Job)

**Goal**: Detect capability loss across all criteria and force badge loss
if projects no longer meet requirements

**Status**: Design documented here, implementation deferred to Phase 2

**Why later**: Complex retry logic, false positive handling, notification system,
extensive testing needed. Not required for immediate UX improvements.

### Design (Decision #12: Model after Existing Email Reminder Process)

**Existing System**: Email reminders sent to projects without passing badges

**Changes Needed**:
1. Stop sending reminder if project has passing OR baseline-1 badge (not just passing)
2. Use same daily limit pattern for verification process

**Frequency**: Daily with configurable limits (via environment variables)

**Scope**: All projects with badges, processed incrementally

**Process** (similar to reminder email system):

1. **Daily Batch Processing**:
   ```ruby
   # Environment variables
   MAX_VERIFICATIONS_PER_DAY = ENV.fetch('MAX_BADGE_VERIFICATIONS_PER_DAY', 100).to_i
   
   # Select projects needing verification
   # - Has a badge (badge_percentage > 0 for any level)
   # - Not verified recently (last_verified_at nil OR > 7 days ago)
   # - Verification enabled (can be disabled by admin)
   # - Limit to daily max
   
   projects_to_verify = Project.where(verification_enabled: true)
     .where('badge_percentage_0 > 0 OR badge_percentage_1 > 0 OR ....')
     .where('last_verified_at IS NULL OR last_verified_at < ?', 7.days.ago)
     .order('last_verified_at ASC NULLS FIRST')  # Oldest first
     .limit(MAX_VERIFICATIONS_PER_DAY)
   
   projects_to_verify.find_each do |project|
     VerifyBadgeJob.perform_later(project.id)
     project.update_column(:last_verified_at, Time.current)
   end
   ```

2. **For each project** (in VerifyBadgeJob):
   - Run Chief with `level: nil, changed_fields: nil` (analyze everything)
   - Compare Chief results to current values
   - Identify fields where Chief has confidence >= 4 and disagrees
   - Update `verification_failures` JSONB column

3. **Failure tracking**:
   ```ruby
   # verification_failures structure:
   {
     "floss_license_osi_status" => {
       "count" => 2,
       "first_failed_at" => "2026-02-01T10:00:00Z",
       "last_checked_at" => "2026-02-07T10:00:00Z",
       "last_explanation" => "Detected license (Proprietary) is not OSI-approved"
     }
   }
   ```
   - Increment count each time verification fails for that field
   - Reset to 0 if verification succeeds

4. **Force corrections after threshold**:
   - **Threshold**: 3 consecutive failures over 3+ days
   - **Action**: Apply high-confidence changes, send email notification
   - **Effect**: May cause badge loss if criteria no longer met

5. **Notification** (Decision #10: Use BCC for logging):
   - Email to: project owner
   - Subject: "Your [passing] badge status has changed"
   - Body: List which criteria failed, explanations, link to fix
   - BCC: trusted logging endpoint (separate from main system)
   - **Rationale**: Stores audit trail without overwhelming main logs

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

**Acceptable runtime**: With daily limits, verification spreads across ~250 days for 25,000 projects at 100/day. Projects cycle through verification every ~8 months.

### Updating Existing Email Reminder System

**Current Behavior**: Send reminder emails to projects without passing badges

**Required Update** (Decision #12):
- Stop sending if project has passing badge OR baseline-1 badge
- Rationale: Both demonstrate minimum community standards

**Code Location**: Find existing reminder email logic (likely in `lib/tasks/` or `app/jobs/`)

**Change**:
```ruby
# Before
if project.badge_percentage_0 < 100
  send_reminder_email(project)
end

# After  
if project.badge_percentage_0 < 100 && project.baseline_badge_percentage_1 < 100
  send_reminder_email(project)
end
```

**Testing**: Verify reminders stop for projects with only baseline-1 badge

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

### Implementation Priority (Decision #11: Phased Rollout with Feature Flags)

**Approach**: Gradual deployment with independent feature flags for each component

**Phase 1 (8-12 hours)**: Chief optimization with topological sort - DO NOW
- Foundation for all three use cases
- Immediate performance benefits for human editing
- Add OVERRIDABLE_OUTPUTS to all detective classes
- **Feature flag**: `CHIEF_OPTIMIZED=true/false` (default: false initially)
- **Testing**: Compare results against legacy Chief, verify identical outputs
- **Rollout**: Enable in production after 1 week in staging
- **Success metrics**: Response time improvements, no errors in logs

**Phase 2A (6-8 hours)**: Database migrations - DO NEXT
- Add `*_saved` flags to projects table with backfill logic
- Add `verification_failures`, `last_verified_at`, `verification_enabled` columns
- **Testing**: Verify backfill correctly identifies edited projects
- **Rollout**: Can deploy immediately (passive schema changes)

**Phase 2B (10-12 hours)**: Before-edit automation and UI highlighting - DO NEXT
- Controller logic for first-edit automation
- View highlighting with CSS/JavaScript (server-side classes)
- i18n translations for automation messages
- **Feature flag**: `AUTOMATION_FIRST_EDIT=true/false` (default: false)
- **Testing**: Verify highlighting works with/without JavaScript
- **Rollout**: Enable after 1 week monitoring in staging
- **Success metrics**: User feedback, no performance degradation

**Phase 3 (10-14 hours)**: Save button differentiation and error handling - DO NEXT
- "Save and Continue" vs "Save and Exit" behavior
- Flash messages for overrides (i18n)
- Chief failure handling (selective saving)
- API JSON responses with override details
- Logging for overrides
- **Feature flag**: `AUTOMATION_OVERRIDES=true/false` (default: false)
- **Testing**: Test all override scenarios, Chief failure scenarios
- **Rollout**: Enable after 2 weeks in staging (monitor override frequency)
- **Success metrics**: Override rate < 5% of saves, no user complaints

**Phase 4 (24-40 hours)**: Periodic verification cron job - DO LATER (months)
- Update reminder email logic (baseline-1 stops reminders)
- VerifyBadgeJob implementation
- Retry logic and failure tracking
- Email notifications with BCC logging
- **Feature flag**: `AUTOMATION_CRON=true/false` (default: false)
- **Testing**: 
  - Run on 100 test projects in staging (week 1-2)
  - Monitor for false positives
  - Run on 1,000 random projects in staging (week 3-4)
  - Verify daily limits work correctly
- **Rollout**: Gradual production (10/day week 1, 50/day week 2, 100/day week 3+)
- **Success metrics**: False positive rate < 1%, no email delivery issues

**Total estimated effort**: 54-86 hours (spread across 3-6 months)

**Rollback Plan**: Each feature flag can be independently disabled if issues arise

**Monitoring Dashboard**: Track per-flag metrics (usage, errors, performance)
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

## Key Decisions Summary

Based on review, the following decisions have been made:

1. **API responses**: Return 200 OK with override details in JSON body
2. **Highlighting**: Orange only when overriding non-'?' values; yellow for filling '?'
3. **Migration backfill**: Yes, set `*_saved=true` if level has non-'?' criteria filled
4. **Accessibility**: Use color + icons + ARIA labels (server-side)
5. **i18n**: Implement from start for HTML flash messages; English for JSON
6. **Error handling**: Save non-overridable fields, block overridable fields on Chief failure, return to edit with flash
7. **Monitoring**: Simple Rails.logger entries for overrides (project#, user, fields)
8. **Skip automation**: Not needed now
9. **Confidence display**: Skip for now
10. **Audit log**: Defer until cron job; use BCC'd emails to separate system for logging
11. **Phased rollout**: Yes, use feature flags for gradual deployment
12. **Cron verification**: Model after existing email reminder process with daily limits

**Key architectural change from #6**: Detectives must declare which outputs can override (new OVERRIDABLE_OUTPUTS list), so we can handle Chief failures safely.

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
