# frozen_string_literal: true

# Copyright the Linux Foundation and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

namespace :login_sessions do
  desc 'Revoke all login sessions for the given user id'
  task :revoke, [:user_id] => :environment do |_t, args|
    if args.user_id.blank?
      puts 'Error: user id is required'
      puts 'Usage: rake login_sessions:revoke[123]'
      exit 1
    end

    user = User.find(Integer(args.user_id, 10)) # raises if not found
    count = user.login_sessions.delete_all
    puts "Revoked #{count} session(s) for user #{user.id} (#{user.name})."
    # This does *not* also invalidate the user's remember-me token: this
    # task is for incident response (e.g. a report of suspected
    # compromise), where the user themselves isn't the one acting, so
    # silently forgetting them too is a bigger behavior change than the
    # tool needs. Run `rails runner "User.find(#{user.id}).forget"`
    # separately if that's also warranted.
  end
end
