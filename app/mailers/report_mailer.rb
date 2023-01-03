# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# This mailer is for reports from the badge system about projects,
# individually or collectively.  This includes reports about
# badge status changes, summary reports, reminders that a project
# isn't done, etc.  This does not include email to a user
# regarding that user's account; those are handled by UserMailer.

# When sending emails we use I18n.with_locale do..end.
# If the destination is user.email, use:
# ... I18n.with_locale(user.preferred_locale.to_sym) do
# If the destination is REPORT_EMAIL_DESTINATION, use:
# ... I18n.with_locale(I18n.default_locale) do
# That's because it's possible that the current user is an administrator
# or script, in which case the current I18n.locale is not necessarily
# the recipient's preferred_locale.  Where possible, we want to use
# the recipient's preferred_locale when sending an email.

# We have not internationalized debug/monthly reports, since they are
# only sent in one language anyway (translators have enough work to do,
# let's not ask them to translate unused text!).

# rubocop:disable Metrics/MethodLength, Metrics/ClassLength
class ReportMailer < ApplicationMailer
  include SessionsHelper
  REPORT_EMAIL_DESTINATION = 'cii-badge-log@lists.coreinfrastructure.org'

  # Report to Linux Foundation that a project's status has changed.
  def project_status_change(project, old_badge_status, new_badge_status)
    @project = project
    @old_badge_status = old_badge_status
    @new_badge_status = new_badge_status
    @project_info_url = project_url(@project, locale: nil)
    @report_destination = REPORT_EMAIL_DESTINATION
    set_standard_headers
    I18n.with_locale(I18n.default_locale) do
      mail(
        to: @report_destination,
        subject: "Project #{project.id} status change to #{new_badge_status}"
      )
    end
  end

  # Return subject line for given badge status.  Uses current I18n.locale.
  def subject_for(old_badge_level, new_badge_level, lost_level)
    if lost_level
      t('report_mailer.subject_no_longer_passing', old_level: old_badge_level)
    else
      t('report_mailer.subject_achieved_passing', new_level: new_badge_level)
    end
  end

  # Create email to badge entry owner about their new badge status
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def email_owner(project, old_badge_level, new_badge_level, lost_level)
    return if project.nil? || project.id.nil? || project.user_id.nil?

    @project = project
    user = User.find(project.user_id)
    return if user.nil?
    return unless user.email?
    return unless user.email.include?('@')

    @project_info_url =
      project_url(@project, locale: user.preferred_locale.to_sym)
    @email_destination = user.email
    @new_level = new_badge_level
    @old_level = old_badge_level
    set_standard_headers
    I18n.with_locale(user.preferred_locale.to_sym) do
      mail(
        to: @email_destination,
        template_name: lost_level ? 'lost_level' : 'gained_level',
        subject: subject_for(
          old_badge_level, new_badge_level, lost_level
        ).strip
      )
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  # Create reminder email to inactive badge entry owner
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def email_reminder_owner(project)
    return if project.nil? || project.id.nil? || project.user_id.nil?

    @project = project
    user = User.find(project.user_id)
    return if user.nil?
    return unless user.email?
    return unless user.email.include?('@')

    @project_info_url =
      project_url(@project, locale: user.preferred_locale.to_sym)
    @email_destination = user.email
    set_standard_headers
    I18n.with_locale(user.preferred_locale.to_sym) do
      mail(
        to: @email_destination,
        # bcc: REPORT_EMAIL_DESTINATION, # This would bcc individual reminders
        subject: t('report_mailer.subject_reminder').strip
      )
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

  # Report on reminders sent.  This is internal, so we haven't bothered
  # to internationalize this.
  def report_reminder_summary(projects)
    @report_destination = REPORT_EMAIL_DESTINATION
    return if projects.nil?

    @projects = projects
    set_standard_headers
    I18n.with_locale(I18n.default_locale) do
      mail(
        to: @report_destination,
        subject: 'Summary of reminders sent'
      )
    end
  end

  # Generate monthly announcement, but only if there's a destination
  # email address environment variable REPORT_MONTHLY_EMAIL
  # We currently only send these out in English, so it's not internationalized
  # (no point in asking the translators to do unnecessary work).
  def report_monthly_announcement(
    projects,
    month_display,
    last_stat_in_prev_month,
    last_stat_in_prev_prev_month
  )
    @report_destination = ENV.fetch('REPORT_MONTHLY_EMAIL', nil)
    return if @report_destination.blank?

    @projects = projects
    @month_display = month_display
    @last_stat_in_prev_month = last_stat_in_prev_month
    @last_stat_in_prev_prev_month = last_stat_in_prev_prev_month
    set_standard_headers
    I18n.with_locale(I18n.default_locale) do
      mail(
        to: @report_destination,
        subject: 'Projects that received badges (monthly summary)'
      )
    end
  end

  # Email user when they add a new project.
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def email_new_project_owner(project)
    return if project.nil? || project.id.nil? || project.user_id.nil?

    @project = project
    user = User.find(project.user_id)
    return if user.nil?
    return unless user.email?
    return unless user.email.include?('@')

    @project_info_url =
      project_url(@project, locale: user.preferred_locale.to_sym)
    @email_destination = user.email
    set_standard_headers
    I18n.with_locale(user.preferred_locale.to_sym) do
      mail(
        to: @email_destination,
        subject: t('report_mailer.subject_new_project').strip
      )
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

  # Report if a project is deleted.  "deletion_rationale" is untrusted
  # data from a user.
  def report_project_deleted(project, user, deletion_rationale)
    @report_destination = REPORT_EMAIL_DESTINATION
    @project = project
    @user = user
    @deletion_rationale = deletion_rationale
    set_standard_headers
    I18n.with_locale(I18n.default_locale) do
      mail(
        to: @report_destination,
        subject: t(
          'report_mailer.subject_project_deleted',
          project_id: project.id, project_name: project.name
        ).strip
      )
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/ClassLength
