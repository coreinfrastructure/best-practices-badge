# Pre-merge evaluation: login-session-hardening vs main

Date: 2026-09-10 (session). Scope: full diff of branch
`login-session-hardening` against `main`, all 17 steps of
`docs/login-session-implementation.md` plus steps 18-20 of
`docs/login-session-18.md`. All CI checks (`rake`, rubocop,
rails_best_practices, whitespace_check) pass on this branch.

**Bottom line: do not merge yet.** Two confirmed bugs are everyday-usage
issues, not edge cases: a logout crash and a cross-user data leak on
shared browsers. Both slipped past CI because the specific runtime
condition each needs (a stale timestamp; two different logins in one
session) is never combined in the existing tests.

Method: a full branch-vs-main code review was run via the `code-review`
skill (forked background agent, 8 finder angles, ~126k tokens, ~31
minutes). Its 10 findings were then independently re-derived by reading
the actual source for the top items rather than taken on trust; each
finding below states which.

## Findings, most severe first

### 1. Logout crashes (500) if the session was idle over an hour

**File:** `app/helpers/sessions_helper.rb:246` (log_out) and
`app/controllers/application_controller.rb:669-686`
(update_session_timestamp).
**Verification: independently confirmed by reading the code.**

`log_out` does `@login_session&.destroy` but never sets the ivar to
`nil` afterward:

```ruby
def log_out
  forget(current_user)
  @login_session&.destroy
  reset_session
  @current_user = nil
end
```

The `after_action :update_session_timestamp` runs after every
controller action, including the one that just called `log_out`:

```ruby
def update_session_timestamp
  return unless @login_session

  old = @session_timestamp < SessionsHelper::RESET_SESSION_TIMER.ago.utc
  return unless old

  @login_session.update_column(:last_used_at, Time.now.utc)
end
```

`@login_session` is still truthy (a destroyed AR object is not `nil`),
so this proceeds to call `update_column` on a destroyed record.
ActiveRecord raises `ActiveRecordError` ("cannot update a destroyed
record") in that case; there is no `rescue_from` for it anywhere in
`ApplicationController`.

`RESET_SESSION_TIMER = 1.hour` (`sessions_helper.rb:13`), so `old` is
true whenever the session's `last_used_at` is more than an hour old at
the moment of the logout request, an ordinary occurrence: log in, work
for a while, step away for over an hour, come back and click logout.

**Same path is hit by self-account-deletion**:
`UsersController#destroy` calls `log_out if id_to_delete ==
current_user.id` before deleting the user, so an idle-then-delete-account
flow crashes the same way.

**Why CI missed it:** the only existing logout test
(`test/controllers/sessions_controller_test.rb:268`, "logout deletes
only the current LoginSession row") logs in and logs out within the
same test, with no time travel. `last_used_at` is therefore always
fresh (milliseconds old), so `old` is always false and the crashing
line is never reached. 100% statement coverage does not imply this
state combination (old timestamp + already-destroyed record in the
same request) was ever exercised.

**Suggested fix:** set `@login_session = nil` right after `destroy` in
`log_out` (matching the existing `@current_user = nil` line right
below it).

### 2. Stashed form data can leak to a different logged-in user on a shared browser

**File:** `app/controllers/pending_resubmissions_controller.rb:24-28`,
`app/helpers/sessions_helper.rb:26`
(`SESSION_KEYS_SURVIVING_RESET`), `db/schema.rb:48-58`
(`pending_resubmissions` table).
**Verification: independently confirmed by reading the code and schema.**

`SESSION_KEYS_SURVIVING_RESET = %i[forwarding_url
pending_resubmission_token]` deliberately preserves the pending-resubmission
token across `counter_fixation`'s session reset on login, so that if the
*same* person who stashed an edit later logs in, they land on their own
stashed data. But `pending_resubmissions` has no `user_id` column at
all:

```
create_table "pending_resubmissions" ... do |t|
  t.datetime "created_at", null: false
  t.string "hashed_random_id", null: false, ...
  t.text "params_json", null: false, ...
  t.string "resubmit_method", null: false, ...
  t.string "resubmit_path", null: false, ...
  t.boolean "sensitive_fields_dropped", default: false, null: false
  t.datetime "updated_at", null: false
  ...
end
```

And `PendingResubmissionsController#show` looks the row up purely by
the session-held token, with no identity check:

```ruby
def show
  pending_token = session.delete(:pending_resubmission_token)
  pending = PendingResubmission.find_by_token(pending_token)
  return redirect_expired unless pending

  pending.destroy
  ...
end
```

**Failure scenario:** on a shared or kiosk browser, person A (not
logged in) edits a project, hits a validation error, and
`ApplicationController#stash_pending_resubmission`
(`application_controller.rb:801-814`) stashes it, setting
`session[:pending_resubmission_token]`. A walks away without logging
in. Person B later logs into *their own* account on that same browser.
Because the token survives the login reset, `redirect_after_login`
(`sessions_controller.rb:139`, checked before the normal
`return_to_path`) sends B straight to `/pending_resubmissions`, which
shows A's stashed `params_json`, `resubmit_path`, and `resubmit_method`
under B's session, with no ownership check anywhere in the chain.

**Context:** step 18 (this same branch) already closed the
"guessable primary key" version of this problem, replacing a
sequential id with an HMAC-verified random token specifically so a
different *browser* couldn't forge or enumerate another session's
stash. That fix assumed session-scoping was sufficient isolation; it
doesn't hold when one session hosts two different people in sequence.

**Suggested fix:** add a `user_id` (nullable, since the stash can be
created while logged out) to `pending_resubmissions`, set it at stash
time from `current_user&.id`, and in `show`, if the row has a
non-nil `user_id` that doesn't match `current_user&.id`, treat it as
expired rather than showing it.

### 3. Remember-cookie replay can insert unbounded LoginSession rows

**File:** `app/controllers/application_controller.rb:748-762`
(`try_remember_token_login`), `app/helpers/sessions_helper.rb:61`
(`log_in`).
**Verification: independently confirmed by reading the code.**

```ruby
def try_remember_token_login
  cookie_user_id = cookies.signed[:user_id]
  return unless cookie_user_id

  user = User.find_by(id: cookie_user_id)
  return unless user&.authenticated?(:remember, cookies[:remember_token])
  return if user.provider == 'github'

  log_in(user) # now the single entry point for "establish a session"
  ...
end
```

`log_in` now performs a real `LoginSession.create_for(...)` INSERT
every time it runs (this is new: the comment at the call site itself
calls it "now the single entry point," implying the pre-branch design
did not hit the database here). `try_remember_token_login` runs
unconditionally, from a `before_action`, whenever no valid
`login_session_id` is found but a valid remember-me cookie is
presented.

**Failure scenario:** an ordinary browser that stores and resends all
cookies only triggers this once (after the session cookie expires or
the browser restarts). But a bot, script, or misconfigured client that
resends the long-lived signed `remember_token`/`user_id` cookies on
every request while discarding `Set-Cookie` (so it never carries a
session cookie back) re-triggers this on *every* request, each one a
fresh DB insert. This is bounded only by the once-daily purge task
mentioned in project memory, on a site AGENTS.md itself describes as
"extremely busy and always under attack."

**Suggested fix:** worth discussing rather than a quick patch: options
include rate-limiting this path specifically, or making repeated
remember-token logins within a short window reuse an existing
still-valid `LoginSession` row instead of always creating a new one.

## Findings, confirmed but lower severity

### 4. Stashed submission is destroyed before the user has acted on it

**File:** `app/controllers/pending_resubmissions_controller.rb:28`.
**Verification: confirmed directly (visible in the same code read for #2).**

```ruby
pending.destroy # single-use
```

runs immediately after the row is found, before the "Resume saving
your changes" page has necessarily reached, or been used by, the
browser. A dropped connection, closed tab, or back-button press before
clicking Resume loses the stashed edit permanently, with no error
explaining why. Destroying it on actual resubmission instead (or at
least deferring destruction) would be more robust.

### 5. Nickname-change flash fires even if the DB save fails

**File:** `app/controllers/sessions_controller.rb:204-219`
(`update_github_nickname`).
**Verification: confirmed by reading the code.**

```ruby
def update_github_nickname(user, new_nickname)
  new_nickname = new_nickname&.slice(0, User::MAX_NICKNAME_LENGTH_GITHUB)
  return if user.nickname == new_nickname

  old_nickname = user.nickname
  user.update(nickname: new_nickname)  # return value discarded
  return if old_nickname.blank?

  flash[:info] = t('sessions.github_nickname_changed', ...)
end
```

If `user.update` fails validation, the flash still claims the nickname
changed, but `current_user_is_github_owner?`
(`sessions_helper.rb:214-217`) keeps comparing against the unsaved
(old) DB value on every later request: a silent mismatch between what
the user was told and what's actually authorized. Suggested fix: check
the return value of `update` (or use `update!` with a rescue) before
setting the flash.

### 6. Remember-token relogin skips the session-fixation reset

**File:** `app/helpers/sessions_helper.rb:53-76` (`log_in`), contrast
with `sessions_controller.rb:152` (`counter_fixation`).
**Verification: confirmed by reading the code; severity assessed and
narrowed below.**

The explicit password/OAuth login path calls `counter_fixation` (which
calls `reset_session`) before authenticating, specifically to defend
against session fixation. `log_in`, when reached via
`try_remember_token_login`, never calls `reset_session`. Any session
state set before authentication survives into the newly-authenticated
session on that path.

**Caveat worth stating plainly:** `session[:login_session_id]` itself
is always freshly minted by `log_in` regardless (a new
`LoginSession.create_for` row and a new raw session id every call), and
that identifier, not the raw Rack session envelope, is what this
branch's whole design (steps 1-17) treats as the actual
authorization-relevant credential. So the practical exposure here is
narrower than classic session fixation against this app specifically.
The inconsistency between the two login entry points is still real and
worth closing deliberately (call `reset_session` in `log_in` itself,
or explicitly in `try_remember_token_login`) rather than leaving it as
an implicit, undocumented gap.

### 7. New HMAC key falls back to the public test value if unset

**File:** `app/models/pending_resubmission.rb:22`,
`app/lib/hex_key_management.rb`.
**Verification: confirmed by reading the code.**

```ruby
def hex_key_for(env_var:, test_value:, env_test: Rails.env.test?)
  return test_value if env_test

  ENV[env_var] || test_value
end
```

No fail-fast check at boot if `env_var` is unset outside test mode:
production would silently sign/verify with the value committed in the
public repo instead of failing loudly. This is a **pre-existing
pattern**, not new to this branch: `SESSION_ID_HMAC_KEY` and
`EMAIL_ENCRYPTION_KEY` already carry the identical risk. Step 18
extends it to a third key (`PENDING_RESUBMISSION_HMAC_KEY`) by reusing
the same helper, consistent with the existing design rather than a
novel regression. Per this session's own record, the env var has
already been provisioned on both staging and production, so live risk
today is latent, not active. Still worth a boot-time assertion someday
across all three keys, not just the new one.

NOTE: RISK ACCEPTED, DO NOT CHANGE. The risk is not active, and the risk
is low anyway. Other items are more important.

### 8. HMAC key re-derived from ENV on every request (performance, not correctness)

**File:** `app/models/login_session.rb:39` (`session_id_hmac_key`), and
the identical pattern in `PendingResubmission#hmac_key`.
**Verification: not independently re-derived; taken from the review
agent's report, plausible on inspection of the method shape.**

Re-reads `ENV` and re-runs `pack('H*')` on every call rather than
memoizing once, unlike `User`'s analogous blind-index key (evaluated
once at class-load time). `LoginSession.find_by_session_id` runs from
the `before_action` on every authenticated request, so this is on the
hottest path in the app.

### 9. HMAC-key-derivation pattern duplicated three times

**File:** `app/models/login_session.rb:18` and the same shape in
`app/models/user.rb` and `app/models/pending_resubmission.rb`.
**Verification: not independently re-derived; consistent with what was
directly observed while implementing step 18 earlier this session
(the pattern was deliberately copied from `LoginSession` at that
time).**

The `DIGITS_OF_*_HMAC_KEY` / `TEST_*_HMAC_KEY` /
`self.*_hmac_key_hex` / `self.*_hmac_key` / `self.digest` shape is
written nearly verbatim in three models. AGENTS.md: "If the same
function or method is written more than once, it's wrong." A future
fix to the hex-to-bytes conversion, or a fourth HMAC-keyed model,
means editing (or copy-pasting) the same logic multiple times.

### 10. Non-numeric rake argument crashes with a raw backtrace

**File:** `lib/tasks/login_sessions.rake:16`.
**Verification: confirmed by reading the code.**

```ruby
if args.user_id.blank?
  puts 'Error: user id is required'
  puts 'Usage: rake login_sessions:revoke[123]'
  exit 1
end

user = User.find(Integer(args.user_id, 10)) # raises if not found
```

The blank-argument case gets a friendly message; a non-numeric one
(e.g. a pasted email instead of a numeric id, a plausible typo during
an incident-response scramble) raises an uncaught `ArgumentError` with
a full Ruby backtrace. Minor, but this task exists specifically for
incident response, the worst possible moment for a confusing crash.

## What was not re-derived from scratch

Findings 8 and 9 are taken from the review agent's report without an
independent second reading of every call site; both are consistent
with code seen directly elsewhere in this session and are low-stakes
(performance and duplication, not correctness or security), so they
were not re-verified line by line the way 1-7 and 10 were.

## Recommendation

Fix #1 and #2 before merging; both are ordinary-usage bugs, not edge
cases, and #2 is a real cross-user data exposure. #3 is worth a
deliberate decision (accept the current bound via the daily purge, or
add a targeted mitigation) rather than silence. #4, #5, #6, #10 are
worth fixing but are not blockers. #7, #8, #9 are pre-existing-pattern
or code-quality items, safe to defer or fix opportunistically.

## Tooling task: system tests can't run in Claude's sandbox

Not an app bug: this is about the dev/AI-assistant environment, added
here only so it gets weighed against the findings above rather than
tracked separately.

**Problem:** `rails test:system` (and `rake test:optimized`, which
includes it) cannot run inside the sandboxed shell Claude Code uses on
this machine. Every system test fails with:

```text
Selenium::WebDriver::Error::WebDriverError: unable to connect to
/snap/bin/chromium.chromedriver 127.0.0.1:9515: Connection refused
```

**Root cause, confirmed by running `/snap/bin/chromium` directly:**

```text
internal error, please report: running "chromium" failed: timeout
waiting for snap system profiles to get updated
```

plus permission-denied reads on `/snap/snapd/current/usr/lib/snapd/info`
and `/etc/fstab`. Snap-packaged Chromium needs to talk to the `snapd`
daemon to refresh its AppArmor profile before it will even open the
chromedriver port, and that path is blocked in the sandbox. This isn't
a general network or filesystem block (plain loopback socket binding
and reads of `/etc/passwd` both work fine); it's specific to snap's own
confinement model, and `docs/INSTALL.md` already documents the snap as
the only supported chromedriver source on arm64 Linux, since Google
ships no official arm64 chromedriver.

**Validated fix:** downloaded Playwright's own Chromium build (a plain
ARM64 ELF binary, not a snap) into a project-local directory via
`PLAYWRIGHT_BROWSERS_PATH`, and confirmed with a standalone Node script
that Playwright's own launcher starts it, loads a real page, and reads
the title back successfully, entirely inside the sandbox. (A first
attempt launching that same binary by hand, guessing Selenium-style
Chrome flags, crashed in Chromium's crashpad self-monitor subprocess;
Playwright's launcher passes whatever flag avoids that, so the binary
and the sandbox were never the problem.) This means switching
Capybara's system-test driver from Selenium+chromedriver to Playwright
would let system tests run directly in this sandbox, with nothing
outside the project directory touched and no `sudo` needed.

**Proposed implementation** (not yet started):

1. Add `capybara-playwright-driver` (real, maintained gem by
   YusukeIwaki, wraps `playwright-ruby-client`) to the `Gemfile`'s test
   group. Needs the user's own dependency check before it goes in, per
   AGENTS.md's "don't add dependencies that may be malicious or
   hallucinated."
2. Rewrite the driver-registration block in
   `test/application_system_test_case.rb` to add a `:playwright` driver
   option, pointed at a project-local, gitignored `PLAYWRIGHT_BROWSERS_PATH`.
3. Keep the existing Selenium/snap path working as-is for any
   environment (CI, a developer's own machine) that isn't running
   inside this kind of sandbox; gate the new path the same deliberate
   way the current arm64-detection block already gates the snap
   fallback, rather than replacing one hardcoded assumption with
   another.
4. Update `docs/INSTALL.md` with the new setup step.

**Why it's worth doing:** without this, every "run the tests" step in
this branch's own workflow (see project memory) needs the user to run
`rails test:system` themselves and report back; Claude can currently
verify only the non-system suite directly. Fixing this closes that
gap for future work, not just this branch.
