# frozen_string_literal: true
class ApplicationMailer < ActionMailer::Base
  default from: "badgeapp@#{ENV['PUBLIC_HOSTNAME'] || 'localhost'}"
  layout 'mailer'
end
