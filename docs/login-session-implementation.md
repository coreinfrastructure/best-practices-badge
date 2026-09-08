# Hardening Login Sessions: Implementation Plan

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

**Status: implementation plan, not yet built.** This plan implements the
design in [`docs/login-session.md`](login-session.md) ("the design doc").
That document is the reference for *why*; this one is the sequence of
concrete changes, file by file, for *how*, and assumes the reader has it
open. Section references below (design §N) point back to it.

This plan also folds in two small naming corrections made while writing
it, now already applied to the design doc: the rake task is
`login_sessions:revoke[user_id]` (was `sessions:revoke`, inconsistent with
the settled `login_sessions` table/model name), and the cookie key holding
the raw session id must not be named `:session_id` (see step 5 below).

## 0. Sequencing principle

Steps 1 to 4 are purely additive (new table, new model, no behavior
change yet) and each can deploy on its own. **Steps 5 to 8 cannot**:
`log_in` (step 5) stops writing `session[:user_id]`, and
`setup_authentication_state` (step 6) is what reads the replacement
instead; deploying step 5 without step 6 breaks login on the very next
request, since nothing yet reads `session[:login_session_id]`. Steps 5
to 8 are separate commits for reviewability, but must land as one
atomic deploy. Step 9 (`log_out`) degrades gracefully if deployed early
(`@login_session` is simply `nil` until the cutover lands, so it's a
no-op addition), but there's no reason to split it out. Steps 10 onward
only add behavior on top of a completed cutover and can each deploy
independently again.

## 1. Secrets: `SESSION_ID_HMAC_KEY`

Design §5 and §8. Mirror the existing pattern in `app/models/user.rb`
(`DIGITS_OF_EMAIL_BLIND_INDEX_KEY`, `TEST_EMAIL_BLIND_INDEX_KEY`,
`self.email_blind_index_key_hex`), but place it on the new `LoginSession`
model (step 3), not on `User`: this key is about sessions, not users, and
`User` is already a large class (`# rubocop:disable Metrics/ClassLength`
at the top of `app/models/user.rb`).

**Code-size opportunity, worth taking now rather than later**: this
would be the *third* near-identical copy of "a hex-encoded secret key
with a test-environment fallback" (`email_encryption_key_hex` and
`email_blind_index_key_hex` are the first two, both in `User`). Three
independent copies of the same four-line pattern is exactly what
AGENTS.md's "if the same thing is written more than once, it's wrong"
is about. Extract a small shared helper, e.g. a `HexKeyManagement`
module with one method:

```ruby
module HexKeyManagement
  def hex_key_for(env_var:, test_value:, env_test: Rails.env.test?)
    return test_value if env_test

    ENV[env_var] || test_value
  end
end
```

Have `LoginSession` (`extend HexKeyManagement`) use it for the new key.
Leave `User`'s two existing methods untouched for this project (they're
tested, working code, and migrating them is a separate, optional cleanup
with its own risk/review, not something this project needs to do); the
new key alone still gets built without a third hand-copied instance of
the pattern, and the shared method is there if that follow-up cleanup
ever happens.

Also: keep all three session-timing constants together. `SESSION_TTL`
and `RESET_SESSION_TIMER` already live in `SessionsHelper`; put the new
`ABSOLUTE_SESSION_AGE` there too (not on `LoginSession`, despite step 3
below sketching it that way first-draft), so session policy has one
home instead of two.

- `LoginSession::DIGITS_OF_SESSION_ID_HMAC_KEY = 256 / 8 * 2`
- `LoginSession::TEST_SESSION_ID_HMAC_KEY = '3' * DIGITS_OF_SESSION_ID_HMAC_KEY`
  (`'1'` and `'2'` are already used by the two existing email keys; pick an
  unused digit so a copy-paste error is easy to spot)
- `LoginSession.session_id_hmac_key_hex(env_test: Rails.env.test?)`, same
  test/production split as the two existing methods
- **A real bug to avoid, not just style**: step 3's `digest` method calls
  `session_id_hmac_key` (no `_hex` suffix), but only
  `session_id_hmac_key_hex` is defined above. The existing pattern always
  converts the hex string to raw bytes before using it as key material
  (`[email_blind_index_key_hex].pack('H*')`, passed as `blind_index`'s
  `key:`); that conversion step is what's missing here. Add it
  explicitly, e.g. `LoginSession.session_id_hmac_key` returning
  `[session_id_hmac_key_hex].pack('H*')`, and have `digest` call *that*.
  Skipping this wouldn't just fail loudly (`NoMethodError`); a careless
  fix that passes the hex *string* straight to `OpenSSL::HMAC` instead of
  the unpacked bytes would run without error while quietly using the
  wrong key material, so name this precisely rather than leaving it to
  be improvised during implementation.
- Document `SESSION_ID_HMAC_KEY` alongside `EMAIL_ENCRYPTION_KEY` and
  `EMAIL_BLIND_INDEX_KEY` wherever those are documented for deployment
  (check `.env.example` or equivalent, and `docs/secrets-policy.md`,
  design §8)

## 2. Migration: `login_sessions` table

Design §3, and §9's now-resolved column-naming question.

```ruby
create_table :login_sessions do |t|
  t.string :session_id_digest, null: false
  t.bigint :user_id, null: false
  t.datetime :last_used_at, null: false
  t.string :ip_address
  t.text :user_agent
  t.timestamps
end
add_index :login_sessions, :session_id_digest, unique: true
add_index :login_sessions, :user_id
add_foreign_key :login_sessions, :users
```

Notes tied to earlier decisions:

- `session_id_digest` is `t.string` (not `bytea`), per design §3's
  resolved digest-column-type decision.
- `user_agent` is `t.text`, not the default `t.string`
  (`varchar(255)`): real `User-Agent` headers can exceed 255 characters,
  and design §3 commits to storing the full string, not a truncated one.
- `ip_address` is `t.string`, not PostgreSQL's native `inet` type, for
  the same portable-standard-SQL reasoning already applied to the digest
  column in design §3.
- Use `t.timestamps` for `created_at`/`updated_at` (Rails convention,
  needed anyway); `created_at` is the column design §3 already uses for
  the absolute session-age cap. `last_used_at` is a separate column, not
  `updated_at`, because `updated_at` would also change on unrelated future
  edits to a row, which `last_used_at`'s "when was this session last
  active" meaning must not.
- `add_foreign_key` a real DB-level foreign key, matching how `projects`
  and other tables reference `users` in this schema (check
  `db/schema.rb` for the existing convention before writing the
  migration, to match `on_delete` behavior if any is set there).

## 3. Model: `LoginSession`

New file `app/models/login_session.rb`.

```ruby
# frozen_string_literal: true
class LoginSession < ApplicationRecord
  belongs_to :user

  # The raw session id, set only right after #create_for and never
  # persisted (there is no session_id column, only session_id_digest).
  # Exists so a caller that just created a row (log_in,
  # try_remember_token_login) gets both the row and the cookie value from
  # one call, instead of creating a row and then querying it back.
  attr_reader :raw_session_id

  def self.session_id_hmac_key
    [session_id_hmac_key_hex].pack('H*') # hex string -> raw key bytes,
    # matching how EMAIL_BLIND_INDEX_KEY is unpacked in app/models/user.rb
  end
  private_class_method :session_id_hmac_key

  def self.digest(session_id)
    OpenSSL::HMAC.hexdigest('SHA256', session_id_hmac_key, session_id)
  end

  def self.create_for(user, ip_address:, user_agent:)
    session_id = User.new_token # design doc section 5: reuse, don't reinvent
    login_session = create!(
      user: user,
      session_id_digest: digest(session_id),
      last_used_at: Time.now.utc,
      ip_address: ip_address,
      user_agent: user_agent
    )
    login_session.instance_variable_set(:@raw_session_id, session_id)
    login_session
  end

  def self.find_by_session_id(session_id)
    return nil if session_id.blank?

    find_by(session_id_digest: digest(session_id))
  end

  def idle_expired?
    last_used_at < SessionsHelper::SESSION_TTL.ago.utc
  end

  def absolutely_expired?
    created_at < SessionsHelper::ABSOLUTE_SESSION_AGE.ago.utc
  end
end
```

`create_for` now returns the `LoginSession` row itself (not just the raw
id), with the raw id available via `.raw_session_id` for the one caller
(`log_in`, step 5) that needs to put it in the cookie. This also means
`log_in` can set `@login_session` directly instead of leaving it to be
picked up later by `setup_authentication_state`'s lookup, which matters
for `try_remember_token_login` (step 8): calling `log_in(user)` there
now hands back the row it just created, with no second query to re-find
what was already just made.

(Illustrative, not final: key management per step 1 needs wiring into
`digest`/`session_id_hmac_key`; exact method names are this plan's
suggestion, not a requirement.) Add `has_many :login_sessions,
dependent: :destroy` to `User` (`app/models/user.rb`), matching the
existing `has_many :projects, dependent: :destroy` /
`has_many :additional_rights, dependent: :destroy` pattern there, and the
same pattern `UsersController#destroy`'s comment already documents
("auto-removes associated ApplicationRecords via the has_many
association", `app/controllers/users_controller.rb:354`). Without this,
deleting a user would leave orphaned `login_sessions` rows.

## 4. Cookie key naming: not `:session_id`

`ApplicationController::SESSION_BOOKKEEPING_KEYS` (application_controller.rb:45)
is already `%w[session_id flash]`, Rack's own internal session-id
bookkeeping key, unrelated to our new value. **The cookie key for our raw
session id must be named something else**, e.g. `:login_session_id`.

The failure mode is not what it might first look like: `logged_in?` is
checked before `session_has_user_content?` in `drop_unneeded_session_cookie`
(application_controller.rb:699-704), so a genuinely logged-in user's
cookie never reaches the bookkeeping-keys check at all, named `:session_id`
or not. The real failure is the opposite case: a session that is *not*
logged in (`@session_user_id` nil) but still carries a stale or
just-revoked `login_session_id`, for example a cookie the admin
(step 11) or the daily cleanup (step 13) invalidated server-side while
the browser still holds it. If that key were named `:session_id` and
therefore counted as bookkeeping, `session_has_user_content?` would see
nothing but bookkeeping keys, and `drop_unneeded_session_cookie` would
delete that cookie. Deleting it is harmless on its own (the row it
pointed to is already gone), but it is exactly the kind of "looks
unrelated, quietly changes what a name refers to" mistake worth naming
precisely rather than describing by a scenario that cannot occur. Use
`:login_session_id` throughout the steps below.

This is a naming collision only; a related but separate question, reusing
Rack's own bookkeeping session id *as our token* rather than minting our
own, is considered and rejected in design §6.6, for reasons that also
explain why the two must not share a key even by accident.

**Document the distinction in code, not only here**, since the two names
are easy to confuse later and the confusion would be silent (no error, just
a subtly wrong assumption about which "session id" a piece of code is
looking at):

- At `SESSION_BOOKKEEPING_KEYS`'s definition
  (application_controller.rb:45): a comment noting that `'session_id'`
  there is Rack's own internal bookkeeping key, unrelated to
  `LoginSession`/`session[:login_session_id]`, and linking to design
  §6.6 for why they're deliberately different.
- At every place `session[:login_session_id]` is first introduced in
  each method touched by this plan (`log_in`, step 5;
  `setup_authentication_state`, step 6; `try_remember_token_login`,
  step 8): a short comment that this is *our* random session id, not
  Rack's.
- On `LoginSession` itself (step 3): a class-level comment stating
  plainly that this model has nothing to do with Rack's session
  mechanism, it is our own server-side record of one login.

## 5. Cutover: `SessionsHelper#log_in`

Design §3's "on login" bullet and §9's `try_remember_token_login`
recommendation (reuse `log_in` directly).

Current (`app/helpers/sessions_helper.rb:48`):

```ruby
def log_in(user)
  session[:user_id] = user.id
  session[:time_last_used] = Time.now.utc
  I18n.locale = user.preferred_locale.to_sym
  return unless session[:forwarding_url]

  session[:forwarding_url] =
    safe_localized_internal_url(session[:forwarding_url], I18n.locale)
end
```

New:

```ruby
def log_in(user)
  # session[:login_session_id] is OUR random session id (LoginSession),
  # not Rack's own bookkeeping session_id; see design doc section 6.6.
  @login_session = LoginSession.create_for(
    user, ip_address: ClientIp.extract(request), user_agent: request.user_agent
  )
  session[:login_session_id] = @login_session.raw_session_id
  I18n.locale = user.preferred_locale.to_sym
  return unless session[:forwarding_url]

  session[:forwarding_url] =
    safe_localized_internal_url(session[:forwarding_url], I18n.locale)
end
```

`session[:user_id]` and `session[:time_last_used]` are gone from the
cookie entirely (design §3). Setting `@login_session` here, not only in
`setup_authentication_state`, is what lets `try_remember_token_login`
(step 8) avoid a redundant re-lookup, and keeps `@login_session`
reliably set for the rest of the request on the request where a login
(or step 10's revoke-and-relogin) actually happens.

## 6. Cutover: `ApplicationController#setup_authentication_state`

Design §3's `setup_authentication_state` bullet: one row lookup replaces
the direct cookie read, and the same row supplies `last_used_at` for the
idle check at no extra query cost.

Current (`app/controllers/application_controller.rb:624`):

```ruby
def setup_authentication_state
  return if Rails.application.config.deny_login

  user_id = session[:user_id]
  timestamp = session[:time_last_used]

  if user_id && (!timestamp || timestamp < SessionsHelper::SESSION_TTL.ago.utc)
    reset_session
    user_id = nil
    timestamp = nil
  end

  user_id, timestamp = try_remember_token_login if user_id.nil?

  @session_user_id = user_id
  @session_timestamp = timestamp
  @session_user_token = session[:user_token]
  @session_github_name = session[:github_name]
end
```

New (shape, not final Ruby):

```ruby
def setup_authentication_state
  return if Rails.application.config.deny_login

  # Forgery-proof evidence this browser once had *some* session, current
  # format or the pre-rollout one, used only to gate step 15's
  # preserve-and-resubmit flow against zero-credential anonymous abuse.
  # Never used for authentication: presence only, value never trusted.
  # Must be read here, before anything below might reset_session.
  @had_prior_session = session[:login_session_id].present? || session[:user_id].present?

  login_session = LoginSession.find_by_session_id(session[:login_session_id])

  if login_session && (login_session.idle_expired? || login_session.absolutely_expired?)
    login_session.destroy
    login_session = nil
    reset_session
  end

  login_session = try_remember_token_login if login_session.nil?

  @session_user_id = login_session&.user_id
  @session_timestamp = login_session&.last_used_at
  # Redundant, not wrong, when login_session came from
  # try_remember_token_login: log_in (step 5) already set @login_session.
  # Still needed for the ordinary path above, where a valid
  # login_session_id was found directly and log_in never ran this request.
  @login_session = login_session
  @session_user_token = session[:user_token]
  @session_github_name = session[:github_name]
end
```

Both the idle check (§3's absolute-cap bullet says "Check `created_at`
... in `setup_authentication_state`") and the pre-existing idle check now
read off the one row already fetched. `try_remember_token_login`'s
return shape changes here too; see step 8.

**Why `@had_prior_session` checks both keys, not just
`session[:login_session_id]`**: found while designing step 15's defense
against zero-credential anonymous abuse (see that step for the full
attack this closes). Checking `session[:login_session_id]` alone would
be structurally correct after this project is fully rolled out, but
wrong during the rollout itself: every legitimately logged-in user's
cookie at deploy time carries the *old* `session[:user_id]` key, never
`login_session_id` (which doesn't exist until this project ships). A
check that only looked at the new key would treat that entire
population, the single highest-volume case step 15 exists for, as
"never had a session," silently withholding exactly the protection just
built for them. Checking presence of *either* key, and trusting neither
key's value for anything, covers both eras without reopening any
authentication path through the legacy key.

Expose it via a small method in `SessionsHelper`, next to `logged_in?`
(sessions_helper.rb:82) and matching its exact shape, so the two gate
methods in step 15 read as plainly as `logged_in?` itself, and so it's
independently stubbable in a test rather than only reachable by poking
at a bare instance variable:

```ruby
def had_prior_session?
  @had_prior_session
end
```

## 7. Cutover: `ApplicationController#update_session_timestamp`

Design §3's `last_used_at` bullet and §7's write-load discussion: keep
the exact existing throttle, retarget the write.

Current (application_controller.rb:658):

```ruby
def update_session_timestamp
  return unless @session_user_id

  old = !@session_timestamp ||
        @session_timestamp < SessionsHelper::RESET_SESSION_TIMER.ago.utc
  return unless old

  session[:time_last_used] = Time.now.utc
  @session_timestamp = session[:time_last_used]
end
```

New:

```ruby
def update_session_timestamp
  return unless @login_session

  old = @session_timestamp < SessionsHelper::RESET_SESSION_TIMER.ago.utc
  return unless old

  @login_session.update_column(:last_used_at, Time.now.utc) # no callbacks needed
  @session_timestamp = @login_session.last_used_at
end
```

`update_column` (not `update!`) deliberately skips validations/callbacks
for this single-column, non-user-facing timestamp bump, the same
reasoning `SessionsController#successful_login` already uses
`update_columns` for `last_login_at`
(app/controllers/sessions_controller.rb:131).

The original's `!@session_timestamp ||` guard is dropped deliberately,
not by oversight: `last_used_at` is `null: false` (step 2), so a found
`LoginSession` can never yield a nil `@session_timestamp`, unlike the old
cookie-only design where a nil timestamp was (defensively) possible.
Worth a code comment saying so, so a future reader doesn't wonder if
restoring that guard is a bug fix.

## 8. Cutover: `ApplicationController#try_remember_token_login`

Design §9's resolved recommendation: reuse `log_in` directly, since the
"downside" originally listed for it didn't survive reading the code (the
locale switch it worried about is already duplicated in both places
today).

Current (application_controller.rb:729):

```ruby
def try_remember_token_login
  cookie_user_id = cookies.signed[:user_id]
  return [nil, nil] unless cookie_user_id

  user = User.find_by(id: cookie_user_id)
  return [nil, nil] unless user&.authenticated?(:remember, cookies[:remember_token])
  return [nil, nil] if user.provider == 'github'

  now = Time.now.utc
  session[:user_id] = user.id
  session[:time_last_used] = now
  I18n.locale = user.preferred_locale.to_sym
  @current_user = user
  [user.id, now]
end
```

New (shape):

```ruby
def try_remember_token_login
  cookie_user_id = cookies.signed[:user_id]
  return nil unless cookie_user_id

  user = User.find_by(id: cookie_user_id)
  return nil unless user&.authenticated?(:remember, cookies[:remember_token])
  return nil if user.provider == 'github'

  log_in(user) # now the single entry point for "establish a session"
  @current_user = user
  @login_session # set by log_in itself (step 5); no re-lookup needed
end
```

Return shape changed (a `LoginSession` or `nil`, not a `[user_id,
timestamp]` pair) to match step 6's rewritten caller. With step 5's
`create_for` change, `log_in` already leaves `@login_session` set, so
this returns it directly rather than re-querying for the row it just
created.

One claim from design §9 needs correcting, not just carrying forward:
that section says reusing `log_in` "likely fixes" a latent gap where
`try_remember_token_login` skips `log_in`'s trailing `forwarding_url`
relocalization. Re-checking the actual call site weakens that claim:
`setup_authentication_state`'s idle-expiry branch (step 6) calls
`reset_session` immediately before falling through to
`try_remember_token_login`, and `reset_session` wipes
`session[:forwarding_url]` (this app's own `counter_fixation` has to
explicitly save and restore it around `reset_session` for exactly this
reason, application_controller.rb comment near `counter_fixation`). So
in the most common path into `try_remember_token_login`, any
`forwarding_url` is typically already gone before `log_in` runs; the fix
this reuse "likely" provides may rarely, if ever, be observable. The DRY
argument for reusing `log_in` (removing an already-existing duplication
of `session[:user_id]`/`session[:time_last_used]`/`I18n.locale` logic)
stands on its own and doesn't need this side-claim to justify the
change; write the test named below to see what actually happens rather
than assume either way.

Write a test that specifically exercises "idle timeout lapses,
remember-me cookie present, silently restores": confirm the session is
correctly re-established, and separately confirm (don't assume) what
happens to `forwarding_url` in that path given the `reset_session`
timing above.

**Worth naming, though it's a minor cost, not a new attacker
capability**: unlike today, a successful silent remember-me restoration
now performs a `LoginSession.create_for` write, not just a cookie
write, and it can be triggered by whatever request happens to come next
from a browser holding a valid remember-me cookie, not only
`POST /login`. Reaching this path at all still requires already
possessing a working, previously-issued `remember_token`/`user_id`
pair, a bcrypt-verified secret that can only be replayed from a prior
theft, never manufactured or guessed; an attacker without one gets
nothing extra from this path. Design §7 covers this in full (including
the precise throttles that bound even this narrow case,
`req/ip`/`nonbadge_req/ip` in `config/initializers/rack_attack.rb`, not
the `/login`-specific one); nothing further is needed here beyond
implementing per design §3 and §7 as written.

## 9. Cutover: `SessionsHelper#log_out`

Design §3's "ordinary logout" bullet: only the current row, never all of
a user's rows.

Current (sessions_helper.rb:195):

```ruby
def log_out
  forget(current_user)
  reset_session
  @current_user = nil
end
```

New:

```ruby
def log_out
  forget(current_user)
  @login_session&.destroy
  reset_session
  @current_user = nil
end
```

## 10. Password-change session revocation

Design §3's password-change bullet, and §3's `forget(user)` requirement.
Both password-change paths need this, and it must fire only when the
password actually changed, not on every profile edit.

New shared method, `SessionsHelper#revoke_all_sessions_and_relogin(user)`:

```ruby
def revoke_all_sessions_and_relogin(user)
  LoginSession.where(user_id: user.id).delete_all
  forget(user)
  log_in(user)
end
```

Call sites, gated on the password actually having changed via Rails'
dirty-tracking (already used the same way in this controller's
`cleanup_changes`, `app/controllers/users_controller.rb:299`):

- `UsersController#update` (users_controller.rb:312): after `@user.save`
  succeeds, `revoke_all_sessions_and_relogin(@user) if
  @user.saved_change_to_password_digest?`
- `PasswordResetsController#update` (password_resets_controller.rb:50):
  after `@user.update(user_params)` succeeds, same guard

The guard matters: without it, this would fire on *any* profile field
change (locale, name, etc.), not just password changes, silently logging
out every other session whenever a user updates their bio.

## 11. Ops tool: `rake login_sessions:revoke[user_id]`

Design §3 and §9's resolved recommendation (fail loudly, matching
`UsersController#destroy`'s `User.find` and `generate_unsubscribe_url`'s
argument-validation style).

New file, e.g. `lib/tasks/login_sessions.rake`:

```ruby
namespace :login_sessions do
  desc 'Revoke all login sessions for the given user id'
  task :revoke, [:user_id] => :environment do |_t, args|
    if args.user_id.blank?
      puts 'Error: user id is required'
      puts 'Usage: rake login_sessions:revoke[123]'
      exit 1
    end

    user = User.find(Integer(args.user_id, 10)) # raises if not found
    count = LoginSession.where(user_id: user.id).delete_all
    puts "Revoked #{count} session(s) for user #{user.id} (#{user.name})."
  end
end
```

`User.find` (not `find_by`) deliberately raises `ActiveRecord::RecordNotFound`
on an unknown id, matching `UsersController#destroy`'s documented choice.
This does *not* call `forget`: unlike the password-change path (step
10), this tool exists for the case where the user themselves is not
acting (a report of suspected compromise), so silently also invalidating
their remember-me token without their knowledge is a bigger behavior
change than the incident-response tool needs; leave that decision to
whoever runs the task (they can also run `rails runner
"User.find(123).forget"` if warranted). Worth a one-line note in the
task's `desc` or output.

## 12. Admin visibility: route, controller, view

Design §3's admin-listing bullet.

- `config/routes.rb`: a resourceful, read-only route,
  `resources :login_sessions, only: [:index]`, inside whatever
  locale-scoping wrapper the rest of this app's routes already use
  (check existing `scope` set up for `/:locale/...` before adding this
  line, to match rather than invent a pattern).
- **Code-size opportunity**: the "check `current_user&.admin?`, flash,
  redirect" shape is about to exist in a *second* controller. Rather
  than hand-copy it again, add a small shared method to
  `ApplicationController`, e.g. `require_admin!`, usable as a
  `before_action`:

  ```ruby
  def require_admin!
    return if current_user&.admin?

    flash[:danger] = t('errors.not_authorized') # or existing equivalent key
    redirect_to root_url
  end
  ```

  Leave `UsersController`'s existing inline checks alone (tested,
  working code; migrating them is optional future cleanup, not this
  project's job); the new controller is the one that uses it, and the
  method is there for that cleanup later.
- New `app/controllers/login_sessions_controller.rb`:

  ```ruby
  class LoginSessionsController < ApplicationController
    before_action :require_admin!, only: [:index]

    def index
      @pagy, @login_sessions = pagy(
        LoginSession.order(last_used_at: :desc).includes(:user)
      )
    end
  end
  ```

  (`.includes(:user)` avoids N+1 queries when the view links each row to
  its user, matching how `UsersController`/`ProjectsController` already
  use `pagy`.)
- **Another small code-size opportunity**: the truncated-token display
  (`"#{token[0..8]}..."`) is about to exist in a *second* view too
  (`app/views/unsubscribe/edit.html.erb:27` already has it). Add a tiny
  shared helper instead of a second hand-copied literal, e.g. in
  `ApplicationHelper`:

  ```ruby
  def truncate_token(token)
    "#{token[0..8]}..."
  end
  ```

  Use it in the new view; optionally retrofit the existing one (touches
  tested code, so treat as optional, not required by this project).
- New view `app/views/login_sessions/index.html.erb`: a table with
  columns `user_id` (linked via `link_to user.name, user_path(user)`),
  `ip_address`, `user_agent` (plain `<%= %>`, per design §3's XSS note,
  never `raw`/`html_safe`), `created_at`, `last_used_at`, and
  `truncate_token(login_session.session_id_digest)` (design §9's
  resolved 9-character recommendation). Paginate with the standard
  `pagy_nav(@pagy)` partial already used elsewhere.
- Add a nav link to this page for admins only (check how the existing
  `/users` admin-only listing link is conditionally shown in the layout,
  and mirror it).

## 13. Cleanup: extend `task daily`

Design §3 and §9's resolved recommendation: no new scheduling
infrastructure, just one more step in the existing task.

In `lib/tasks/default.rake`, inside `task daily` (currently around line
1758, alongside the existing `User.purge_unactivated_accounts` call):

```ruby
stale_count = LoginSession.where(
  'last_used_at < :idle OR created_at < :absolute',
  idle: SessionsHelper::SESSION_TTL.ago.utc,
  absolute: SessionsHelper::ABSOLUTE_SESSION_AGE.ago.utc
).delete_all
puts "Purged #{stale_count} stale login session(s)."
```

Both conditions matter: `last_used_at` catches idle/abandoned sessions
around the 48-hour window (design §7's write-load discussion); `created_at`
catches the rarer case of a continuously-active session hitting the
30-day absolute cap. Live requests already reject both cases in
`setup_authentication_state` (step 6); this task's job is only to stop
the rows from accumulating, not to enforce the expiry itself.

## 14. Tests

AGENTS.md requires 100% statement coverage for production code, meaning
everything this plan adds except the rake task in step 11 (`rake` tasks
are exercised by the test named for them below, but aren't held to the
same formal coverage gate the app's request/response and model code is).
Each area below needs real coverage, not just the happy path: every
branch this plan adds (idle vs. absolute expiry, matched vs. mismatched
`pending_token`, sensitive-field-dropped vs. not) needs a test that
actually distinguishes it from its sibling branch, not just one test
that happens to touch the line.

Write the new code with this in mind, not as an afterthought once it
exists: prefer small, named methods with a single clear responsibility
(`idle_expired?`, `sensitive_fields_present?`-shaped checks, the
`stash_pending_resubmission`/`show` split already in this plan) over
inlining logic into a large method, since a small method is something a
test can call and assert on directly, while logic buried inside a large
`before_action` or controller action can usually only be exercised
indirectly, through whatever HTTP-level behavior happens to depend on
it. This isn't a new principle for this codebase (`can_edit?` vs.
`can_edit_else_redirect` already draw exactly this line), just worth
stating as a goal for the new code specifically, given how much of this
step involves adding new conditional branches to existing methods.

- `test/models/login_session_test.rb`: `digest`/`find_by_session_id`
  round-trip; `idle_expired?`/`absolutely_expired?` boundary conditions;
  `create_for` stores a digest, not the raw session id (assert the raw
  value is never a substring of any column's DB-stored value, guarding
  the core security property directly, not just indirectly through
  behavior).
- `test/controllers/application_controller_test.rb` (or wherever
  `setup_authentication_state` is already tested): idle expiry,
  absolute-cap expiry, and the ordinary logged-in path, all via the new
  table instead of cookie-only state.
- `test/integration/drop_session_cookie_test.rb`: rerun as-is first,
  since it pins the *outcome*, not the mechanism; it should still pass
  unmodified once `SESSION_BOOKKEEPING_KEYS` correctly treats
  `:login_session_id` as real content (step 4). If it doesn't pass
  unmodified, that is itself a signal something in step 4 or 6 is wrong.
- `test/controllers/sessions_controller_test.rb`: login creates exactly
  one `LoginSession` row, with `ip_address`/`user_agent` populated;
  logout deletes exactly that row and no other session belonging to the
  same user (a second-session-survives-logout test is the one that most
  directly proves design §3's "ordinary logout" bullet).
- Password-change tests (`test/controllers/users_controller_test.rb`,
  `test/controllers/password_resets_controller_test.rb`): changing the
  password revokes other sessions and the current request stays logged
  in; changing an unrelated field (e.g., locale) does *not* revoke
  sessions, directly testing the `saved_change_to_password_digest?` guard
  from step 10.
- `test/lib/tasks/login_sessions_rake_test.rb` (matching however
  existing rake tasks are tested in this repo, check for a precedent
  file before inventing a new pattern): valid id revokes; unknown id
  raises/exits nonzero, not silently.
- `test/controllers/login_sessions_controller_test.rb`: non-admin gets
  redirected/forbidden; admin sees the list; **an explicit XSS test**,
  asserting a `login_sessions` row with `<script>alert(1)</script>` (or
  similar) in `user_agent` renders escaped in the response body, given
  design §3 calls this out by name as a real stored-XSS vector.
- Cleanup task test: rows past each threshold are deleted, rows just
  inside each threshold are kept (boundary tests, not just "old enough"
  vs. "new").

## 15. Preserve in-progress form submissions across a forced re-login

Added after review. This is a general fix for a "login loss" case, not a
rollout-specific one: `logged_in?` (sessions_helper.rb:82) is a plain
`@session_user_id.present?` check with no branching on *why* it's
absent, so the same mechanism below covers all three causes uniformly:
the rollout (step 16) removing `user_id` from the cookie, the ordinary
48-hour idle timeout, and the 30-day absolute cap, all three drive
`@session_user_id` to `nil` the same way (step 6), and none of the code
in this step needs to know or care which one happened. Users mostly log
in specifically *to make changes*, so the case worth protecting against
is someone mid-edit (most importantly, project criteria justifications,
real typed prose) whose submission lands right when any of the three
strikes. The rollout is simply the one case where this happens to every
logged-in user at once instead of one user at a time, which is why it's
what prompted building this, but it isn't the only beneficiary.

**What happens today, checked rather than assumed**: a POST/PATCH from a
logged-out submitter does not currently get a chance to re-authenticate
without losing what they typed. Four separate gates handle this, none
of them the same way:

| Gate | Actions | Today, on not-logged-in |
|---|---|---|
| `ProjectsController#can_edit_else_redirect` (projects_controller.rb:1105) | edit, update, choose_edit | GET → login w/ `return_to`; non-GET → flash + redirect to the project page, submitted data discarded |
| `ProjectsController#can_control_else_redirect` (projects_controller.rb:1120) | destroy, delete_form | redirect to root; nothing typed to preserve (a delete confirmation, not a form) |
| `UsersController#redir_unless_logged_in` (users_controller.rb:423) | edit, update, destroy, index | redirect to `login_path`, no `return_to`, data discarded |
| `UsersController#redir_unless_current_user_can_edit` (users_controller.rb:438) | edit, update | redirect to root, no login prompt at all, data discarded |

Only the first and third need this treatment (project editing and
profile editing, the two places a logged-in user has real typed
content). `can_control_else_redirect` has nothing to preserve.
`redir_unless_current_user_can_edit`'s *other* failure mode, logged in
as the wrong user, is a genuinely different case (re-authenticating
doesn't help; they need different rights), and should keep discarding
and flashing exactly as it does now: only its "not logged in at all"
path is this same problem in disguise.

**The tempting shortcut that doesn't actually work, checked, not
assumed**: stash the submitted params in `Rails.cache` instead of a new
table. Checked `config/environments/production.rb`:
`config.cache_store = :memory_store`, in-process, per-dyno. A deploy
(the exact event this exists for) replaces the process; a stash written
there wouldn't survive it, and wouldn't reliably survive even ordinary
multi-dyno operation, since the request that stashes and the request
that later retrieves could land on different processes. A small
database table is the right tool here specifically *because* it
survives the restart that necessitates this feature.

**A second tempting shortcut that also doesn't work, for a different
reason**: avoid the table by round-tripping the submitted data through
hidden form fields instead, no server storage at all. This works cleanly
for local email/password login, since the whole flow stays on our own
pages. It does not work for GitHub OAuth login: that flow leaves the
site entirely (redirect to github.com and back), so hidden fields can't
survive the trip, and OAuth `state` parameters are size-constrained by
the provider, not by us, so a large in-progress project edit (many
criteria fields, real prose) likely won't fit even if squeezed in. Given
this is a GitHub-centric tool, GitHub login is plausibly the *majority*
path, not an edge case worth carving out. Since GitHub login needs a
small server-side stash no matter what, using the same mechanism for
local login too is less total code than building and maintaining two
parallel preservation paths for the sake of avoiding one cheap row
insert on the local-login side.

**Design**: one small table, a token that lives in the session cookie,
not in any URL, hidden field, or OmniAuth parameter (see the security
note below for why that distinction matters), and, found during review,
a gate (`had_prior_session?`, defined in step 6) restricting the whole
mechanism to browsers with forgery-proof evidence of a genuine prior
login, so it's never reachable by a visitor who has never authenticated
at all, closing an anonymous, zero-credential abuse path this table
would otherwise open (see flow step 1, below).

- New table `pending_resubmissions`:

  ```ruby
  create_table :pending_resubmissions do |t|
    t.string :token, null: false
    t.string :resubmit_path, null: false
    t.string :resubmit_method, null: false
    t.text :params_json, null: false
    t.timestamps
  end
  add_index :pending_resubmissions, :token, unique: true
  ```

  No foreign key: unlike `login_sessions`, a row here isn't tied to a
  known user (it's created *because* the submitter isn't authenticated
  yet), so there's no `user_id` to reference. `created_at` (from
  `t.timestamps`) is what step 13's cleanup line ages out against.
- New file `app/models/pending_resubmission.rb`:

  ```ruby
  # frozen_string_literal: true
  class PendingResubmission < ApplicationRecord
  end
  ```

  No custom methods needed; every operation on it (`create!`, `find_by`,
  `destroy`, the cleanup `.where(...).delete_all`) is plain
  `ActiveRecord`, unlike `LoginSession`, which needed its own digest
  logic.
- New route, `config/routes.rb`, alongside the other locale-scoped
  routes: `get 'pending_resubmissions/:token', to:
  'pending_resubmissions#show', as: :pending_resubmission`.
- `stash_pending_resubmission` and `SENSITIVE_STASH_KEYS` (below) live in
  `ApplicationController`, alongside `require_admin!` (step 12): both
  `ProjectsController#can_edit_else_redirect` and
  `UsersController#redir_unless_logged_in` need to call it, and it needs
  `request`/`session`, so it can't be a plain model or helper method.
- **Token**: plain `SecureRandom.urlsafe_base64`, not hashed at rest in
  the *database*. Considered and rejected hashing it (like
  `session_id_digest`, section 3): unlike `login_sessions`, the
  sensitive thing here, the drafted content, is stored directly in
  `params_json`, in the *same row* as the token. A database-read
  attacker sees it by reading the row regardless of whether the token
  column is hashed; they don't need to present anything back to the app
  to compute or exploit a match. Hashing the lookup key doesn't protect
  a payload sitting unencrypted right next to it, so it would add a key
  and an HMAC call for no closed gap. The actual requirement is that the
  token be unguessable, which `SecureRandom` already provides without
  hashing.
- **Security-critical: the token must never travel through anything an
  attacker could construct and hand to someone else** (a URL, a hidden
  field, an OmniAuth parameter). Caught during review, not something the
  original design got right the first time: if `pending_token` travels
  via `login_path(pending_token: ...)`, an attacker can trigger their
  *own* rejected submission against any editable resource, with
  whatever malicious content they choose, get back a token, and send a
  link like `/pending_resubmissions/THEIR_TOKEN` directly to a victim,
  logged in or not. `PendingResubmissionsController#show`, checking only
  "does a row exist for this token," would show the victim a page that
  looks like "here's your pending edit," pre-filled with the attacker's
  content, targeting a resubmit path the attacker chose. A victim who
  doesn't scrutinize it and clicks "Resume saving your changes" submits
  the attacker's data as their own authorized edit. This isn't a CSRF
  hole in the usual sense (the victim's browser genuinely submits a
  same-origin, correctly-tokened form); the attacker is exploiting *what
  the app displays as trustworthy*, not forging the request itself.
  Design §5's "an unguessable value alone gives an attacker nothing"
  reasoning for `login_session_id` doesn't transfer here, because that
  value only ever travels inside the encrypted cookie; this one was
  designed to travel through exactly the channels an attacker can hand
  to someone else.

  **The fix, which also simplifies the rest of this step**: bind the
  token to the session cookie, the same way `forwarding_url` already is,
  instead of passing it through URLs at all.

  ```ruby
  SENSITIVE_STASH_KEYS = %w[password password_confirmation email].freeze

  def stash_pending_resubmission(resubmit_path, permitted_params)
    token = SecureRandom.urlsafe_base64
    dropped = SENSITIVE_STASH_KEYS.any? { |key| permitted_params[key].present? }
    PendingResubmission.create!(
      token: token, resubmit_path: resubmit_path,
      resubmit_method: request.request_method,
      params_json: permitted_params.to_h.except(*SENSITIVE_STASH_KEYS).to_json
    )
    session[:pending_token] = token
    session[:pending_sensitive_fields_dropped] = true if dropped
  end
  ```

  Because this now lives in the session cookie, it survives the GitHub
  OAuth round trip for free: it's this app's own domain's cookie, sent
  automatically by the browser on the callback request regardless of the
  detour through github.com, with no need to thread it through
  OmniAuth's `state`/`origin` mechanism at all. It does need one more
  save/restore, exactly matching how `forwarding_url` is already
  protected: `SessionsController#counter_fixation` must save both
  `session[:pending_token]` and `session[:pending_sensitive_fields_dropped]`
  before its `reset_session` call and restore them after, or a login
  attempt would silently drop them. This also means none of the
  following are needed anymore, and should be dropped from this step:
  the `sessions/new.html.erb` hidden field and GitHub-URL query param,
  and the `successful_login`/`local_login_procedure`/`omniauth_login`
  signature changes originally planned, since `successful_login` can
  just read `session[:pending_token]` itself.

  Checked `UsersController::PERMITTED_PARAMS` (users_controller.rb:22):
  it includes `email`, and this app already encrypts email at rest
  (`attr_encrypted :email`, section 5's precedent for keyed data). A
  naive stash would write a plaintext pending email change into this
  table, inconsistent with how the app treats email everywhere else.
  Rather than add a second encryption key to protect it (real
  protection, but a new key, a new encrypted column, another entry in
  `docs/secrets-policy.md`), just exclude it, the same way `password`/
  `password_confirmation` already have to be excluded. `Project`'s
  permitted fields (criteria statuses, justifications, repo info) have
  nothing comparably sensitive; that content becomes public once saved
  anyway.

  Excluding these fields from the stash without saying so anywhere
  would recreate the silent-partial-loss problem this step exists to
  avoid: someone mid-password-change who gets bumped would see the
  confirmation page with no password field at all, and if they click
  "Resume saving your changes" without noticing, that change is
  silently dropped while everything else succeeds, worse than a clean
  total loss, since they might believe they're protected when they
  aren't. `session[:pending_sensitive_fields_dropped]` (set above,
  checked in step 4 below) is what closes this: a plain flash on the
  confirmation page naming *both possible fields by name* ("your email
  and/or password"), not which one specifically applies here. That's
  not the dynamic-list problem it might look like: `SENSITIVE_STASH_KEYS`
  is a fixed set of exactly two concepts (email, password), so "email
  and/or password" is one static, translatable phrase, not a list
  assembled at runtime, and naming them is strictly more useful to the
  user than staying fully generic, while still preserving and
  resubmitting everything else, rather than discarding
  the whole submission just because one field in it was sensitive.

**Flow**, extending the exact save/restore-around-`reset_session`
mechanism this app already uses for `forwarding_url`
(`SessionsController#counter_fixation`), not a new one:

1. `can_edit_else_redirect` (projects_controller.rb:1105): only `update`
   submits a body worth stashing, so check the HTTP method, not just
   `logged_in?`, to avoid calling `project_params` on a GET where
   `params[:project]` isn't present at all. **Also gated on
   `had_prior_session?`** (step 6): found during review that without
   this, `stash_pending_resubmission` is reachable by anyone with no
   credential of any kind at all, unlike every other write this app
   allows an anonymous visitor to make (signup, password reset both
   require at least a plausible-looking unique value and are separately
   throttled in `rack_attack.rb`). `had_prior_session?` closes this
   structurally, not heuristically: an attacker without `SECRET_KEY_BASE`
   cannot make it return true without having genuinely logged in at
   least once themselves, so this stops being a zero-cost action for a
   never-authenticated visitor:

   ```ruby
   def can_edit_else_redirect
     return true if can_edit?

     if !logged_in?
       return redirect_to login_path(return_to: request.original_fullpath) if request.get?

       if request.patch? && had_prior_session? && params[:project].present?
         stash_pending_resubmission(request.path, project_params)
         return redirect_to login_path(return_to: request.original_fullpath)
       end
     end

     flash[:danger] = t('projects.edit.not_authorized')
     redirect_to project_section_path(@project,
                                      @criteria_level || Sections::DEFAULT_SECTION)
   end
   ```

   `redir_unless_logged_in` (users_controller.rb:423) gets the same
   treatment, guarding on `request.patch?` (the only PATCH action in its
   `only: %i[edit update destroy index]` list is `update`):

   ```ruby
   def redir_unless_logged_in
     return if logged_in?

     if request.patch? && had_prior_session? && params[:user].present?
       stash_pending_resubmission(request.path, compute_user_params)
       return redirect_to login_path(return_to: request.original_fullpath)
     end

     flash[:danger] = t('users.please_log_in')
     redirect_to login_path
   end
   ```

   **The `params[:project].present?` / `params[:user].present?` check
   matters; it isn't defensive filler.** `project_params` and
   `compute_user_params` both call `params.expect(...)`, and Rails 8's
   `expect` raises `ActionController::ParameterMissing` when the named
   top-level key is absent from the request entirely (a malformed or
   hand-crafted PATCH with no `project`/`user` key at all, sent by a
   browser with no valid session). Checked: `application_controller.rb`
   has no `rescue_from ActionController::ParameterMissing`, so nothing in
   this app currently catches that exception; `config/environments/test.rb`
   sets `show_exceptions = :none`, so a test exercising this case raises
   directly instead of failing gracefully. Without the presence check, a
   request shaped that way would surface as a bare 400 error page in
   production (and a raised exception in tests) instead of the existing
   flash-and-redirect behavior every other malformed or unauthorized
   request on this action already gets. With the check, that request
   simply falls through to the same `flash[:danger]` branch at the bottom
   it hits today, no regression for a shape of request that isn't a real
   in-progress edit.

   A visitor with no `had_prior_session?` evidence, or a request with no
   `project`/`user` param to stash, falls through to exactly today's
   existing plain discard, no regression for either a
   genuinely-never-visited anonymous submitter or a malformed request,
   since that's already today's behavior for both.

   Both stash unconditionally once past that gate, whether or not a
   sensitive field is present; `stash_pending_resubmission` handles that
   distinction itself (excluding the field from what's saved, flagging
   it via `session[:pending_sensitive_fields_dropped]`), so the gate
   methods don't need to know or care.

   Note there's no `pending_token:` in either redirect: it's already in
   `session[:pending_token]`, set inside `stash_pending_resubmission`.
2. `counter_fixation` (sessions_controller.rb:138) must save and restore
   both `session[:pending_token]` and
   `session[:pending_sensitive_fields_dropped]` around `reset_session`,
   next to the existing `forwarding_url` handling:

   ```ruby
   def counter_fixation
     ref_url = session[:forwarding_url]
     pending_token = session[:pending_token]
     pending_dropped = session[:pending_sensitive_fields_dropped]
     I18n.locale = session[:locale]
     reset_session
     session[:forwarding_url] = ref_url
     session[:pending_token] = pending_token
     session[:pending_sensitive_fields_dropped] = pending_dropped if pending_dropped
   end
   ```

   Without this, both would be silently wiped on every login attempt,
   since `counter_fixation` runs unconditionally at the top of every
   `POST /login`, success or failure.
3. `successful_login` (sessions_controller.rb:113) checks
   `session[:pending_token]` directly, no new parameter needed and no
   change needed to either caller (`local_login_procedure`,
   `omniauth_login`):

   ```ruby
   def successful_login(user, return_to_path = nil)
     log_in user
     if session[:pending_token].present?
       redirect_to pending_resubmission_path(token: session[:pending_token])
     elsif return_to_path.present? && valid_return_path?(return_to_path)
       redirect_to return_to_path, allow_other_host: false
     else
       redirect_back_or root_url
     end
     # ...unchanged: flash[:success], user.update_columns(last_login_at:)
   end
   ```

   This is also what makes GitHub OAuth login work with no OmniAuth
   `state`/`origin` involvement at all: `session[:pending_token]` is
   this app's own domain cookie, sent automatically by the browser on
   the `/auth/github/callback` request regardless of the detour through
   github.com in between; nothing needs to thread it through GitHub's
   side of the flow.
4. New `PendingResubmissionsController#show` **must verify the
   requested token matches this browser's own session**, not just that
   a database row exists for it. This is the check that actually closes
   the vulnerability described above: even if the resulting URL is
   guessed or shared, it only works for the one browser whose session
   cookie says it's expecting that exact token, and an attacker cannot
   write into a victim's session cookie without `SECRET_KEY_BASE`
   (design §1's whole premise).

   **A second bug, found while re-reviewing the fix above, not the
   original vulnerability itself**: an earlier draft of this action read
   `session.delete(:pending_token)` unconditionally, before comparing it
   to `params[:token]`, on the reasoning that the key is single-use
   either way. That reasoning only holds when the token matches. If it
   doesn't, for example a stale bookmarked link, a typo, or someone
   simply poking at the URL, that unconditional delete destroys the
   browser's own *real* `session[:pending_token]`, the one sitting there
   waiting to be resumed, even though no matching row was ever found or
   touched. The user is left with a generic "expired" flash and no way
   back to a submission that was never actually lost, at the one endpoint
   built specifically to prevent that. The fix is to read and compare
   before deleting anything, and only clear the session keys on an actual
   match:

   ```ruby
   class PendingResubmissionsController < ApplicationController
     def show
       token = params[:token]
       expected = session[:pending_token]
       if token.present? && expected.present? && token == expected
         session.delete(:pending_token) # single-use, only on a real match
         dropped = session.delete(:pending_sensitive_fields_dropped)
         pending = PendingResubmission.find_by(token: token)
       end
       unless pending
         flash[:danger] = t('.expired')
         redirect_to root_url and return
       end

       pending.destroy # single-use
       flash.now[:warning] = t('.sensitive_fields_dropped') if dropped
       @resubmit_path = pending.resubmit_path
       @resubmit_method = pending.resubmit_method
       @fields = JSON.parse(pending.params_json)
     end
   end
   ```

   A mismatched or missing `params[:token]` now leaves
   `session[:pending_token]` untouched, so the browser's real pending
   submission, if it has one, stays reachable at its own correct URL.

   `flash.now`, not plain `flash`, since this action renders directly
   rather than redirecting; a plain `flash[:warning]=` here would linger
   and reappear on whatever page comes after this one, which isn't what
   we want. The message names both possible fields rather than staying
   fully generic, e.g. "Your email and/or password change couldn't be
   restored here; please re-enter it separately if needed," since
   `SENSITIVE_STASH_KEYS` is a fixed set of exactly two concepts, not a
   variable-length list that would need locale-aware joining and
   pluralization to name accurately. It doesn't say *which* of the two
   applies to this specific case, just that it might be either, which is
   still strictly more useful than a fully generic "some sensitive
   information."

   Paired view, e.g. `app/views/pending_resubmissions/show.html.erb`:
   one `form_with url: @resubmit_path, method: @resubmit_method` block,
   `@fields.each` emitting one `hidden_field_tag` per key/value pair, and
   one visible submit button, e.g. "Resume saving your changes." Checked
   `Project::PROJECT_PERMITTED_FIELDS` and `UsersController::PERMITTED_PARAMS`:
   both are flat lists of scalar attributes (no nested or array-valued
   fields on either), so the `to_json`/`JSON.parse` round trip always
   produces a flat hash; a single non-recursive loop over `@fields` is
   enough, and building anything more general than that would be
   unneeded complexity for a shape of data that doesn't occur here. This
   view never needs to know it's a project or a user; it echoes back
   opaque key/value pairs.

**Cleanup**: one more `.where('created_at < ?', 3.days.ago).delete_all`
line added to `task daily` (step 13), alongside the `login_sessions`
cleanup already being added there. Single-use covers the common case
(destroyed the moment it's displayed); the few-day window is only for
ones nobody ever came back to.

**Tests**: a submission rejected as logged-out sets `session[:pending_token]`
and redirects to login; both local login and GitHub OAuth login (mocked)
carry it through `counter_fixation`'s `reset_session` intact and land on
`/pending_resubmissions/:token`, which shows the stashed values and
successfully resubmits on click; the stash is single-use (a second visit
to the same token finds nothing, whether or not `session[:pending_token]`
is also gone by then); **a test specifically for the vulnerability this
step was rewritten to close**: visiting `/pending_resubmissions/:token`
with a *valid* token but *without* the matching `session[:pending_token]`
(simulating an attacker sending a victim a direct link) must be rejected,
not shown the stashed content; a missing/expired/mismatched token
redirects to root without error; **a test for the second bug found while
reviewing that fix**: a session genuinely holding
`session[:pending_token] = "A"` that then visits
`/pending_resubmissions/B` (a different, wrong token) must still find its
own real submission at `/pending_resubmissions/A` afterward, that is, the
mismatched visit must not have deleted `session[:pending_token]`; a
PATCH with no `project`/`user` key at all from a logged-out browser
(malformed or hand-crafted) falls through to the ordinary
flash-and-redirect, not an unhandled `ActionController::ParameterMissing`;
a stash created from a password or email change never contains those
fields, asserted directly against the stored row, not just indirectly
through behavior; **a test for the silent-partial-loss fix**: a logged-out `UsersController#update`
submission that includes a non-blank `password` (or `email`) still
creates a `PendingResubmission` row and still redirects to
`/pending_resubmissions/:token` (name/locale intact in `params_json`,
stripped fields absent), but the resulting confirmation page carries
the generic "sensitive information couldn't be restored" warning, while
the same submission with only ordinary fields shows no such warning;
**a test for `had_prior_session?`, the anonymous-abuse gate**: a
logged-out PATCH from a browser with no session cookie at all (neither
`login_session_id` nor the legacy `user_id`) creates no
`PendingResubmission` row and falls back to today's plain discard, a
rollout-shaped session (`session[:user_id]` present, `login_session_id`
absent, matching a pre-deploy cookie) *does* get preserved, and a
current-format session that expired mid-request (an idle- or
absolute-expired `login_session_id`) also gets preserved, exercising
all three of the causes design §3 lists, not just the rollout one.

## 16. Rollout note

This is a one-time, expected side effect worth calling out before
deploying, not discovering afterward: existing session cookies carry
`session[:user_id]` (an integer), which the new code no longer reads at
all. Every currently-logged-in user is logged out at deploy time. This is
the same *kind* of event as the `SECRET_KEY_BASE`-rotation global logout
the design doc already treats as normal (design §1, §2), just triggered
by this deploy instead of a deliberate secret rotation, and, with step 15
in place, an in-progress edit's typed content survives it: the user is
prompted to log back in and sees their draft, not an error page and lost
work.

A minor, self-healing residual effect worth knowing about, not worth
building anything to prevent: leftover `session[:user_id]`/
`session[:time_last_used]` keys from a pre-deploy cookie, and, separately,
an abandoned `session[:pending_token]` from a bounced submission the
user never returned to, both persist in that browser's session hash
until `reset_session` next runs for any reason (any login attempt,
success or failure, via `counter_fixation`, or an explicit logout). Until
then, `session_has_user_content?` (application_controller.rb:719) sees
these as "real content" and keeps the cookie alive, so that specific
browser doesn't benefit from the CDN-caching optimization
`drop_unneeded_session_cookie` provides for genuinely anonymous
requests. This is a performance nit, not a security or correctness one,
and resolves itself the next time that browser interacts with `/login`
in any way.

## 17. Final checks before merging

- `rake default` (full local CI: rubocop, rails_best_practices,
  markdownlint, eslint, whitespace, YAML syntax, license, bundle_audit,
  tests) per AGENTS.md.
- `rake rubocop -a` only (never `-A`) for any offenses it can safely
  autocorrect.
- `rake whitespace_check`.
- Update `docs/secrets-policy.md` (design §8 already flags this) to add
  `SESSION_ID_HMAC_KEY` to the secret-rotation runbook, and to note that
  a session table now gives an additional global-logout mechanism
  (truncating `login_sessions`) alongside the existing
  `SECRET_KEY_BASE`-rotation procedure.
- Confirm `docs/cdn-cache-not-logged-in.md`'s invariant (anonymous
  requests never receive a `Set-Cookie`) still holds; nothing in this
  plan should change anonymous-request behavior, but it's cheap to
  re-verify given how carefully that invariant is documented.
- New user-facing strings this plan introduces (the `require_admin!`
  flash, step 12; `PendingResubmissionsController`'s `.expired` flash,
  the generic `.sensitive_fields_dropped` warning, and the "Resume
  saving your changes" button text, step 15) need real i18n keys, not
  placeholder English. Check for an existing equivalent key before
  adding a new one (`require_admin!`'s code sketch already flags this
  as unresolved). This app is translated into 6+ languages via
  translation.io (AGENTS.md); confirm the usual workflow for adding a
  new translatable string is followed, not just an `en.yml` edit.
