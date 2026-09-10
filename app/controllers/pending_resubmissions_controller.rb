# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# Shows a stashed form submission after a forced re-login, so the submitter
# can resume it with one click instead of retyping it. See
# docs/login-session-implementation.md section 15.
#
# There is deliberately no :id/:token param on this route or read here: the
# only identifier is session[:pending_resubmission_id], written solely by
# this browser's own prior request (ApplicationController#stash_pending_resubmission).
# Reading an id from params instead would let anyone who guesses or
# enumerates a small integer view and destroy another browser's stashed
# submission -- do not add one.
class PendingResubmissionsController < ApplicationController
  # Supports `GET /pending_resubmissions`.
  # @return [void]
  def show
    pending_id = session.delete(:pending_resubmission_id) # never params
    pending = PendingResubmission.find_by(id: pending_id) if pending_id
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
