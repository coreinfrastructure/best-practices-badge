class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy]

  # GET /projects
  # GET /projects.json
  def index
    @projects = Project.all
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
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

    respond_to do |format|
      if @project.save
        format.html { redirect_to @project, success: 'Project was successfully Added!' }
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
                                      :license, :project_url_status,
                                      :project_url_status_justification,
                                      :project_url_https_status,
                                      :project_url_https_status_justification,
                                      :description_sufficient_status,
                                      :description_sufficient_status_justification,
                                      :interact_status,
                                      :interact_status_justification,
                                      :contribution_status,
                                      :contribution_status_justification,
                                      :contribution_criteria_status,
                                      :contribution_criteria_status_justification,
                                      :license_location,
                                      :license_location_justification,
                                      :oss_license,
                                      :oss_license_justification,
                                      :oss_license_osi,
                                      :oss_license_osi_justification,
                                      :documentation_basics_status,
                                      :documentation_basics_status_justification,
                                      :documentation_interface_status,
                                      :documentation_interface_status_justification,
                                      :repo_url_status,
                                      :repo_url_status_justification,
                                      :repo_track_status,
                                      :repo_track_status_justification,
                                      :repo_interim_status,
                                      :repo_interim_status_justification,
                                      :repo_distributed_status,
                                      :repo_distributed_status_justification,
                                      :version_unique_status,
                                      :version_unique_status_justification,
                                      :version_semver_status,
                                      :version_semver_status_justification,
                                      :version_tags_status,
                                      :version_tags_status_justification,
                                      :changelog_status,
                                      :changelog_status_justification,
                                      :changelog_vulns_status,
                                      :changelog_vulns_status_justification,
                                      :general_comments)
    end
end
