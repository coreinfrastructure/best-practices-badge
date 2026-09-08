# Server-Side Login Sessions

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

**Status: design discussion, not yet planned or implemented.** This document
records what we've decided to do, what we've decided *not* to do, and why,
before writing an implementation plan.

## 1. Problem

`config/initializers/session_store.rb` uses `:cookie_store`. `session[:user_id]`
(set in `SessionsHelper#log_in`, app/helpers/sessions_helper.rb) lives entirely
inside a cookie that Rails encrypts and signs using a key derived from
`SECRET_KEY_BASE`. Anyone who obtains `SECRET_KEY_BASE` can forge a cookie
claiming to be any user id, including an admin, with no other secret needed.
The blast radius of that one environment variable leaking is "become anyone."

Today the only way to invalidate all existing sessions is to rotate
`SECRET_KEY_BASE` or rename the session cookie key (both documented in
`config/initializers/session_store.rb` and `docs/secrets-policy.md`). There's
no way to see who is currently logged in, and no way to revoke one session
without revoking all of them.

## 2. Goal

Move the session's authentication state (which user this session belongs to)
out of the cookie and into a new database table, indexed by a large random
session id. The cookie holds only that random id. Compromising
`SECRET_KEY_BASE` alone then gains an attacker nothing: they'd still need an
actual valid session id, which is never derivable from `SECRET_KEY_BASE` and
is only ever handed to the legitimate browser.

We're also raising the bar past the original ask: the new table stores a
**keyed hash (HMAC) of the session id, not the session id itself**, so that
an attacker who can only read the database (e.g., via SQL injection, a stolen
backup, or insider access) *also* gains nothing usable. See section 5.

Side benefit: the new table gives us a place to see currently logged-in
users, and a simple way to revoke one session (delete its row) or force a
global logout (truncate the table) without touching `SECRET_KEY_BASE`.

## 3. What we ARE doing

- Add a new table (name TBD, e.g. `login_sessions`) with roughly:
  - a keyed-hash column of the session id (see section 5) — unique, indexed,
    this is the lookup key
  - `user_id` (foreign key to `users`)
  - `created_at` — also used for the absolute session age cap, below
  - `last_used_at` (or reuse `updated_at`) — for the idle-timeout logic
    currently done via `session[:time_last_used]`
  - `ip_address` and, optionally, a user-agent string — recorded once at
    creation, purely observational (no enforcement). Gives real forensic
    value after an incident and makes the "see who's logged in" admin view
    (section 2) show more than opaque ids and timestamps, for the cost of
    two columns. Worth noting: today the app only ever uses the client IP
    transiently (Rack::Attack throttling, the OAuth-failure log line in
    `SessionsController#failure`) via the existing `ClientIp`
    (app/lib/client_ip.rb) helper; nothing persists it. This column is a
    genuinely new, if small, category of stored personal data, not an
    extension of an existing pattern. It's bounded automatically by the
    row's own lifecycle (deleted on logout, the absolute cap, or idle
    cleanup below), so there's no separate retention question to solve,
    but it's worth being deliberate about, not just "cheap so why not."
    Use the existing `ClientIp` helper for extraction rather than
    `request.remote_ip` directly, for consistency with the rest of the app.
- On login, generate a large random session id (128 bits — see the note on
  bit length below), store its keyed hash plus `user_id` in the new table,
  and put the raw random id in the (still `cookie_store`-based) session
  cookie in place of `user_id`/`time_last_used`. This does not change what
  else lives in that cookie (`forwarding_url`, `locale`, `user_token`,
  `github_name`, flash) — see section 6.1 on why `user_token` stays put.
- **Absolute session age cap, independent of activity.** `SESSION_TTL`
  (48 hours) is an *idle* timeout: `RESET_SESSION_TIMER` refreshes it on
  activity, so a continuously-active session, legitimate or one an attacker
  is keeping alive, has no hard upper bound today. Check `created_at`
  against a new constant (e.g. 30 days) in `setup_authentication_state`, so
  a leaked session id's useful life is bounded regardless of how often it's
  used.
- **On password change (and similarly sensitive account-security events:
  password reset, presumably 2FA changes if we ever add them): revoke every
  existing session for that user and mint a fresh one for the request doing
  the changing.** Concretely, delete all of that user's `login_sessions`
  rows (`LoginSession.where(user_id: user.id).delete_all`) and immediately
  create a new row + new cookie value, the same way login does, so the
  browser making the change stays logged in on a freshly issued session
  while every other previously-issued session id, including a stolen one an
  attacker might be riding, stops working. This is standard practice (OWASP
  recommends it) and is the highest-value item here relative to its cost:
  one delete plus a call into the same login-session-creation code path.
  This is a deliberate, narrow exception to the next point.
  **Must also call `SessionsHelper#forget(user)`** (app/helpers/
  sessions_helper.rb:120) in the same flow. Checked while reviewing this
  document: `UsersController#update` (app/controllers/users_controller.rb:
  312) and `PasswordResetsController#update` (app/controllers/
  password_resets_controller.rb:50), today's two password-change paths,
  neither touches `remember_digest`. Without adding `forget(user)` here,
  revoking every `login_sessions` row still leaves a permanent "remember
  me" cookie (if the user, or an attacker, ever set one) able to silently
  re-establish a brand-new session with no password needed, defeating the
  point of this bullet. This isn't new to this project, but this feature
  is the first place it's directly relevant, and closing it here is one
  extra method call given `forget` already exists.
- **Ordinary logout affects only the current session, never all of a
  user's sessions.** `SessionsHelper#log_out`
  (app/helpers/sessions_helper.rb:195) deletes the one row matching the
  current cookie's session id, not `reset_session` alone and not every row
  for that `user_id`. Do not generalize logout into a global revoke: a
  user legitimately logged in on
  a phone and a laptop should be able to log out of one without being
  logged out of the other. The password-change case above is the one
  deliberate exception, because there the intent genuinely is "kill every
  session but this one."
- On each request, `ApplicationController#setup_authentication_state`
  (app/controllers/application_controller.rb:624) looks up the session id's
  hash in the new table once, exactly the way it currently reads
  `session[:user_id]` once, and continues to set `@session_user_id` etc. the
  same way. `current_user`'s memoization (`SessionsHelper#current_user`,
  app/helpers/sessions_helper.rb:70) and `update_session_timestamp`
  (app/controllers/application_controller.rb:658) are otherwise unaffected;
  `last_used_at` moves from the cookie into the new table's row.
- `ApplicationController#try_remember_token_login`
  (app/controllers/application_controller.rb:729) currently logs a user back
  in from the "remember me" cookie by setting `session[:user_id]` and
  `session[:time_last_used]` directly, bypassing `SessionsHelper#log_in`.
  Under this design it must instead mint a **new** login-session row (fresh
  random id, fresh hash) the same way an explicit login does, not just set a
  session key that no longer means anything on its own. This is a required
  change, not optional cleanup: without it, a remember-me-restored session
  would have no matching row and `setup_authentication_state` would treat
  the user as logged out.
- A rake task, e.g. `rake sessions:revoke[user_id]`, that deletes every
  `login_sessions` row for the given user id. Same `delete_all` call as the
  password-change flow above, exposed as an ops/incident-response tool: an
  admin can kill a specific user's sessions on report of suspected
  compromise, without waiting on that user to change their password. A few
  lines given the delete logic already exists for password change.
- No `github_name` column on the new table: it's one join away via `user_id`
  to `users`, and duplicating it would violate 3NF for no benefit.
- Clean up expired/stale rows the same way `User.purge_unactivated_accounts`
  (app/models/user.rb:376) cleans up abandoned accounts: a scheduled job
  (solid_queue), following the existing daily/monthly maintenance task
  pattern.

## 4. Models and views never touch the session directly, and won't need to

Checked while planning this: `setup_authentication_state` really is the
single choke point for identity, which is why this project's blast radius
stays contained to the items in section 3.

- **Models never look anything up themselves.** They're always handed an
  already-resolved identity:
  - PaperTrail (audit trail): `ApplicationController#user_for_paper_trail`
    (app/controllers/application_controller.rb:165) just returns
    `@session_user_id`. The `set_paper_trail_whodunnit` before_action runs
    *after* `setup_authentication_state` (see the comment at
    application_controller.rb:88-90) and hands that id to PaperTrail's
    gem-internal mechanism. Models never query "who's doing this."
  - Ordinary model methods take a `user` object as an explicit parameter,
    e.g. `Project.attempt_notification(project, user, ...)`
    (app/models/project.rb:1397). The controller calls `current_user` once
    and passes the result in. Models have zero awareness of sessions,
    cookies, or requests — they'd work identically from a rake task or
    console.
- **Views get identity for free, via two ordinary Rails mechanisms, not
  anything session-specific**:
  - `SessionsHelper` is `include`d into `ApplicationController`
    (app/controllers/application_controller.rb:752), and because it lives
    in `app/helpers/`, Rails' default `include_all_helpers = true`
    (unmodified in this app) auto-mixes every helper module into every
    view too. That's why templates call `current_user`, `logged_in?`,
    `can_edit?`, etc. directly (e.g. app/views/users/show.html.erb:11)
    with no `helper_method` declaration needed.
  - Rails automatically copies controller instance variables into the
    view's rendering context, so a view's call to `current_user` runs the
    exact same method against the exact same `@session_user_id`/
    `@current_user` that `setup_authentication_state` and `current_user`'s
    own memoization already resolved once, server-side, before the view
    ever rendered. No new lookup happens in the view.

Conclusion: this redesign only has to change how `setup_authentication_state`
resolves `@session_user_id` (cookie value directly → session-id lookup in
the new table). Everything downstream of it, in models and views, is
already decoupled from *how* that id was resolved and needs no changes.

## 5. Hashing the session id: keyed HMAC, not the raw value, not bcrypt

We store `HMAC-SHA256(key, session_id)` in the table, not `session_id` itself.

- **Why keyed HMAC, not a plain hash**: using a dedicated key means a leak of
  *that* key alone (without the database) is useless, and a database leak
  alone (without the key) is useless. Same principle already used for email:
  `EMAIL_ENCRYPTION_KEY` and `EMAIL_BLIND_INDEX_KEY`
  (app/models/user.rb:36-68, via the `blind_index` gem, Gemfile:81) are
  separate keys for separate purposes so one leaking doesn't cascade into
  the other. The new key must be **its own environment variable**, distinct
  from `SECRET_KEY_BASE`, `EMAIL_ENCRYPTION_KEY`, and
  `EMAIL_BLIND_INDEX_KEY` — tentatively `SESSION_ID_HMAC_KEY`, following the
  same 256-bit-hex, `TEST_..._KEY` fallback, `self.foo_key_hex(env_test:)`
  pattern already established in `app/models/user.rb`.
- **Why HMAC-SHA256, not bcrypt/scrypt/argon2**: those algorithms are
  deliberately slow to resist brute-forcing a *low-entropy, human-chosen*
  secret (a password). A session id is 128 bits of `SecureRandom`, already
  infeasible to guess regardless of hash speed, and the lookup runs on every
  authenticated request, so a fast, standard, indexable keyed hash
  (`OpenSSL::HMAC`, or the `blind_index` gem's own hashing if it exposes it
  without requiring the full `attr_encrypted` DSL — check before assuming)
  is the right tool, not the wrong one made to feel more secure.
- **Why 128 bits of session id, not 256**: 128 bits is the OWASP Session
  Management Cheat Sheet's stated minimum for session identifiers, and is
  already what this codebase uses for the "remember me" token
  (`User.new_token`, app/models/user.rb:355, is `SecureRandom.urlsafe_base64`
  with its default 16-byte/128-bit length) and what Rack itself defaults to
  for its own session ids. 256 bits is the right size for a *symmetric
  encryption key* meant to stay secret and valuable for years, where you
  size up to keep a safety margin against a quantum computer's Grover's
  algorithm someday halving the effective search space. A session id is
  neither: it's a short-lived bearer value, replaced on every login, with
  128 bits (2^128 possible values) already far beyond any brute-force
  attack that will ever be practical. Reusing `User.new_token` for
  generation, rather than inventing a new call, is one line and keeps the
  precedent DRY.
- **What this buys us**: HMAC is one-way. Reading the database yields only
  hashes, which can't be inverted back to a working session id. Even
  obtaining *both* the HMAC key and the database doesn't let an attacker
  forge a new working session id, because they'd still need to already know
  the original random plaintext to compute a matching hash forward, and
  that plaintext was never stored anywhere except in the legitimate
  browser's cookie. This resists full server-side compromise (DB + this
  key), not just a `SECRET_KEY_BASE` leak, which is more than the original
  ask but costs little extra.
- **Honest limit of this protection**: separate keys defend against
  *partial* compromises — the database alone (SQL injection, a stolen
  backup) or one specific secret alone (a bug that discloses exactly
  `SECRET_KEY_BASE`, say). If the actual failure mode is "attacker reads
  the whole environment" (a dumped `.env`, a secrets-manager compromise, a
  container/memory dump), every key discussed here typically leaks
  together, and separating them buys nothing against that scenario
  specifically — though the attacker still needs the database too, since
  none of these keys alone reveal a working session id. That's not a flaw
  in this design so much as a boundary worth stating plainly: this raises
  the number of distinct things that must go wrong at once, it doesn't
  make a full infrastructure compromise survivable, and no low-complexity
  change here would.

## 6. What we're explicitly NOT doing (and why)

### 6.1. Not moving `session[:user_token]` (GitHub OAuth token) into the database

`SessionsController#omniauth_login` (app/controllers/sessions_controller.rb:166)
currently stores the live GitHub OAuth access token in `session[:user_token]`,
read back as `@session_user_token` in `setup_authentication_state` and used
by `SessionsHelper#github_user_can_push?` and `#github_user_projects`
(app/helpers/sessions_helper.rb) to call the GitHub API for the user.

This looked like a natural extension of the same idea, but it isn't, and we
considered and rejected it:

- The session id only ever needs to be **verified** ("does this match?"), so
  a one-way hash works, giving the strong DB-read-proof property in
  section 5.
- The GitHub token must be **recovered** in full: the app hands the raw
  token to Octokit to call GitHub's API. A one-way hash cannot protect
  something that must be reversible. The only protection available for it
  is encryption, which means some key, somewhere, turns the stored value
  back into a live, usable GitHub credential.
- That's the same shape of risk it already has today (a secret plus a
  stored value together are a usable credential), just relocated from
  "cookie + `SECRET_KEY_BASE`" to "database row + a new encryption key." It
  does not gain the "safe even if the key and the database both leak"
  property that section 5 gives the session id, because reversibility is
  required for the token to be useful at all.
- So moving it would add a new place where a live external credential is at
  risk under a combined DB+key compromise, in exchange only for no longer
  transmitting it to/storing it in the browser. That's a lateral trade-off,
  not a strict improvement, and conflates two changes with different
  security properties. Leave `user_token` in the cookie; revisit
  separately if ever justified on its own merits.

### 6.2. Not storing `github_name` redundantly

Already covered in section 3: it's derivable via `user_id` → `users`, so a
separate column would just be denormalization with no benefit.

### 6.3. Not using a slow/adaptive hash for the session id

Covered in section 5: bcrypt-style algorithms solve a different problem
(low-entropy secrets) and would only add latency to every authenticated
request.

### 6.4. Not building a self-service "log out everywhere" UI

The `rake sessions:revoke[user_id]` task in section 3 already covers the
operationally relevant case (an admin acting on a suspected-compromise
report), and password change already self-serves the case where the user
themselves takes action. A dedicated UI affordance for a user to revoke
their own other sessions would be real, separate code (a view, a
controller action, a translated string) for a case those two already
handle; not worth it unless it turns out users actually ask for it.

## 7. Known trade-off to keep in mind while planning

Today, `logged_in?` and everything gated on `@session_user_id` cost zero
database queries for anonymous requests, *and* a logged-in request that
never calls `current_user` also does zero queries, because the user id sits
directly in the cookie. Under this design, resolving the session id to a
user id requires one indexed lookup per request for every logged-in
request, even ones that never call `current_user`. Anonymous traffic is
unaffected. This is an inherent cost of moving authentication state
server-side and is what makes revocation possible; call it out explicitly
because AGENTS.md emphasizes this site's production load and attack
exposure.

A second, related cost: every successful login is currently free of
server-side storage (it only ever writes a cookie); under this design it
also writes a `login_sessions` row. A burst of successful logins (or of a
script that logs in repeatedly without ever logging out) now has a
storage/write cost it didn't have before, not just a read cost. This is
already bounded by two things this design already includes: Rack::Attack's
existing login throttling (`config/initializers/rack_attack.rb`), and the
cleanup job (section 3). Worth being deliberate that the cleanup job's
schedule needs to keep pace with the *shortest* relevant window — the
48-hour idle timeout, not just the 30-day absolute cap — so the table
doesn't grow unbounded between runs during sustained attack traffic; "a
daily job" almost certainly suffices, but this is worth confirming
explicitly during planning rather than assuming any schedule is fine.

## 8. Files and identifiers likely relevant to implementation

- `app/controllers/application_controller.rb` — `setup_authentication_state`,
  `update_session_timestamp`, `drop_unneeded_session_cookie`,
  `session_has_user_content?`, `try_remember_token_login`,
  `omit_session_cookie`, `SESSION_COOKIE_NAME`,
  `SESSION_BOOKKEEPING_KEYS`
- `app/helpers/sessions_helper.rb` — `log_in`, `log_out`, `current_user`,
  `logged_in?`, `remember`, `forget`, `SESSION_TTL`, `RESET_SESSION_TIMER`
- `app/controllers/sessions_controller.rb` — `create`, `destroy`,
  `omniauth_login`, `local_login_procedure`, `counter_fixation`
- `app/controllers/users_controller.rb` — `update` (one of today's two
  password-change paths; needs a `forget(user)` call, see section 3)
- `app/controllers/password_resets_controller.rb` — `update` (the other
  password-change path; same requirement)
- `app/lib/client_ip.rb` — existing helper for extracting the client IP
  through Fastly correctly; use it for the new `ip_address` column instead
  of calling `request.remote_ip` directly
- `config/initializers/rack_attack.rb` — existing login-attempt throttling,
  relevant to the write-load trade-off in section 7
- `app/models/user.rb` — `remember`, `forget`, `authenticated?`,
  `self.digest`, `self.new_token`, `remember_digest` column, and the
  existing key-management pattern (`DIGITS_OF_EMAIL_BLIND_INDEX_KEY`,
  `TEST_EMAIL_BLIND_INDEX_KEY`, `self.email_blind_index_key_hex`) to mirror
  for the new session HMAC key
- `config/initializers/session_store.rb` — current cookie store config and
  the documented (soon to be partly superseded) global-logout procedure
- `docs/secrets-policy.md` — secret rotation procedure; will need an update
  once a session table gives us a better global-logout mechanism
- `docs/cdn-cache-not-logged-in.md` — documents the invariant that anonymous
  requests must never receive a `Set-Cookie`; the new design must not
  regress this
- `test/integration/drop_session_cookie_test.rb` — pins the cookie-dropping
  behavior referenced above
- Gemfile: `blind_index` gem (already a dependency, used for email) — model
  for the keyed-hash approach in section 5
- Env vars: `SECRET_KEY_BASE`, `EMAIL_ENCRYPTION_KEY`,
  `EMAIL_BLIND_INDEX_KEY` (existing); a new one for the session HMAC key
  (tentatively `SESSION_ID_HMAC_KEY`)

## 9. Open questions for the implementation plan

- Exact table and column names.
- Whether to compute the HMAC via raw `OpenSSL::HMAC` or via a `blind_index`
  gem helper (needs checking the gem's public API).
- Digest column type: store as `bytea`/binary rather than hex or base64
  text, to avoid encoding mismatches at comparison time and save space.
- Exact idle-timeout/cleanup job design (mirroring
  `User.purge_unactivated_accounts` vs. a different schedule).
- Whether/how admins view the "currently logged in" list, and what fields
  it exposes.
- Exact mechanics of `try_remember_token_login` minting a new login-session
  row (section 3): does it reuse `SessionsHelper#log_in`, or need its own
  path? The password-change flow's "revoke all, then create one fresh row"
  (section 3) likely wants to share that same creation code path too.
- Exact interface for `rake sessions:revoke[user_id]` (section 3): argument
  validation, what it prints/logs, and whether it errors on an unknown
  user id or just deletes zero rows silently.
- Bigger, deliberately out of scope for now: `remember_digest`
  ("remember me") tokens have no expiration at all today — they're valid
  until an explicit logout/`forget` call. Adding `forget(user)` to
  password change (section 3) closes the one gap directly relevant to this
  project, but a stolen remember-me cookie is otherwise a standing,
  permanent credential regardless of this whole redesign. Giving remember
  tokens an absolute lifetime is a real, separate hardening step (a new
  column, a check in `try_remember_token_login`) — noted here because this
  review surfaced it, not because it's part of this project's scope.
