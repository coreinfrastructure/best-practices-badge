# Hardening Login Sessions: Proposed Steps 18, 19, and 20

<!-- SPDX-License-Identifier: (MIT OR CC-BY-3.0+) -->

## Goal

Revelation of this app's *application-level* secrets (`SECRET_KEY_BASE`,
`SESSION_ID_HMAC_KEY`, `EMAIL_ENCRYPTION_KEY`, and the like: everything
`HexKeyManagement`-style code reads from `ENV` for its own cryptographic
purposes) should by itself cause relatively little damage. Specifically:
**an attacker who has all of those, and nothing else, should not be able
to log in as a different user, or change data they couldn't already
change as themselves.**

That scope is deliberately narrower than "every environment variable".
The problem is that `DATABASE_URL` is one of this app's environment
variables (`docs/secrets-policy.md`'s own inventory lists it), and on
this app's current Heroku plans a leak of that value alone grants full
database read and write access, directly, with no cookie forgery
needed at all. We'll reduce risks from its exposure differently
in step 20. See "Honest limits, restated" below for the full reasoning
and what's being done about `DATABASE_URL` separately.

This is still a stronger goal than the original design doc set out to
meet, for the scope it does cover. `docs/login-session.md` section 5's
"Honest limit of this protection" paragraph explicitly resigned the
*original* design to "if the actual failure mode is 'attacker reads
the whole environment' ... separating [keys] buys nothing against that
scenario specifically." The two steps below close that gap for
application secrets specifically, for the two places it turned out to
still be open.

An attacker who gains access to the environment variables *can* send/receive
emails as the app. An attacker who gains access to the environment variables
and the full database can retrieve all encrypted email addresses of users
(necessarily, since we need to be able to get them).
However, that's still not enough to log in as an arbitrary user.

## What's already safe, checked rather than assumed

Two claims worth verifying before deciding what to fix, both checked
against this app's actual configuration and code, not assumed from
general Rails behavior:

- **CSRF via cross-site form submission is already closed.**
  `config/initializers/session_store.rb` sets no explicit `same_site`,
  so the session cookie gets Rails' default, `Lax`, in effect since
  Rails 6.1 (`config/application.rb:40` has `config.load_defaults 8.1`).
  Nothing in `config/` overrides it. A cross-site `<form method=post>`
  can't carry this app's session cookie at all, and
  `protect_from_forgery with: :exception`
  (app/controllers/application_controller.rb:71) still applies as
  defense-in-depth. (Out of scope for both steps below, since it's
  independent of any key leaking: a state-changing GET endpoint, if
  one existed, would stay vulnerable to ordinary cross-site navigation
  regardless of `SECRET_KEY_BASE`. Worth a separate look, not audited
  here.)
- **`LoginSession` itself is already safe against a `SECRET_KEY_BASE`
  leak alone.** `session_id_digest` is
  `HMAC-SHA256(SESSION_ID_HMAC_KEY, session_id)`, one-way, keyed with a
  second, independent secret (`docs/login-session.md` section 5).
  Forging a cookie with `SECRET_KEY_BASE` alone produces a
  `login_session_id` that matches no row. Impersonating an *existing*
  user needs `SESSION_ID_HMAC_KEY` too, and even then needs the
  database to already contain a matching row. See "Honest limits,
  restated" for exactly where this stops holding.
- **There is no way to smuggle session data in via a URL parameter
  instead of the real cookie.** `config/initializers/session_store.rb`
  configures `:cookie_store`, which reads and writes session data only
  through the actual `Cookie` HTTP header; it has no URL-param fallback
  (that was a Rails 2/3-era feature of the old
  `ActiveRecord::SessionStore`/`CacheStore`, not something
  `:cookie_store` has). Grepped the app for any code that reads an
  authentication-relevant identifier from `params` instead of
  `session`: none exists. `login_session_id` is read only via
  `session[:login_session_id]`
  (app/controllers/application_controller.rb:641);
  `pending_resubmission_id` the same, and it's specifically covered by
  step 15's own regression test asserting `?id=...` and
  `?pending_resubmission_id=...` query params are ignored entirely.

## Full audit: every session-cookie key, forgery reachability

Every `session[...] =` write in the app, and whether forging its value
(with `SECRET_KEY_BASE` alone) can harm a user other than the
attacker:

| Key | Used as | Forgery-reachable cross-user harm? |
|---|---|---|
| `login_session_id` | Looks up a `LoginSession` row | No (see above). |
| `pending_resubmission_id` | Looks up a `PendingResubmission` row | **Yes: step 18, below.** |
| `github_name` | String-compared against a repo's owner name, feeding `can_edit?` | **Yes: step 19, below.** |
| `user_token` | GitHub API access token, passed to Octokit | No: a forged/garbage value fails against GitHub's own servers, which we don't locally override; gated behind `current_user`, already safe. |
| `forwarding_url` | Redirect target on the next request | No: `redirect_back_or` passes `allow_other_host: false`, and it only affects the attacker's own subsequent redirect. |
| `locale` | Display language | Cosmetic only. |

Two gaps found, `pending_resubmission_id` and `github_name`. No third
instance of the pattern.

## Step 18: `pending_resubmissions` identified by a guessable id

Step 15 created the table `pending_resubmissions` for stashed form
resubmissions. `session[:pending_resubmission_id]` holds its `id`
directly, and `PendingResubmissionsController#show` looks the row up
with a plain `PendingResubmission.find_by(id: pending_id)`
(app/controllers/pending_resubmissions_controller.rb).

### The problem

A `SECRET_KEY_BASE` leak by itself is enough to forge an arbitrary
`pending_resubmissions` row's id into a victim's cookie. No other
secret and no database access is needed, because the Rails session
cookie's only protection is `SECRET_KEY_BASE`, and nothing else stands
between that cookie and the row it names.

This is the exact assumption step 15's own design already named as
the sole thing holding this up. From
`docs/login-session-implementation.md` section 15:
"`pending_resubmissions.id` is a plain sequential primary key, easily
guessed or enumerated; the *only* reason that's safe is that nothing
web-reachable ever accepts it as input; the lookup key comes
exclusively from this browser's own encrypted session cookie." That's
true against an attacker who doesn't control the server. It stops
being true the moment `SECRET_KEY_BASE` leaks, because at that point
the attacker *can* construct that cookie themselves, for any id they
choose.

Compare with `LoginSession`: `pending_resubmissions` has no equivalent
second layer at all. One secret, `SECRET_KEY_BASE`, is the entire
barrier.

**Severity stays modest regardless**, which is worth stating plainly
rather than overselling the fix: `ApplicationController::SENSITIVE_STASH_KEYS`
already excludes `password`, `password_confirmation`, and `email` from
any stash (step 15), so the worst direct disclosure is non-secret
project fields (which become public once saved anyway) or a user's
name/locale/notification preferences. The more concrete harm is
denial of service: `PendingResubmissionsController#show` destroys the
row on read regardless of who's asking (`pending.destroy # single-use`),
so an attacker who reaches a victim's row deletes their unsaved draft.
The worst exposure window is right after step 16's rollout, when every
logged-in user is bounced to login at once and `pending_resubmissions`
volume briefly spikes: exactly when guessing a small range of recent
sequential ids is most likely to land on something real.

### Proposed solution

Add a `hashed_random_id` column to `pending_resubmissions`, generate a
random token per resubmission, store the raw token in the cookie and
its digest in the new column, and look the row up by digest instead of
by `id`. This mirrors `LoginSession` deliberately: same shape of
problem (identify a row via a value that only ever travels in this
browser's own cookie), same solution.

**Use a keyed HMAC, matching `LoginSession.digest`, not a plain
hash.** A plain SHA-256 of 128 bits of `SecureRandom` is cryptographically
adequate against brute-forcing: there's no low-entropy secret here
the way there is with a password, so keying doesn't add brute-force
resistance. But brute-force resistance isn't why `LoginSession` uses a
keyed HMAC. Design doc section 5 gives the actual reason: "using a
dedicated key means a leak of *that* key alone (without the database)
is useless, and a database leak alone (without the key) is useless."
That forces two *independent* secrets to leak together, the same
principle already applied to `EMAIL_ENCRYPTION_KEY`/`EMAIL_BLIND_INDEX_KEY`.
A plain hash doesn't get that property for free.

More concretely: this codebase already has two different "digest a
random bearer token" patterns: `User.digest` (BCrypt, for
`remember_token`) and `LoginSession.digest` (keyed HMAC-SHA256, for
the session id). Section 5 already argues at length for HMAC-SHA256
over bcrypt specifically for "128 bits of `SecureRandom`, checked on
every request", which is exactly what this is. Introducing a third
pattern (unkeyed SHA-256) for the same conceptual problem is the kind
of duplication AGENTS.md's DRY principle argues against, when the
second pattern already fits and is already implemented and tested.
Reuse `LoginSession.digest`'s shape, with a **new, dedicated key**
(`PENDING_RESUBMISSION_HMAC_KEY` or similar) generated via the
existing `HexKeyManagement` module (`app/lib/hex_key_management.rb`)
rather than a fourth copy of that pattern (not `SESSION_ID_HMAC_KEY`
itself), per the design doc's own key-separation principle: one key,
one purpose, so leaking one doesn't cascade into the other.

### Implementation notes

- Generate the raw token with `SecureRandom.urlsafe_base64`, matching
  `User.new_token`'s existing 128-bit precedent, rather than inventing
  new size reasoning.
- `add_index :pending_resubmissions, :hashed_random_id, unique: true`,
  matching `login_sessions.session_id_digest`'s existing `unique: true`.
- This must *replace* the `id`-based lookup, not run alongside it.
  Keeping both paths alive would leave the weaker one exploitable.
- Rename `session[:pending_resubmission_id]` to something like
  `session[:pending_resubmission_token]`: once the session value is a
  raw random token rather than an id, keeping the old name
  reintroduces exactly the name/content mismatch step 15's own design
  went out of its way to avoid ("it's worth naming that plainly here,
  since it's easy to read this table's columns and wonder where
  `session[:pending_resubmission_id]` comes from"). Update
  `SessionsHelper::SESSION_KEYS_SURVIVING_RESET` to match.
- The existing regression test
  (`test 'a params-supplied id never shows or destroys another session's row'`
  in `test/controllers/pending_resubmissions_controller_test.rb`)
  covers a different threat (an id supplied via `params`, not a
  forged cookie) and needs no change.

## Step 19: `session[:github_name]` grants real edit authorization

### The problem

`SessionsHelper#current_user_is_github_owner?`
(app/helpers/sessions_helper.rb:214):

```ruby
def current_user_is_github_owner?(url)
  logged_in? && current_user.present? && current_user.provider == 'github' &&
    @session_github_name == get_github_owner(url)
end
```

feeds `can_current_user_edit_on_github?` (line 295:
`current_user_is_github_owner?(url) || github_user_can_push?(url)`),
which feeds `can_edit?`, the actual authorization check for editing a
project.

`github_user_can_push?` is already safe: it round-trips to the real
GitHub API with `session[:user_token]`, and GitHub itself verifies
push access. A forged token just fails there; we never trust it
locally.

`current_user_is_github_owner?` is not safe: it's a **pure local
string comparison** against `session[:github_name]`, which is only
ever set from `auth['info']['nickname']` at login
(sessions_controller.rb:185) and never re-verified against anything.
An attacker who (a) has `SECRET_KEY_BASE` and (b) is logged in as
*any* real GitHub-provider account of their own (no special
privileges needed) can forge their own cookie's `github_name` to
match the real owner name of *any* repo, say `"torvalds"`, and
`can_edit?` returns true for a project whose `repo_url` is
`github.com/torvalds/...`, without ever proving anything to GitHub.
That's edit access to someone else's project entry: an authorization
bypass, not just data disclosure, and worse than step 18's gap, not
equivalent to it.

### Proposed solution

Stop trusting `session[:github_name]` for authorization. Anchor to
`current_user.nickname` instead, which is already safe: it's read off
`current_user`, which is already gated behind `login_session_id`.

One wrinkle: `User.create_with_omniauth` sets `nickname` only at
account *creation* (app/models/user.rb:239); unlike
`session[:github_name]`, it's never refreshed on later logins today.
Refresh it on every GitHub login, and tell the user when it changes,
so a real GitHub username change is both reflected and visible rather
than silently going stale:

```ruby
# In SessionsController#omniauth_login, replacing the
# session[:github_name] = auth['info']['nickname'] line:
update_github_nickname(user, auth['info']['nickname'])
```

```ruby
# New private method, SessionsController.
# @param user [User] the user logging in
# @param new_nickname [String] GitHub nickname from this login's OAuth payload
# @return [void]
def update_github_nickname(user, new_nickname)
  new_nickname = new_nickname&.slice(0, User::MAX_NICKNAME_LENGTH_GITHUB)
  return if user.nickname == new_nickname

  old_nickname = user.nickname
  user.update(nickname: new_nickname)
  return if old_nickname.blank? # first login after account creation; nothing changed

  flash[:info] = t('sessions.github_nickname_changed',
                    old_nickname: old_nickname, new_nickname: new_nickname)
end
```

`user.update`, not `update!`: a nickname-update failure must never
block login itself. `flash[:info]` (not `flash[:success]`, which
`successful_login` already sets for "signed in") so both show; the
layout already renders every flash key
(`app/views/layouts/application.html.erb:62`).

Then in `SessionsHelper`:

```ruby
def current_user_is_github_owner?(url)
  logged_in? && current_user.present? && current_user.provider == 'github' &&
    current_user.nickname == get_github_owner(url)
end
```

Remove `session[:github_name]`, `@session_github_name`
(app/controllers/application_controller.rb:662, and its doc comment at
line 610), and the now-unused `SessionsHelper` reference at line 216,
entirely: don't leave a second, now-pointless copy of the same
information alongside the DB column.

### Implementation notes

- New locale key needed: `sessions.github_nickname_changed`, following
  this app's real-translation workflow (AGENTS.md), not a placeholder
  English string, the same requirement step 17 already applied to
  step 15's new strings.
- Test the rename path specifically: an existing GitHub user whose
  `auth['info']['nickname']` differs from their stored `nickname` sees
  the flash and gets `current_user.nickname` updated; a user whose
  nickname hasn't changed sees no flash; a brand-new user (nickname
  just set by `create_with_omniauth`) sees no flash either.
- Test the authorization fix directly: forging `github_name` (however
  a test simulates that) must have no effect once the code no longer
  reads it; `can_edit?` for a repo owned by someone else must depend
  only on `current_user.nickname` or `github_user_can_push?`.

## Step 20: daily `DATABASE_URL` rotation, to bound leak exposure time

### The problem, and what this step doesn't claim to solve

As established above, a leaked `DATABASE_URL` is unconditionally
severe: direct database read and write, no cookie or HMAC involved.
Steps 18 and 19 can't touch that, and neither can this one. What this
step buys is narrower and worth being precise about: it bounds how
long a *stale* leaked copy of `DATABASE_URL` (an old log line, a
forgotten backup, a stale secrets-manager snapshot) stays valid, by
rotating the credential daily. An attacker who steals the *live*
credential and uses it immediately is unaffected by any rotation
schedule. This closes the "found an old copy" leak shape, not the
"actively exploiting a fresh leak" one.

### Why CircleCI, and why not inside the app itself

`rake daily` (`lib/tasks/default.rake`) was the first place considered
and rejected: it runs inside the app's own dyno, using the app's own
config vars. Rotating `DATABASE_URL` from there would mean calling the
Heroku Platform API, which needs a Heroku credential capable of
modifying config vars: a *more* powerful secret than `DATABASE_URL`
itself, sitting in the exact environment this whole document is trying
to shrink the blast radius of. That's self-defeating: an attacker with
"all the env vars" would then also have the means to rotate
`DATABASE_URL` to a value of their own choosing.

This app already has the right isolated place for this: CircleCI's
`bestpractices-heroku-deploy` context, holding `HEROKU_API_KEY`. The
`deploy-only` executor's own comment already states the principle
this reuses: *"This is also the one job holding `HEROKU_API_KEY`...
so carrying less here is worth a second image."* Running rotation from
there keeps the Heroku-API-capable credential where it already lives,
isolated from the app's runtime, rather than adding a copy of it (or
something equally powerful) anywhere new.

### Proposed solution

Two new scheduled workflows, staging and production kept separate (so
either can be paused, rescheduled, or debugged independently), sharing
one parameterized job. Extract the existing Heroku CLI install (pinned
version, SHA-512 integrity check, caching, currently inlined only in
the `deploy` job, .circleci/config.yml:660-757) into a shared command,
the same way `prepare_ruby` already is, since a second job now needs
it too:

```yaml
commands:
  # ... existing prepare_ruby command ...
  install_heroku_cli:
    description: >
      Installs a pinned, integrity-checked Heroku CLI into $HOME,
      caching it by version. Extracted from the deploy job so a second
      job (credential rotation) doesn't carry a second copy of a
      supply-chain-security-relevant install step.
    steps:
      - run:
          name: Pin the Heroku CLI version
          command: |
            # ... unchanged from the current deploy job ...
      - restore_cache:
          keys:
          - heroku-cli-v1-{{ arch }}-{{ checksum "/tmp/heroku-cli-version" }}
      - run:
          name: Install Heroku CLI tools
          command: |
            # ... unchanged from the current deploy job ...
      - save_cache:
          key: heroku-cli-v1-{{ arch }}-{{ checksum "/tmp/heroku-cli-version" }}
          paths:
            - ~/heroku-cli
```

`deploy`'s own copy of these four steps is then replaced with a single
`- install_heroku_cli`.

```yaml
jobs:
  # ... existing jobs ...
  rotate-db-credentials:
    executor: deploy-only
    parameters:
      app:
        type: string
    steps:
      # No checkout, no .netrc/git remote setup: unlike deploy, this
      # touches no code and pushes nothing, so it needs neither.
      - install_heroku_cli
      - run:
          name: Rotate DATABASE_URL for << parameters.app >>
          command: |
            export PATH="$HOME/heroku-cli/bin:$PATH"
            # No --force: let Heroku wait (up to 30 minutes) for any
            # in-progress transaction to finish naturally rather than
            # killing connections outright. A routine daily rotation
            # has no reason to be disruptive.
            heroku pg:credentials:rotate \
              --app "<< parameters.app >>" \
              --confirm "<< parameters.app >>"

workflows:
  # ... existing build-deploy workflow, unchanged ...
  rotate-staging-db:
    when: pipeline.trigger_source == "scheduled_pipeline" and pipeline.schedule.name == "rotate-staging-db"
    jobs:
      - rotate-db-credentials:
          app: staging-bestpractices
          context: bestpractices-heroku-deploy
  rotate-production-db:
    when: pipeline.trigger_source == "scheduled_pipeline" and pipeline.schedule.name == "rotate-production-db"
    jobs:
      - rotate-db-credentials:
          app: production-bestpractices
          context: bestpractices-heroku-deploy
```

Each workflow's `when:` condition is doing real work, not decoration:
a Scheduled Pipeline trigger fires the whole pipeline, and by default
every workflow in it would run. Without these conditions, an ordinary
push-triggered pipeline would *also* try to run both rotation
workflows on every commit. Gating each on its own
`pipeline.schedule.name` means a normal push runs only `build-deploy`
(neither `pipeline.trigger_source` nor `pipeline.schedule.name` match),
and each scheduled trigger runs only its own rotation, never the
other's.

### Implementation notes

- Two CircleCI Scheduled Triggers need creating via the CircleCI UI
  (Project Settings -> Triggers) or API. This is configuration, not
  code, and isn't in `.circleci/config.yml`. Name them
  `rotate-staging-db` and `rotate-production-db` to match the `when:`
  conditions above, each set to run daily, each targeting whichever
  branch's config this app treats as canonical (`main`, given staging
  and production are reached only by fast-forwarding it, so the
  config is identical across all three at any given time).
- **Rotation frequency lives entirely in that trigger configuration,
  not in code.** Starting at daily costs nothing beyond what Heroku's
  own baseline dyno cycling already costs (every dyno restarts at
  least once every 24 hours regardless, per Heroku Dev Center's "Dyno
  Restarts" article). Moving to 12h or 6h later is a dashboard change,
  not a deploy, but it multiplies the release-phase overhead
  (`db:migrate` re-runs on every config-var-triggered release,
  harmless since idempotent, but not free) for a narrower benefit:
  it only helps a stale-leak that's exploited within hours rather
  than a day, and does nothing against an immediately-exploited one at
  any frequency. Start at daily; treat faster rotation as a knob to
  revisit only if that narrower case is a real enough worry to justify
  the added disruption.
- Needs a failure notification (CircleCI supports notifying on a
  failed scheduled pipeline): a silently-failing rotation is worse
  than no rotation, since it would look like protection that isn't
  actually happening.
- Update `docs/secrets-policy.md`'s `DATABASE_URL` rotation entry to
  note that daily rotation is now automated, alongside (not replacing)
  the existing manual `heroku pg:credentials:rotate` incident-response
  procedure for a suspected exposure that can't wait for the next
  scheduled run.

## Honest limits, restated

**`DATABASE_URL` is the boundary this doc cannot move, and it's worth
being precise about why.** It's listed in `docs/secrets-policy.md`'s
own secrets inventory alongside `SECRET_KEY_BASE` and the rest,
equally "an environment variable," equally capable of leaking the same
way any of them could. But it isn't the same kind of thing: every
other key in that table exists to let *this app's code* verify or
decrypt something, one narrow purpose each, which is exactly the
property steps 18 and 19 rely on (a leaked `SESSION_ID_HMAC_KEY` alone
can't manufacture a database row). `DATABASE_URL` grants direct
database access, full stop. On this app's current Heroku plans
(`essential-1` staging, `Standard 0` production), that means an
attacker with it can read `users.encrypted_email` for everyone
(needing `EMAIL_ENCRYPTION_KEY` too, to decrypt it, but that's just
another environment variable away), or run
`UPDATE users SET role = 'admin' WHERE id = ...` (`User#admin?` is
`role == 'admin'`) directly. Neither of those needs any cookie, any
session, any HMAC: they bypass the entire login-session design this
whole branch built. No key-separation scheme changes that; it isn't a
gap in this design, it's a different design question (database access
control) that a session-cookie hardening doc can't answer.

Two direct mitigations were considered for `DATABASE_URL` specifically
and set aside as impractical for this app right now: restricting
database network access to known IPs (Heroku's IP-allowlist feature
needs confirming per-plan, and even where available, this app's
dynos, standard Common Runtime rather than Private Spaces, don't have
a stable outbound IP to allowlist without adding a static-IP add-on),
and a least-privilege database role for the app separate from a
migration/admin role (real, but it only blocks structural damage such
as `DROP TABLE` or schema changes, not the two things this doc
actually cares about, since the app's own normal operation already
needs to read `users.encrypted_email` and set `role`). A practical
middle ground, proposed as step 20 below: **daily automated
`DATABASE_URL` rotation** (`heroku pg:credentials:rotate`, already
documented in `docs/secrets-policy.md` as a manual incident-response
step). This is cheap specifically because `DATABASE_URL` is cheap to
rotate, unlike `SECRET_KEY_BASE` (forces a global logout) or
`EMAIL_ENCRYPTION_KEY` (needs a maintenance-mode re-encryption pass);
it bounds how long a *stale, already-leaked* copy (an old log line, a
forgotten backup, a stale secrets-manager snapshot) stays valid, which
is a real and common leak shape. It does nothing for an attacker who
steals the live credential and uses it immediately: rotation limits
exposure *time*, it doesn't prevent exposure.

So, precisely: steps 18 and 19 *prevent* the gap for `SECRET_KEY_BASE`
(or any other application secret) leaking *without* `DATABASE_URL`,
whatever that leak's actual shape turns out to be (a narrower-scoped
bug that dumps specific `ENV` reads rather than a full config-var
export, for instance). Step 20 does something weaker but still real
for `DATABASE_URL` itself: it *bounds*, rather than prevents, how long
a leaked copy stays useful. Nothing here makes a live,
actively-exploited `DATABASE_URL` leak survivable. That's the honest
scope of what "even full revelation of the environment variables" can
mean for this app today.

## Implementation notes for all three steps

Separate concerns, separate mechanisms, separate commits: step 18
touches `pending_resubmissions` and its controller; step 19 touches
`SessionsController`/`SessionsHelper`/`ApplicationController` and adds
one new locale key; step 20 touches only `.circleci/config.yml` and
`docs/secrets-policy.md`, and needs the two CircleCI Scheduled
Triggers configured outside the repo. Land and test them
independently.
