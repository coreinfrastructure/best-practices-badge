# Hardening Login Sessions

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

This document describes our goal for hardening login sessions, by
using session IDs in the session cookie instead of directly storing the
user id in the session cookie.

## 1. Problem

`config/initializers/session_store.rb` uses `:cookie_store`, which
by itself is fine. Curreently `session[:user_id]`
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

The new table stores a **keyed hash (HMAC) of the session id, not the
session id itself**, so that an attacker who can only read the database
(e.g., via SQL injection, a stolen backup, or insider access) *also*
gains nothing usable. See section 5.

Side benefit: the new table gives us a place to see currently logged-in
users, and a simple way to revoke one session (delete its row) or force a
global logout of a specific user (delete that user's table rows)
without touching `SECRET_KEY_BASE`.

## 3. What we ARE doing

- Add a new table, `login_sessions` (model `LoginSession`). Not just
  `sessions`/`Session`: this app already has
  `app/controllers/sessions_controller.rb` handling login (`create`) and
  logout (`destroy`), so a new admin-listing controller can't also be
  named `SessionsController`; Rails doesn't allow two same-named
  controllers. `login_sessions` also stays clear of the *existing,
  unrelated* use of "session" throughout this codebase for the Rack/
  cookie-store session (`session[:...]`, `SessionsHelper`,
  `config/initializers/session_store.rb`): a `login_sessions` row is a
  persisted record of one login, not the request-scoped cookie session
  itself.
- The table has roughly these columns:
  - a keyed-hash column of the session id (see section 5): unique, indexed,
    this is the lookup key (hashed so attackers who can read the database
    cannot log in to that session). Store it as a standard `string`
    (hex-encoded), not `bytea`. `bytea` is PostgreSQL-specific, not
    portable standard SQL, and every existing digest column in this
    codebase (`activation_digest`, `password_digest`, `remember_digest`,
    `reset_digest`, all in `db/schema.rb`) is already `t.string`. At this
    table's scale, the size difference between a 32-byte binary value and
    its 64-character hex form is a few tens of bytes per row, immaterial
    for lookup speed or storage, so there's no real trade-off to make:
    matching the existing convention and staying on portable SQL wins on
    both counts.
  - `user_id` (foreign key to `users`)
  - `created_at` (also used for the absolute session age cap, below),
    essentially the login time for this session.
  - `last_used_at` (or reuse `updated_at`): read on every logged-in
    request as part of the same row fetch that resolves `user_id` (no
    extra query; see below), but **written at most once per
    `RESET_SESSION_TIMER` (1 hour) per active user, not once per
    request**, reusing the exact throttle `update_session_timestamp`
    already implements today for the cookie, just retargeted at this
    column. Needed for two things the absolute cap (`created_at`) can't
    give us on its own: letting the cleanup job reap idle/abandoned rows
    around the existing 48-hour window instead of waiting up to 30 days,
    and giving the "who's logged in" admin view (section 2) a real
    recency signal instead of just a login timestamp. `session[:time_last_used]`
    goes away from the cookie entirely; this column is now the sole
    source of truth for it.
  - `ip_address` and the full `User-Agent` request header string, both
    recorded once at creation, purely observational (no enforcement). Gives real forensic
    value after an incident and makes the "see who's logged in" admin view
    (section 2) show more than opaque ids and timestamps, for the cost of
    two columns. Worth noting: today the app only ever uses the client IP
    transiently (Rack::Attack throttling, the OAuth-failure log line in
    `SessionsController#failure`) via the existing `ClientIp`
    (`app/lib/client_ip.rb`) helper; nothing persists it. This column is a
    genuinely new, if small, category of stored personal data, not an
    extension of an existing pattern. It's bounded automatically by the
    row's own lifecycle (deleted on logout, the absolute cap, or idle
    cleanup below), so there's no separate retention question to solve,
    but it's worth being deliberate about, not just "cheap so why not."
    Use the existing `ClientIp` helper for extraction rather than
    `request.remote_ip` directly, for consistency with the rest of the app.
- On login, generate a large random session id (128 bits; see the note on
  bit length below), store its keyed hash plus `user_id` in the new table,
  and put the raw random id in the (still `cookie_store`-based) session
  cookie in place of `user_id`/`time_last_used`. This does not change what
  else lives in that cookie (`forwarding_url`, `locale`, `user_token`,
  `github_name`, flash); see section 6.1 on why `user_token` stays put.
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
  same way. That single row fetch also returns `last_used_at`, so the
  48-hour idle-timeout check (today: compare `session[:time_last_used]`
  against `SESSION_TTL`) costs nothing extra to move server-side: it's the
  same query, just reading one more column from a row we already fetched.
  `current_user`'s memoization (`SessionsHelper#current_user`,
  app/helpers/sessions_helper.rb:70) is unaffected. `update_session_timestamp`
  (app/controllers/application_controller.rb:658) keeps its existing
  throttle logic unchanged; it now writes `last_used_at` on the row
  instead of `session[:time_last_used]` in the cookie, still at most once
  per `RESET_SESSION_TIMER`, not once per request.
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
- A rake task, e.g. `rake login_sessions:revoke[user_id]`, that deletes every
  `login_sessions` row for the given user id. Same `delete_all` call as the
  password-change flow above, exposed as an ops/incident-response tool: an
  admin can kill a specific user's sessions on report of suspected
  compromise, without waiting on that user to change their password. A few
  lines given the delete logic already exists for password change.
- An admin-only page listing every row in `login_sessions`, at
  `GET /:locale/login_sessions` (an `index` action on a
  `LoginSessionsController`): a plain RESTful route named after the
  resource, matching this app's i18n URL convention, rather than an
  invented verb-phrase path like `/logged_in`. This also matches how
  admin-facing listings are conventionally named elsewhere (Django's
  built-in admin, ActiveAdmin, RailsAdmin all name a resource's admin
  listing after the resource itself). Gated the same way other
  admin-only behavior already is in this codebase:
  an inline `current_user&.admin?` check (see `UsersController`,
  app/controllers/users_controller.rb:45,69,112,189), not a dedicated
  `admin` namespace or before_action, since none exists here yet. Shows
  every column: `user_id` (as a link to the user), `ip_address`, the full
  `User-Agent` string, `created_at`, `last_used_at`. Paginate with `pagy`,
  matching its existing use in `UsersController`/`ProjectsController`,
  since this list can grow to one row per currently-active session.
  - **The session-id hash column is shown truncated**: the first several
    hex characters plus `...`, not the full digest. This is a *display*
    choice, not a security one: per section 5, the digest is one-way, so
    showing the *entire* hash would still reveal nothing usable to log in
    with (the actual bearer credential is the raw session id, which never
    reaches the server again after the cookie was issued). Truncating is
    purely so the admin has a short, still-effectively-unique label to
    reference a specific row by (the same idea as a truncated git commit
    SHA), instead of a 64-character string nobody can visually
    distinguish from another at a glance.
  - **`User-Agent` is attacker-controlled input rendered to an admin
    audience**, a real stored-XSS vector if it were ever output
    unescaped. Standard ERB (`<%= %>`) auto-escapes by default, which is
    sufficient; this is a reminder to never use `raw`, `html_safe`, or
    `<%== %>` on this column specifically, not a call for new escaping
    machinery.
- No `github_name` column on the new table: it's one join away via `user_id`
  to `users`, and duplicating it would violate 3NF for no benefit.
- Clean up expired/stale rows the same way `User.purge_unactivated_accounts`
  (app/models/user.rb:376) is cleaned up: as one more step inside the
  existing `task daily` (`lib/tasks/default.rake:1758`), not a new
  solid_queue recurring job. Checked: `config/recurring.yml` exists but is
  entirely commented-out example content, unused; the real mechanism for
  this app's daily/monthly maintenance is `rake daily`/`rake monthly`,
  triggered externally by a scheduler (Heroku Scheduler, per that task's
  own comment), and `purge_unactivated_accounts` is already invoked from
  inside `task daily`. Daily cadence comfortably keeps pace with the
  48-hour idle window from above (an abandoned row lives at most about
  72 hours: the 48-hour idle window plus up to 24 hours until the next
  daily run).

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
    cookies, or requests: they'd work identically from a rake task or
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
  `EMAIL_BLIND_INDEX_KEY` (tentatively `SESSION_ID_HMAC_KEY`), following the
  same 256-bit-hex, `TEST_..._KEY` fallback, `self.foo_key_hex(env_test:)`
  pattern already established in `app/models/user.rb`.
- **Why HMAC-SHA256, not bcrypt/scrypt/argon2**: those algorithms are
  deliberately slow to resist brute-forcing a *low-entropy, human-chosen*
  secret (a password). A session id is 128 bits of `SecureRandom`, already
  infeasible to guess regardless of hash speed, and the lookup runs on every
  authenticated request, so a fast, standard, indexable keyed hash
  (`OpenSSL::HMAC`) is the right tool, not the wrong one made to feel more
  secure. This also rules out the `blind_index` gem's own hashing for this
  column: checked its source (`blind_index-2.8.1/lib/blind_index.rb`), and
  `BlindIndex.generate_bidx` only offers `argon2id` (its default), `argon2i`,
  `scrypt`, or `pbkdf2_sha256`, the exact family of deliberately-slow
  algorithms this bullet is arguing against, with no fast-HMAC mode at all.
  This app's own `blind_index :email` call (app/models/user.rb:80) uses that
  default, `argon2id`, which is the right choice for a guessable email
  address and the wrong one for an unguessable random session id checked on
  every request. See section 9 for the full comparison.
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
  *partial* compromises: the database alone (SQL injection, a stolen
  backup) or one specific secret alone (a bug that discloses exactly
  `SECRET_KEY_BASE`, say). If the actual failure mode is "attacker reads
  the whole environment" (a dumped `.env`, a secrets-manager compromise, a
  container/memory dump), every key discussed here typically leaks
  together, and separating them buys nothing against that scenario
  specifically, though the attacker still needs the database too, since
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

The `rake login_sessions:revoke[user_id]` task in section 3 already covers the
operationally relevant case (an admin acting on a suspected-compromise
report), and password change already self-serves the case where the user
themselves takes action. A dedicated UI affordance for a user to revoke
their own other sessions would be real, separate code (a view, a
controller action, a translated string) for a case those two already
handle; not worth it unless it turns out users actually ask for it.

### 6.5. Not giving `remember_digest` ("remember me") tokens an absolute expiration

`remember_digest` tokens have no expiration at all today; they're valid
until an explicit logout or `forget` call. Adding `forget(user)` to
password change (section 3) closes the one gap directly relevant to this
project, but a stolen remember-me cookie is otherwise a standing,
permanent credential regardless of this whole redesign, and we are
deliberately leaving that as-is here. Giving remember tokens an absolute
lifetime is a real, separate hardening step (a new column, a check in
`try_remember_token_login`); it's out of scope for this project, which is
about the `SECRET_KEY_BASE`/database-read exposure of `user_id`, not about
remember-me's own token lifetime. Noted here, deliberately, because this
review surfaced it and it's worth a future project on its own merits, not
because leaving it unchanged is an oversight.

We don't expire passwords, so it seems consistent that we don't normally
expire these either.

### 6.6. Not reusing Rack's own bookkeeping session id

It's tempting: Rack already puts a random `session_id` into the session
hash on every request (`SESSION_BOOKKEEPING_KEYS`,
application_controller.rb:45, already names it), so why generate a
second random value instead of reusing that one as the `login_sessions`
lookup key? Checked Rails' own cookie-store source
(`actionpack-8.1.3.1/lib/action_dispatch/middleware/session/cookie_store.rb`)
rather than assuming. One finding there is decisive on its own; the other
two are weaker and shouldn't be read as carrying equal weight.

**The decisive reason**: `delete_session` regenerates this id on every
`reset_session` call: `new_sid = generate_sid unless options[:drop]`.
This app calls `reset_session` for reasons unrelated to a login session
starting or ending: `SessionsController#counter_fixation` calls it
unconditionally at the top of *every* `POST /login`, success or failure
(app/controllers/sessions_controller.rb:138), and
`setup_authentication_state` calls it on idle-timeout expiry. Keying
`login_sessions` off this value would mean unrelated `reset_session`
calls elsewhere in the app silently rotate the very value a row's digest
depends on, orphaning it, for events that have nothing to do with our
login lifecycle. This alone rules it out; the two points below are
context, not additional independent reasons.

Two things that do *not*, by themselves, distinguish this from minting
our own token, worth naming so a future reader doesn't mistake them for
part of the case:

- It's stored as a plain key inside the same encrypted cookie payload as
  everything else (`persistent_session_id!`:
  `data["session_id"] ||= sid || generate_sid.public_id`). That's true,
  but it's equally true of a `login_session_id` we generate ourselves:
  under `:cookie_store` there is only one cookie, and whatever holds the
  id, ours or Rack's, ends up in that same encrypted blob. This fact
  doesn't favor either option.
- This codebase's own `SESSION_BOOKKEEPING_KEYS` already treats this key
  as *not real content* (existence-checked only, to decide whether the
  cookie can be dropped for CDN caching, never read for its value
  anywhere in this app). That's a genuine signal about this app's own
  intent, that the key is Rack-internal plumbing rather than data meant
  to be consumed, but it's a convention, not a technical barrier; it
  wouldn't by itself have stopped the reuse from working if the rotation
  problem above didn't already rule it out.

Minting our own token (`User.new_token`, already used for the "remember
me" token, section 5) costs one line and gives a value with a lifecycle
we fully control: created exactly at login, destroyed exactly at
logout/revocation, immune to `reset_session` calls that happen for
unrelated reasons elsewhere in the app.

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

That read costs nothing extra to also carry `last_used_at`, but the write
side is a separate question: raised and resolved during review, worth
recording so it doesn't need re-deriving. Naively updating `last_used_at`
on every logged-in request would turn a read-only trade-off into a
write on every logged-in request too, real added load for no benefit.
Section 3 avoids this by keeping the exact throttle
`update_session_timestamp` already uses today (`RESET_SESSION_TIMER`,
1 hour): the column is written at most once per active user per hour,
not once per request, identical in shape to the cookie write it
replaces.

A second, related cost: every successful login is currently free of
server-side storage (it only ever writes a cookie); under this design it
also writes a `login_sessions` row. A burst of successful logins (or of a
script that logs in repeatedly without ever logging out) now has a
storage/write cost it didn't have before, not just a read cost. This
extends beyond explicit logins too: a silent remember-me restoration
(section 3's `try_remember_token_login` bullet) now writes a row as
well, triggered by whatever request happens to be the next one from a
browser holding a valid remember-me cookie, not only `POST /login`. This
isn't a new attacker capability worth much weight on its own: reaching
this path at all requires already possessing a working
`remember_token`/`user_id` pair, a bcrypt-verified secret an attacker
can only replay from a prior theft, never manufacture or guess: the same
precondition that already grants full account access regardless of this
project. It's a minor added write cost on an already-narrow, already
accepted scenario (section 6.5), not a fresh path to abuse. To the
extent it's worth bounding at all, `rack_attack.rb`'s two general
per-IP throttles already do, since they apply to every request
regardless of path: `req/ip` (600 per 5 minutes) and `nonbadge_req/ip`
(31 per 15 seconds), both production-only. Those, together with the
cleanup job (section 3), are what bound this cost. Worth being
deliberate that the cleanup job's schedule needs to keep pace with the
*shortest* relevant window (the 48-hour idle timeout, not just the
30-day absolute cap), so the table doesn't grow unbounded between runs
during sustained attack traffic; "a daily job" almost certainly
suffices, but this is worth confirming explicitly during planning
rather than assuming any schedule is fine.

## 8. Files and identifiers likely relevant to implementation

- `app/controllers/application_controller.rb`: `setup_authentication_state`,
  `update_session_timestamp`, `drop_unneeded_session_cookie`,
  `session_has_user_content?`, `try_remember_token_login`,
  `omit_session_cookie`, `SESSION_COOKIE_NAME`,
  `SESSION_BOOKKEEPING_KEYS`
- `app/helpers/sessions_helper.rb`: `log_in`, `log_out`, `current_user`,
  `logged_in?`, `remember`, `forget`, `SESSION_TTL`, `RESET_SESSION_TIMER`
- `app/controllers/sessions_controller.rb`: `create`, `destroy`,
  `omniauth_login`, `local_login_procedure`, `counter_fixation`
- `app/controllers/users_controller.rb`: `update` (one of today's two
  password-change paths; needs a `forget(user)` call, see section 3)
- `app/controllers/password_resets_controller.rb`: `update` (the other
  password-change path; same requirement)
- `app/lib/client_ip.rb`: existing helper for extracting the client IP
  through Fastly correctly; use it for the new `ip_address` column instead
  of calling `request.remote_ip` directly
- `config/initializers/rack_attack.rb`: existing login-attempt throttling,
  relevant to the write-load trade-off in section 7
- `app/models/user.rb`: `remember`, `forget`, `authenticated?`,
  `self.digest`, `self.new_token`, `remember_digest` column, and the
  existing key-management pattern (`DIGITS_OF_EMAIL_BLIND_INDEX_KEY`,
  `TEST_EMAIL_BLIND_INDEX_KEY`, `self.email_blind_index_key_hex`) to mirror
  for the new session HMAC key
- `config/initializers/session_store.rb`: current cookie store config and
  the documented (soon to be partly superseded) global-logout procedure
- `docs/secrets-policy.md`: secret rotation procedure; will need an update
  once a session table gives us a better global-logout mechanism
- `docs/cdn-cache-not-logged-in.md`: documents the invariant that anonymous
  requests must never receive a `Set-Cookie`; the new design must not
  regress this
- `test/integration/drop_session_cookie_test.rb`: pins the cookie-dropping
  behavior referenced above
- Gemfile: `blind_index` gem (already a dependency, used for email), the
  model for the keyed-hash approach in section 5
- Env vars: `SECRET_KEY_BASE`, `EMAIL_ENCRYPTION_KEY`,
  `EMAIL_BLIND_INDEX_KEY` (existing); a new one for the session HMAC key
  (tentatively `SESSION_ID_HMAC_KEY`)

## 9. Open questions for the implementation plan

Here were some open questions that we believe are resolved
(see the "recommended" sections for each):

- Exact column name for the session-id hash (the table name itself,
  `login_sessions`, and its other columns are already settled in
  section 3).
  - `session_id_digest`: matches this codebase's existing `_digest`
    suffix convention exactly (`activation_digest`, `password_digest`,
    `remember_digest`, `reset_digest`, all in `db/schema.rb`), so it
    reads as "obviously the same kind of thing" to anyone who already
    knows the `User` model. Slight downside: "digest" doesn't by itself
    say *which* digest algorithm, but neither do the existing ones.
  - `session_id_hash`: more generic, immediately clear to a reader
    unfamiliar with this app's specific naming habit. Downside: breaks
    from the `_digest` convention already used four times in this same
    codebase for no real gain.
  - `hashed_session_id`: reads naturally in a sentence. Downside: a third
    naming style next to the two above, with no advantage over either.
  - **Recommended: `session_id_digest`.** It matches the *dominant*
    existing pattern (four uses, not one), and semantically it's the
    closer match: `_digest` in this codebase already means "one-way
    transform of a secret-like value, stored so the plaintext is never
    retained," exactly our case, whereas `_hash` is used once
    (`forbidden_hash`) for a different concept (checking membership in a
    public breached-password corpus, not protecting a value of ours).

- Whether to compute the HMAC via raw `OpenSSL::HMAC` or via a `blind_index`
  gem helper (needs checking the gem's public API; see section 5).
  - Raw `OpenSSL::HMAC`: a one-line stdlib call
    (`OpenSSL::HMAC.hexdigest('SHA256', key, session_id)`), no dependency
    on `blind_index`'s attribute-level machinery, which is built around
    pairing a hash with an `attr_encrypted` attribute we don't have here
    (we never need to decrypt the session id back out).
  - The `blind_index` gem's own hashing, if it exposes a plain function
    without requiring the full encrypted-attribute DSL: reuses the exact
    already-vetted, already-tested code path used for the email blind
    index, maximizing consistency with existing infrastructure per
    AGENTS.md.
  - **Recommended: raw `OpenSSL::HMAC`, now confirmed, not just
    suspected.** Read the gem's source
    (`blind_index-2.8.1/lib/blind_index.rb`): `BlindIndex.generate_bidx`
    *is* public and callable standalone, so the "unverified" downside
    above turned out not to apply, but it only implements `argon2id`
    (its default), `argon2i`, `scrypt`, and `pbkdf2_sha256`, the exact
    family of deliberately-slow algorithms section 5 argues against, with
    no fast-HMAC mode. Confirmed this app's own `blind_index :email` call
    (app/models/user.rb:80) takes that `argon2id` default, correct for a
    guessable email address, wrong for our unguessable session id checked
    on every request. The gem is the wrong tool here, not just an
    unexplored one.

- Exact idle-timeout/cleanup job design (mirroring
  `User.purge_unactivated_accounts` vs. a different schedule).
  - **Recommended: mirror the *real*
    mechanism instead of the one this document assumed.** Checked how
    `purge_unactivated_accounts` actually runs: not solid_queue at all.
    `config/recurring.yml` is entirely commented-out example content,
    unused. The actual mechanism is `task daily` in
    `lib/tasks/default.rake`, triggered externally by a scheduler (Heroku
    Scheduler, per that task's own comment), and
    `purge_unactivated_accounts` is already invoked right inside it. Add
    the `login_sessions` cleanup as one more step in that same task: no
    new scheduling infrastructure at all, and daily cadence already keeps
    pace with the 48-hour window (an abandoned row lives at most about
    72 hours). Section 3 has been corrected to reflect this.

- How many hex characters to truncate the session-id hash to in the
  `login_sessions` admin listing (section 3): enough to be
  effectively-unique for eyeballing, short enough to be a clean label.
  This is cosmetic, not a security decision (section 3), so "wrong" just
  means "occasionally two rows look alike at a glance," self-resolved by
  the adjacent `user_id`/`created_at` columns.
  - 8 characters: compact; at this table's realistic scale (concurrent
    sessions, not millions of rows), visually-identical prefixes across
    different rows are unlikely.
  - 12 characters: lower odds of two rows sharing a visible prefix as the
    table grows, at the cost of a slightly longer label.
  - Match git's familiar 7-character abbreviation: instantly recognizable
    to anyone used to short SHAs. Downside: git's default works because
    git auto-lengthens an abbreviation when it would collide; we'd have
    no equivalent safety net, so borrowing "7" alone borrows the number
    without the mechanism that makes it safe for git.
  - **Recommended: 9 characters plus `...`, matching existing precedent
    in this exact codebase.** `app/views/unsubscribe/edit.html.erb:27`
    already does exactly this for a different security-relevant token:
    `"#{@token[0..8]}..."`, read-only, for human recognition only, never
    resubmitted. No reason to invent a different length or style when
    this app already has one.

- Exact mechanics of `try_remember_token_login` minting a new login-session
  row (section 3): does it reuse `SessionsHelper#log_in`, or need its own
  path? The password-change flow's "revoke all, then create one fresh row"
  (section 3) likely wants to share that same creation code path too.
  - Reuse `log_in` directly: one entry point for "establish a session,"
    matching this project's DRY/minimal-code emphasis (AGENTS.md); any
    future change to session creation only needs to happen once.
  - Extract a smaller shared method (e.g. `create_login_session(user)`)
    used by both `log_in` and `try_remember_token_login`, leaving
    `log_in`'s locale/forwarding-url side effects out of the silent
    remember-me path: avoids duplicating the security-relevant row
    creation while not dragging in login-specific side effects.
    Downside: one more small private method, marginally more indirection
    than a single shared entry point.
  - **Recommended: reuse `log_in` directly; the "downside" listed for it
    doesn't survive reading the actual code.** Read
    `try_remember_token_login` in full
    (app/controllers/application_controller.rb:729-749): it *already*
    duplicates `log_in`'s `session[:user_id] = user.id`,
    `session[:time_last_used] = ...`, and, tellingly,
    `I18n.locale = user.preferred_locale.to_sym`, nearly verbatim. The
    locale switch this bullet worried about "may not be wanted" is
    already happening today, independently, in both places; reusing
    `log_in` removes a duplication that already exists rather than
    introducing new behavior. The one genuine difference is `log_in`'s
    trailing `forwarding_url` relocalization, which `try_remember_token_login`
    currently skips; that looks like a latent gap rather than an
    intentional difference; a user whose session lapsed mid-visit and
    gets silently restored via remember-me should arguably get the same
    forwarding treatment as one who explicitly re-logged-in. Reusing
    `log_in` likely fixes that gap as a side effect, not a risk.

- Exact interface for `rake login_sessions:revoke[user_id]` (section 3): argument
  validation, what it prints/logs, and whether it errors on an unknown
  user id or just deletes zero rows silently.
  - Fail loudly on an unknown user id: matches this codebase's stated
    preference for fail-fast checks over silent success (AGENTS.md), and
    catches a likely typo immediately, important since this tool exists
    specifically for urgent, possibly mid-incident use.
  - Succeed silently with zero rows deleted, treating "no such user" the
    same as "user exists, no active sessions": simpler, one code path.
    Downside: masks a pasted-wrong-id typo as a false success, in exactly
    the scenario (an admin urgently responding to a suspected compromise)
    where believing you've revoked sessions when you haven't is worst.
  - **Recommended: fail loudly, matching two existing precedents in this
    exact codebase, not just general philosophy.** `UsersController#destroy`
    (app/controllers/users_controller.rb:344) deliberately uses
    `User.find` over `find_by`, with the comment "Exception raised if not
    found," for the same shape of action (an admin operating on a
    specific user id). Separately, the existing
    `generate_unsubscribe_url` rake task
    (`lib/tasks/default.rake:2207`) validates its argument explicitly and
    calls `puts` plus `exit 1` with a usage message on bad input, rather
    than continuing silently. Mirror both: validate the argument is
    present, use `User.find(user_id)` (raises `ActiveRecord::RecordNotFound`
    if missing) or an equivalent explicit check with a clear message and
    `exit 1`.
