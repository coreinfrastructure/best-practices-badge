# frozen_string_literal: true
# rubocop:disable Metrics/MethodLength
class ReportMailer < ApplicationMailer
  REPORT_EMAIL_DESTINATION = 'cii-badge-log@lists.coreinfrastructure.org'

  def set_headers
    # Disable SendGrid's clicktracking, it creates ugly URLs.
    # See: https://sendgrid.com/docs/API_Reference/SMTP_API/apps.html
    headers['X-SMTPAPI'] =
      '{ "filters" : { "clicktrack" : { "settings" : { "enable" : 0 } } } }'
  end

  def project_info_url(id)
    ('https://' + (ENV['PUBLIC_HOSTNAME'] || 'localhost') +
      '/projects/' + id.to_s).freeze
  end

  # Report to Linux Foundation that a project's status has changed.
  def project_status_change(project, old_badge_status, new_badge_status)
    @project = project
    @old_badge_status = old_badge_status
    @new_badge_status = new_badge_status
    @project_info_url = project_info_url(@project.id)
    @report_destination = REPORT_EMAIL_DESTINATION
    set_headers
    mail(
      to: @report_destination,
      subject: "Project #{project.id} status change to " \
                        "passing=#{new_badge_status}"
    )
  end

  def subject_for(new_badge_status)
    if new_badge_status == 'passing'
      'CONGRATULATIONS on achieving a passing best practices badge!'
    else
      'Your best practices badge is no longer passing'
    end
  end

  # Create email to badge entry owner about their new badge status
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def email_owner(project, new_badge_status)
    return if project.nil? || project.id.nil? || project.user_id.nil?
    @project = project
    user = User.find(project.user_id)
    return if user.nil?
    return unless user.email?
    return unless user.email.include?('@')
    @project_info_url = project_info_url(@project.id)
    @email_destination = user.email
    set_headers
    mail(
      to: @email_destination,
      template_name: new_badge_status,
      subject: subject_for(new_badge_status)
    )
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

  # Create reminder email to inactive badge entry owner
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def email_reminder_owner(project)
    return if project.nil? || project.id.nil? || project.user_id.nil?
    @project = project
    user = User.find(project.user_id)
    return if user.nil?
    return unless user.email?
    return unless user.email.include?('@')
    @project_info_url = project_info_url(@project.id)
    @email_destination = user.email
    set_headers
    mail(
      to: @email_destination,
      bcc: REPORT_EMAIL_DESTINATION, # Eventually remove this.
      subject: 'Your project does not yet have the "best practices" badge'
    )
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

  # Report on reminders sent
  def report_reminder_summary(projects)
    @report_destination = REPORT_EMAIL_DESTINATION
    return if projects.nil?
    @projects = projects
    set_headers
    mail(
      to: @report_destination,
      subject: 'Summary of reminders sent'
    )
  end
end
