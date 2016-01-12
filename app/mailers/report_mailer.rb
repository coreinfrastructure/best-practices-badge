class ReportMailer < ApplicationMailer
  def project_status_change(project, old_badge_status, new_badge_status)
    @project = project
    @old_badge_status = old_badge_status
    @new_badge_status = new_badge_status
    @report_destination = 'cii-badge-log@lists.coreinfrastructure.org'
    mail(to: @report_destination,
         subject: "Project #{project.id} status change to " \
                  "passing=#{new_badge_status}")
  end
end
