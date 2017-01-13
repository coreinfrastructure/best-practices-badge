# frozen_string_literal: true

class ProjectStatsController < ApplicationController
  # Our graphing component (chartkick) requires exceptions in our
  # content security policy (CSP), so poke holes in the policy.
  # This isn't so bad, because this page only displays data that is
  # numbers and dates, so even if there's a failure to escape the data
  # it would be challenging to exploit.
  SecureHeaders::Configuration.override(:headers_stats_index) do |config|
    config.csp[:script_src] = ["'self'", "'unsafe-inline'"]
    config.csp[:style_src] = ["'self'", "'unsafe-inline'"]
  end

  # GET /project_stats
  # GET /project_stats.json
  def index
    use_secure_headers_override :headers_stats_index
    @project_stats = ProjectStat.all
    # respond_to do |format|
    #     format.json {
    #        render :show, status: :created, location: @project_stat }
    # end
  end

  # GET /project_stats/1
  # GET /project_stats/1.json
  def show
    set_project_stat
  end

  # Forbidden:
  # GET /project_stats/new
  # def new
  # end

  # GET /project_stats/1/edit
  # def edit
  # end

  # POST /project_stats
  # POST /project_stats.json
  # def create
  # end

  # PATCH/PUT /project_stats/1
  # PATCH/PUT /project_stats/1.json
  # def update
  # end

  # DELETE /project_stats/1
  # DELETE /project_stats/1.json
  # def destroy
  # end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_project_stat
    @project_stat = ProjectStat.find(params[:id])
  end

  # Never trust parameters from the scary internet,
  # only allow the white list through.
  # def project_stat_params
  #   params.require(:project_stat).permit(:when, :all, :percent_ge_25,
  #     :percent_ge_50, :percent_ge_75, :percent_ge_90, :percent_ge_100)
  # end
end
