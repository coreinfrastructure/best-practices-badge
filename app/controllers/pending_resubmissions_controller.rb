# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Shows a stashed form submission after a forced re-login, so the submitter
# can resume it with one click instead of retyping it. See
# docs/login-session-implementation.md section 15.
#
# There is deliberately no :id/:token param on this route or read here: the
# only identifier is session[:pending_resubmission_token], written solely by
# this browser's own prior request (ApplicationController#stash_pending_resubmission).
# Reading anything from params instead would let anyone who guesses or
# enumerates an identifier view and destroy another browser's stashed
# submission; do not add one. (Since step 18, the token itself is also no
# longer guessable even if it did leak into params somehow: it's 128 bits
# of SecureRandom, matched server-side only by its HMAC digest. But the
# session-only rule stands regardless, unchanged from the original design.)
class PendingResubmissionsController < ApplicationController
  # Supports `GET /pending_resubmissions`.
  # @return [void]
  def show
    pending_token = session.delete(:pending_resubmission_token) # never params
    pending = PendingResubmission.find_by_token(pending_token)
    return redirect_expired unless pending

    pending.destroy # single-use
    flash.now[:warning] = t('.sensitive_fields_dropped') if pending.sensitive_fields_dropped?
    @resubmit_path = pending.resubmit_path
    @resubmit_method = pending.resubmit_method
    @fields = JSON.parse(pending.params_json)
  end

  private

  # @return [void]
  def redirect_expired
    flash[:danger] = t('.expired')
    redirect_to root_url
  end
end
