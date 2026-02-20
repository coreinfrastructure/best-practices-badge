# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Be sure to restart your server when you modify this file.

# FORCING A GLOBAL LOGOUT (invalidating all active sessions at once):
#
# Option 1 — rotate SECRET_KEY_BASE (most natural for operators):
#   Change the value of the SECRET_KEY_BASE environment variable and redeploy.
#   Rails derives all cookie signing and encryption keys from secret_key_base,
#   so every existing session and remember-token cookie becomes undecryptable
#   and is silently treated as absent. All users are logged out immediately.
#   This is the preferred approach because it requires no code change.
#
# Option 2 — rename the cookie key:
#   Change '_BadgeApp_session' below to a new name (e.g. '_BadgeApp_session_v2')
#   and deploy. Browsers send the old cookie name; the server looks for the new
#   name, finds nothing, and starts a fresh session for every user. The old
#   cookies are never even read, so no decryption errors occur.
#   Use this when you want a clean break without rotating the secret.

Rails.application.config.session_store :cookie_store, key: '_BadgeApp_session'
