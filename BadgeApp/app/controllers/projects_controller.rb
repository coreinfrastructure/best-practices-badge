class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy, :badge]

  # GET /projects
  # GET /projects.json
  def index
    @projects = Project.all
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
  end

  def badge
    @project = Project.find(params[:id])
    respond_to do |format|
      if badge? @project
        format.svg {render :file => "app/assets/images/badge-pass.svg"}
      else
        format.svg {render :file => "app/assets/images/badge-fail.svg"}
      end
    end
  end

# GET /projects/new
  def new
    @project = Project.new
  end

  # GET /projects/1/edit
  def edit
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(project_params)

    # TODO: Error out if project_url and repo_url are both empty... don't
    # do a save yet.

    respond_to do |format|
      if @project.save
        format.html { redirect_to edit_project_path(@project) }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to @project, success: 'Project was successfully updated.' }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project.destroy
    respond_to do |format|
      format.html { redirect_to projects_url, notice: 'Project was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def project_params
      params.require(:project).permit(:name, :description, :project_url, :repo_url,
                                      :license,
                                      # Project Website (auto-populated, currently not in the form)
                                      :project_url_status,
                                      :project_url_justification,
                                      :project_url_https_status,
                                      :project_url_https_justification,
                                      # Basic Project Website Content
                                      :description_sufficient_status,
                                      :description_sufficient_justification,
                                      :interact_status,
                                      :interact_justification,
                                      :contribution_status,
                                      :contribution_justification,
                                      :contribution_criteria_status,
                                      :contribution_criteria_justification,
                                      # OSS License
                                      :license_location_status,
                                      :license_location_justification,
                                      :oss_license_status,
                                      :oss_license_justification,
                                      :oss_license_osi_status,
                                      :oss_license_osi_justification,
                                      # Documentation
                                      :documentation_basics_status,
                                      :documentation_basics_justification,
                                      :documentation_interface_status,
                                      :documentation_interface_justification,
                                    # CHANGE CONTROL
                                      # Public version-controlled source repository
                                      :repo_url_status,
                                      :repo_url_justification,
                                      :repo_track_status,
                                      :repo_track_justification,
                                      :repo_interim_status,
                                      :repo_interim_justification,
                                      :repo_distributed_status,
                                      :repo_distributed_justification,
                                      # Unique version numbering
                                      :version_unique_status,
                                      :version_unique_justification,
                                      :version_semver_status,
                                      :version_semver_justification,
                                      :version_tags_status,
                                      :version_tags_justification,
                                      # ChangeLog
                                      :changelog_status,
                                      :changelog_justification,
                                      :changelog_vulns_status,
                                      :changelog_vulns_justification,
                                    # REPORTING
                                      # Bug-reporting process
                                      :report_url_status,
                                      :report_url_justification,
                                      :report_tracker_status,
                                      :report_tracker_justification,
                                      :report_process_status,
                                      :report_process_justification,
                                      :report_responses_status,
                                      :report_responses_justification,
                                      :enhancement_responses_status,
                                      :enhancement_responses_justification,
                                      :report_archive_status,
                                      :report_archive_justification,
                                      # Vulnerability report process
                                      :vulnerability_report_process_status,
                                      :vulnerability_report_process_justification,
                                      :vulnerability_report_private_status,
                                      :vulnerability_report_private_justification,
                                      :vulnerability_report_response_status,
                                      :vulnerability_report_response_justification,
                                    # QUALITY
                                      # Working build system
                                      :build_status,
                                      :build_justification,
                                      :build_common_tools_status,
                                      :build_common_tools_justification,
                                      :build_oss_tools_status,
                                      :build_oss_tools_justification,
                                      # Automated test suite
                                      :test_status,
                                      :test_justification,
                                      :test_invocation_status,
                                      :test_invocation_justification,
                                      :test_most_status,
                                      :test_most_justification,
                                      # New functionality testing
                                      :test_policy_status,
                                      :test_policy_justification,
                                      :tests_are_added_status,
                                      :tests_are_added_justification,
                                      :tests_documented_added_status,
                                      :tests_documented_added_justification,
                                      # Warning flags
                                      :warnings_status,
                                      :warnings_justification,
                                      :warnings_fixed_status,
                                      :warnings_fixed_justification,
                                      :warnings_strict_status,
                                      :warnings_strict_justification,
                                    # SECURITY
                                      # Secure development knowledge
                                      :know_secure_design_status,
                                      :know_secure_design_justification,
                                      :know_common_errors_status,
                                      :know_common_errors_justification,
                                      # Use basic good cryptographic practices
                                      :crypto_published_status,
                                      :crypto_published_justification,
                                      :crypto_call_status,
                                      :crypto_call_justification,
                                      :crypto_oss_status,
                                      :crypto_oss_justification,
                                      :crypto_keylength_status,
                                      :crypto_keylength_justification,
                                      :crypto_working_status,
                                      :crypto_working_justification,
                                      :crypto_pfs_status,
                                      :crypto_pfs_justification,
                                      :crypto_password_storage_status,
                                      :crypto_password_storage_justification,
                                      :crypto_random_status,
                                      :crypto_random_justification,
                                      # Secured delivery against man-in-the-middle (MITM) attacks
                                      :delivery_mitm_status,
                                      :delivery_mitm_justification,
                                      :delivery_unsigned_status,
                                      :delivery_unsigned_justification,
                                      # Publicly-known Vulnerabilities fixed
                                      :vulnerabilities_fixed_60_days_status,
                                      :vulnerabilities_fixed_60_days_justification,
                                      :vulnerabilities_critical_fixed_status,
                                      :vulnerabilities_critical_fixed_justification,
                                    # SECURITY ANALYSIS
                                      # Static Code Analysis
                                      :static_analysis_status,
                                      :static_analysis_justification,
                                      :static_analysis_common_vulnerabilities_status,
                                      :static_analysis_common_vulnerabilities_justification,
                                      :static_analysis_fixed_status,
                                      :static_analysis_fixed_justification,
                                      :static_analysis_often_status,
                                      :static_analysis_often_justification,
                                      # Dynamic Analysis
                                      :dynamic_analysis_status,
                                      :dynamic_analysis_justification,
                                      :dynamic_analysis_unsafe_status,
                                      :dynamic_analysis_unsafe_justification,
                                      :dynamic_analysis_enable_assertions_status,
                                      :dynamic_analysis_enable_assertions_justification,
                                      :dynamic_analysis_fixed_status,
                                      :dynamic_analysis_fixed_justification,


                                      :general_comments)
    end

    FIELD_CATEGORIES = {
      "description_sufficient" => "MUST",
      "interact" => "MUST",
      "contribution" => "MUST",
      "contribution_criteria" => "SHOULD",
      "license_location" => "MUST",
      "oss_license" => "MUST",
      "oss_license_osi" => "SUGGESTED",
      "documentation_basics" => "MUST",
      "documentation_interface" => "MUST",
      "repo_url" => "MUST",
      "repo_track" => "MUST",
      "repo_interim" => "MUST",
      "repo_distributed" => "SUGGESTED",
      "version_unique" => "MUST",
      "version_semver" => "SUGGESTED",
      "version_tags" => "SUGGESTED",
      "changelog" => "MUST",
      "changelog_vulns" => "MUST",
      "report_tracker" => "SUGGESTED",
      "report_process" => "MUST",
      "report_responses" => "MUST",
      "enhancement_responses" => "SHOULD",
      "report_archive" => "MUST",
      "vulnerability_report_process" => "MUST",
      "vulnerability_report_private" => "MUST",
      "vulnerability_report_response" => "MUST",
      "build" => "MUST",
      "build_common_tools" => "SUGGESTED",
      "build_oss_tools" => "SHOULD",
      "test" => "MUST",
      "test_invocation" => "SHOULD",
      "test_most" => "SUGGESTED",
      "test_policy" => "MUST",
      "tests_are_added" => "MUST",
      "tests_documented_added" => "SUGGESTED",
      "warnings" => "MUST",
      "warnings_fixed" => "MUST",
      "warnings_strict" => "SUGGESTED",
      "know_secure_design" => "MUST",
      "know_common_errors" => "MUST",
      "crypto_published" => "MUST",
      "crypto_call" => "MUST",
      "crypto_oss" => "MUST",
      "crypto_keylength" => "MUST",
      "crypto_working" => "MUST",
      "crypto_pfs" => "SHOULD",
      "crypto_password_storage" => "MUST",
      "crypto_random" => "MUST",
      "delivery_mitm" => "MUST",
      "delivery_unsigned" => "MUST",
      "vulnerabilities_fixed_60_days" => "MUST",
      "vulnerabilities_critical_fixed" => "SHOULD",
      "static_analysis" => "MUST",
      "static_analysis_common_vulnerabilities" => "SUGGESTED",
      "static_analysis_fixed" => "MUST",
      "static_analysis_often" => "SUGGESTED",
      "dynamic_analysis_unsafe" => "MUST",
      "dynamic_analysis_enable_assertions" => "SUGGESTED",
      "dynamic_analysis_fixed" => "MUST" }


  def badge?(project)
    FIELD_CATEGORIES.each do |key, value|
      criteria_status = (key + "_status")
      criteria_just = (key + "_justification")
      if value == "MUST" and project[criteria_status] != "Met"
        return false
      elsif ["SHOULD", "SUGGESTED"].include? value and
            (project[criteria_status] == "?" or
              (project[criteria_status] == "Unmet" and
               project[criteria_just].length == 0))
        return false
      else next
      end
    end
    return true
  end
end
