class ReportMailer < ApplicationMailer
  def project_status_change(project, old_badge_status, new_badge_status)
    @project = project
    @old_badge_status = old_badge_status
    @new_badge_status = new_badge_status
    @report_destination = 'dwheeler@ida.org' # TODO
    mail(to: @report_destination,
         # content_type: 'multipart/alternative', # automatic
         subject: "Project #{project.id} status change")
  end
end
