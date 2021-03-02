# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

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
  # rubocop:disable Metrics/MethodLength
  def index
    use_secure_headers_override :headers_stats_index
    @project_stats = ProjectStat.all
    respond_to do |format|
      format.csv do
        headers['Content-Disposition'] =
          'attachment; filename="project_stats.csv"'
        render csv: @project_stats, filename: @project_stats.name
      end
      format.json
      # { render :show, status: :created, location: @project_stat }
      format.html
    end
  end
  # rubocop:enable Metrics/MethodLength

  # GET /project_stats/1
  # GET /project_stats/1.json
  # We may someday remove this, as it's not very useful.
  def show
    set_project_stat
  end

  # Use separate JSON endpoints for charts.
  # This greatly speeds graph display & makes it easy to cache the data on the CDN
  # (we can't use the CDN on the HTML, because it varies by who's logged in)
  # For more information, see:
  # https://chartkick.com/

  # GET /project_stats/total_projects.json
  # Dataset of total number of project entries.
  # Path is total_projects_project_stats_path
  def total_projects
    series_dataset =
      ProjectStat.all.reduce({}) do |h, e|
        h.merge(e.created_at => e.percent_ge_0)
      end
    render json: series_dataset
  end

  # GET /project_stats/nontrivial_projects.json
  # Dataset of nontrivial project entries
  # rubocop:disable Metrics/MethodLength
  # I "freeze" when I can to prevent some errors - allow that:
  # rubocop:disable Style/MethodCalledOnDoEndBlock
  def nontrivial_projects
    # Show project counts, but skip <25% because that makes chart scale unusable
    gt0_stats = ProjectStat::STAT_VALUES.select do |e|
      e.to_i.positive?
    end.freeze

    dataset =
      gt0_stats.map do |minimum|
        desired_field = 'percent_ge_' + minimum.to_s
        series_dataset =
          ProjectStat.all.reduce({}) do |h, e|
            h.merge(e.created_at => e[desired_field])
          end
        { name: '>=' + minimum.to_s + '%', data: series_dataset }
      end

    render json: dataset
  end
  # rubocop:enable Style/MethodCalledOnDoEndBlock
  # rubocop:enable Metrics/MethodLength

  # GET /:locale/project_stats/activity.json
  # Dataset of activity
  # Note: The names of the datasets are translated
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def activity
    dataset = []

    # Active projects
    active_dataset =
      ProjectStat.all.reduce({}) do |h, e|
        h.merge(e.created_at => e.active_projects)
      end
    dataset << {
      name: I18n.t('project_stats.index.active_projects'),
                data: active_dataset
    }

    # Active in-progress projects
    active_in_progress_dataset =
      ProjectStat.all.reduce({}) do |h, e|
        h.merge(e.created_at => e.active_in_progress)
      end
    dataset << {
      name: I18n.t('project_stats.index.active_in_progress'),
                data: active_in_progress_dataset
    }

    # Active edited projects
    active_edited_dataset =
      ProjectStat.all.reduce({}) do |h, e|
        h.merge(e.created_at => e.active_edited_projects)
      end
    dataset << {
      name: I18n.t('project_stats.index.active_edited'),
                data: active_edited_dataset
    }

    # Active edited in-progress projects
    active_edited_in_progress_dataset =
      ProjectStat.all.reduce({}) do |h, e|
        h.merge(e.created_at => e.active_edited_in_progress)
      end
    dataset << {
      name: I18n.t('project_stats.index.active_edited_in_progress'),
                data: active_edited_in_progress_dataset
    }

    render json: dataset
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

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
