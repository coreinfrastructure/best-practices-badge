# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop:disable Metrics/ClassLength
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

  # The time, in number of seconds since midnight, when we log
  # project statistics. This is currently 23:30 UTC, set by Heroku scheduler;
  # change this value if you change the time of day we log statistics.
  LOG_TIME = (23 * 60 + 30) * 60

  # If the "current time" is within this number of seconds to
  # seconds_since_midnight_log_time, presume that we're about to change
  # and thus do not cache statistics for long.
  LOG_TIME_SLOP = 5 * 60 # 5 minutes

  # Only cache for 60 seconds if we're within the slop time.
  CACHE_TIME_WITHIN_SLOP = 60

  SECONDS_IN_A_DAY = 24 * 60 * 60 # 24 hours, 60 minutes, 60 seconds

  # Report the time we should cache, given seconds since midnight and
  # the fact that a log event will occur at "log_time". If the current
  # time and log time are within CACHE_TIME_WITHIN_SLOP, return a small
  # cache value.
  def cache_time(seconds_since_midnight)
    time_left = LOG_TIME - seconds_since_midnight
    if time_left.abs < LOG_TIME_SLOP
      CACHE_TIME_WITHIN_SLOP
    else
      time_left += SECONDS_IN_A_DAY if time_left.negative?
      time_left
    end
  end

  # Set the cache (including the CDN) to be used for cache_time
  def cache_until_next_stat
    seconds_left = cache_time(Time.now.utc.seconds_since_midnight)
    headers['Cache-Control'] = "max-age=#{seconds_left}"
  end

  # GET /project_stats
  # GET /project_stats.json
  # rubocop:disable Metrics/MethodLength
  def index
    use_secure_headers_override :headers_stats_index
    # Only load the full set of project stats if we need to
    respond_to do |format|
      format.csv do
        cache_until_next_stat
        headers['Content-Disposition'] =
          'attachment; filename="project_stats.csv"'
        @project_stats = ProjectStat.all
        render csv: @project_stats, filename: @project_stats.name
      end
      format.json do
        cache_until_next_stat
        @project_stats = ProjectStat.all
        render format: :json
      end
      # { render :show, status: :created, location: @project_stat }
      format.html do
        @is_normal = (params[:type] != 'uncommon')
        @project_stats = ProjectStat.all unless @is_normal
        render
      end
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
    cache_until_next_stat

    series_dataset =
      ProjectStat.select(:created_at, :percent_ge_0).reduce({}) do |h, e|
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
    cache_until_next_stat

    # Show project counts; skip 0% because that makes chart scale unusable
    # We could turn this into one database query; unclear it's worth doing.
    dataset =
      ProjectStat::STAT_VALUES_GT0.map do |minimum|
        desired_field = 'percent_ge_' + minimum.to_s
        series_dataset =
          ProjectStat.select(:created_at, desired_field.to_sym)
                     .reduce({}) do |h, e|
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
  def activity_30
    cache_until_next_stat
    dataset = []

    # Ask the database *once* for the data we need, then reorganize it
    stat_data = ProjectStat.select(
      :created_at,
      :active_projects, :active_in_progress,
      :active_edited_projects, :active_edited_in_progress
    )

    # Active projects
    active_dataset =
      stat_data.reduce({}) do |h, e|
        h.merge(e.created_at => e.active_projects)
      end
    dataset << {
      name: I18n.t('project_stats.index.active_projects'),
                data: active_dataset
    }

    # Active in-progress projects
    active_in_progress_dataset =
      stat_data.reduce({}) do |h, e|
        h.merge(e.created_at => e.active_in_progress)
      end
    dataset << {
      name: I18n.t('project_stats.index.active_in_progress'),
                data: active_in_progress_dataset
    }

    # Active edited projects
    active_edited_dataset =
      stat_data.reduce({}) do |h, e|
        h.merge(e.created_at => e.active_edited_projects)
      end
    dataset << {
      name: I18n.t('project_stats.index.active_edited'),
                data: active_edited_dataset
    }

    # Active edited in-progress projects
    active_edited_in_progress_dataset =
      stat_data.reduce({}) do |h, e|
        h.merge(e.created_at => e.active_edited_in_progress)
      end
    dataset << {
      name: I18n.t('project_stats.index.active_edited_in_progress'),
                data: active_edited_in_progress_dataset
    }

    render json: dataset
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # GET /:locale/project_stats/daily_activity.json
  # Dataset of daily activity
  # Note: The names of the datasets are translated
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def daily_activity
    # Show new and edited projects
    # These are expected to be smaller numbers, and show detailed activity,
    # so showing them separately will let us use scales that show more info.

    cache_until_next_stat

    dataset = []
    ndays = 7 # Days for calculated moving average

    # Retrieve just the data we need
    stat_data = ProjectStat.select(
      :created_at,
      :created_since_yesterday, :updated_since_yesterday
    )

    actions = ['created', 'updated'].freeze
    actions.each do |action|
      desired_field = action + '_since_yesterday'
      series_dataset = stat_data.reduce({}) do |h,e|
        h.merge(e.created_at => e[desired_field])
      end
      dataset << {
        name: I18n.t("project_stats.index.projects_#{action}_since_yesterday"),
        data: series_dataset
      }
      # Calculate moving average over ndays
      series_counts = stat_data.map { |e| e[desired_field] }
      series_moving_average = series_counts.each_cons(ndays).map do |e|
        e.reduce(&:+).to_f/ndays
      end
      moving_average_dataset = {}
      stat_data.each_with_index do |e, index|
        if index >= ndays
          moving_average_dataset[e.created_at] =
            series_moving_average[index-ndays]
        end
      end
      dataset << {
        name: I18n.t("project_stats.index.projects_#{action}_average_7_days"),
        data: moving_average_dataset,
        library: { borderDash: [5,5] }
      }
    end
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
# rubocop:enable Metrics/ClassLength
