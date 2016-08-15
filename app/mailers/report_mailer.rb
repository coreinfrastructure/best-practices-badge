# frozen_string_literal: true
# rubocop:disable Metrics/MethodLength
class ReportMailer < ApplicationMailer
  def project_status_change(project, old_badge_status, new_badge_status)
    @project = project
    @old_badge_status = old_badge_status
    @new_badge_status = new_badge_status
    @project_info_url = ('https://' + (ENV['PUBLIC_HOSTNAME'] || 'localhost') +
                        '/projects/' + @project.id.to_s).freeze
    @report_destination = 'cii-badge-log@lists.coreinfrastructure.org'
    # Disable SendGrid's clicktracking, it creates ugly URLs.
    # See: https://sendgrid.com/docs/API_Reference/SMTP_API/apps.html
    headers['X-SMTPAPI'] =
      '{ "filters" : { "clicktrack" : { "settings" : { "enable" : 0 } } } }'
    mail(
      to: @report_destination,
      subject: "Project #{project.id} status change to " \
                        "passing=#{new_badge_status}"
    )
  end
end
