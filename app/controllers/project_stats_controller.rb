# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
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

  # These actions (endpoints) are special and do NOT take a locale.
  # These actions report JSON that is locale-independent; by always
  # omitting the locale, we create a single cacheable URL
  # that is used regardless of the locale. As a result, users who
  # use these are more likely to get a quick answer, and we also
  # save a few cycles on the server.
  # This is *only* acceptable if the called routine never calls I18n.t.
  skip_before_action :redir_missing_locale,
                     only: %i[total_projects nontrivial_projects silver gold]

  CSV_FILENAME = 'project_stats.csv'

  # The time, in number of seconds since midnight, when we log
  # project statistics. This is currently 23:30 UTC, set by Heroku scheduler;
  # change this value if you change the time of day we log statistics.
  LOG_TIME = ((23 * 60) + 30) * 60

  # If the "current time" is within this number of seconds to
  # seconds_since_midnight_log_time, presume that we're about to change
  # and thus do not cache statistics for long.
  LOG_TIME_SLOP = 5 * 60 # 5 minutes

  # Only cache for 120 seconds if we're within the slop time.
  CACHE_TIME_WITHIN_SLOP = 120

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
  # Sets HTTP header 'Cache-Control' to "max-age=#{seconds_left}, public"
  def cache_until_next_stat
    seconds_left = cache_time(Time.now.utc.seconds_since_midnight)
    # We can't just set Cache-Control directly like this:
    # headers['Cache-Control'] = "max-age=#{seconds_left}"
    # The problem is that Rails will quietly add 'private'
    # to the value of Cache-Control value. An easy solution is to
    # just use the built-in Rails mechanism for setting Cache-Control:
    expires_in seconds_left, public: true
  end

  # These controllers often generate a lot of JSON. More info:
  # https://guides.rubyonrails.org/layouts_and_rendering.html
  # https://buttercms.com/blog/json-serialization-in-rails-a-complete-guide
  # https://dev.to/caicindy87/rendering-json-in-a-rails-api-25fd
  # We *could* use other gems to speed JSON generation further
  # (e.g., oj), but that would add yet more dependencies; we think
  # the performance we get with "boring built-in tools" is adequate.

  # *Rapidly* render a JSON dataset which must *NOT* have cycles.
  # The default JSON renderer implements cycle-checking for safety.
  # We *know* that there are no cycles in the JSON datasets we create,
  # so we can use "fast_generate" instead of the default JSON generator.
  # This improves performance by skipping an unnecessary complicated check.
  # We justify doing this via benchmarks. We used:
  # require 'benchmark' ...
  # time = Benchmark.measure do {render} end ; puts "Time = #{time.real}"
  # Benchmark of nontrivial_projects of `render json: dataset` had averages:
  # - render time: 226ms (200,252)
  # - total service allocations: 171986 (171988,171983)
  # Benchmark of this `render body: JSON.fast_generate(dataset)` approach:
  # - render time: 53ms (39,33)
  # - total service allocations: 129562 (129561,129562)
  # So these samples average 173ms less time with 42K fewer allocations
  # on a development environment.
  # Technically this method is a view, not a controller, but this method is
  # so small that for simplicity we include this method in this controller.
  def render_json_fast(dataset)
    headers['Content-Type'] = 'application/json'
    render body: JSON.fast_generate(dataset)
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
          "attachment; filename=\"#{CSV_FILENAME}\""
        # No longer need this: @project_stats = ProjectStat.all
        @model = ProjectStat
        render format: :csv, filename: CSV_FILENAME
      end
      format.json do
        cache_until_next_stat
        @project_stats = ProjectStat.all
        # We use a special jbuilder view, so we can't use render_json_fast
        render format: :json
      end
      # { render :show, status: :created, location: @project_stat }
      format.html do
        @is_normal = (params[:type] != 'uncommon')
        # We don't get project stats when generating HTML, but instead
        # send that separately via JSON. If you needed to get that in
        # some case, you could get it this way:
        # @project_stats = ProjectStat.all unless @is_normal
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
  # Note that this does NOT take a locale.
  def total_projects
    cache_until_next_stat

    dataset =
      ProjectStat.select(:created_at, :percent_ge_0).reduce({}) do |h, e|
        h.merge(e.created_at => e.percent_ge_0)
      end
    render_json_fast dataset
  end

  # Database fieldnames >0% for level 0 (passing)
  # rubocop: disable Style/MethodCalledOnDoEndBlock
  LEVEL0_GT0_FIELDS =
    ProjectStat::STAT_VALUES_GT0.map do |e|
      "percent_ge_#{e}".to_sym
    end.freeze
  # rubocop: enable Style/MethodCalledOnDoEndBlock

  # GET /project_stats/nontrivial_projects.json
  # Dataset of nontrivial project entries
  # Note that this does NOT take a locale.
  # rubocop:disable Metrics/MethodLength
  # I "freeze" when I can to prevent some errors - allow that:
  # rubocop:disable Style/MethodCalledOnDoEndBlock
  def nontrivial_projects
    cache_until_next_stat

    # Ask the database *once* for the data we need, then reorganize it
    stat_data = ProjectStat.select(:created_at, *LEVEL0_GT0_FIELDS)

    # Show project counts; skip 0% because that makes chart scale unusable
    dataset =
      ProjectStat::STAT_VALUES_GT0.map do |minimum|
        desired_field = 'percent_ge_' + minimum.to_s
        series_dataset =
          stat_data.reduce({}) do |h, e|
            h.merge(e.created_at => e[desired_field])
          end
        { name: '>=' + minimum.to_s + '%', data: series_dataset }
      end

    render_json_fast dataset
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

    render_json_fast dataset
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # GET /:locale/project_stats/daily_activity.json
  # Dataset of daily activity
  # Note: The names of the datasets are translated
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength
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

    actions = %w[created updated].freeze
    actions.each do |action|
      desired_field = action + '_since_yesterday'
      series_dataset =
        stat_data.reduce({}) do |h, e|
          h.merge(e.created_at => e[desired_field])
        end
      dataset << {
        name: I18n.t("project_stats.index.projects_#{action}_since_yesterday"),
        data: series_dataset
      }
      # Calculate moving average over ndays
      series_counts = stat_data.pluck(desired_field)
      series_moving_average =
        series_counts.each_cons(ndays).map do |e|
          e.sum.to_f / ndays
        end
      moving_average_dataset = {}
      stat_data.each_with_index do |e, index|
        if index >= ndays
          moving_average_dataset[e.created_at] =
            series_moving_average[index - ndays]
        end
      end
      dataset << {
        name: I18n.t("project_stats.index.projects_#{action}_average_7_days"),
        data: moving_average_dataset,
        library: { borderDash: [5, 5] }
      }
    end

    render_json_fast dataset
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength

  # GET /:locale/project_stats/reminders.json
  # Reminders sent, reactivated after reminders
  # Note: The names of the datasets are translated
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def reminders
    cache_until_next_stat
    dataset = []

    # Retrieve just the data we need
    stat_data = ProjectStat.select(
      :created_at, :reminders_sent, :reactivated_after_reminder
    )

    # Reminders sent
    reminders_dataset =
      stat_data.reduce({}) do |h, e|
        h.merge(e.created_at => e.reminders_sent)
      end
    dataset << {
      name: I18n.t('project_stats.index.reminders_sent_since_yesterday'),
      data: reminders_dataset
    }
    # Reactivated after reminders
    reactivated_dataset =
      stat_data.reduce({}) do |h, e|
        h.merge(e.created_at => e.reactivated_after_reminder)
      end
    dataset << {
      name: I18n.t('project_stats.index.reactivated_projects'),
      data: reactivated_dataset
    }

    render_json_fast dataset
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # Level 1 (silver) database fields that are more than 25%
  # rubocop: disable Style/MethodCalledOnDoEndBlock
  LEVEL1_GT25_FIELDS =
    ProjectStat::STAT_VALUES_GT25.map do |e|
      "percent_1_ge_#{e}".to_sym
    end.freeze
  # rubocop: enable Style/MethodCalledOnDoEndBlock

  # GET /project_stats/silver.json
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def silver
    # Show project counts, but skip 25% because that makes chart scale unusable
    # The 25% value is a little misleading (because of overlaps), and messes
    # the scale, so show starting at 50%.

    cache_until_next_stat

    # Retrieve just the data we need
    stat_data = ProjectStat.select(:created_at, *LEVEL1_GT25_FIELDS)

    dataset =
      ProjectStat::STAT_VALUES_GT25.map do |minimum|
        desired_field = "percent_1_ge_#{minimum}"
        series_dataset =
          stat_data.reduce({}) do |h, e|
            h.merge(e.created_at => e[desired_field])
          end
        { name: ">=#{minimum}%", data: series_dataset }
      end

    render_json_fast dataset
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # Level 2 (gold) database fields that are more than 25%
  # rubocop: disable Style/MethodCalledOnDoEndBlock
  LEVEL2_GT25_FIELDS =
    ProjectStat::STAT_VALUES_GT25.map do |e|
      "percent_2_ge_#{e}".to_sym
    end.freeze
  # rubocop: enable Style/MethodCalledOnDoEndBlock

  # GET /project_stats/gold.json
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def gold
    # Show project counts, but skip 25% because that makes chart scale unusable
    # The 25% value is a little misleading (because of overlaps), and messes
    # the scale, so show starting at 50%.

    cache_until_next_stat

    # Retrieve just the data we need
    stat_data = ProjectStat.select(:created_at, *LEVEL2_GT25_FIELDS)

    dataset =
      ProjectStat::STAT_VALUES_GT25.map do |minimum|
        desired_field = "percent_2_ge_#{minimum}"
        series_dataset =
          stat_data.reduce({}) do |h, e|
            h.merge(e.created_at => e[desired_field])
          end
        { name: ">=#{minimum}%", data: series_dataset }
      end

    render_json_fast dataset
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  # GET /:locale/project_stats/silver_and_gold.json
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def silver_and_gold
    cache_until_next_stat

    # Retrieve just the data we need
    stat_data = ProjectStat.select(
      :created_at, :percent_1_ge_100, :percent_2_ge_100
    )

    dataset =
      %w[1 2].map do |level|
        desired_field = "percent_#{level}_ge_100"
        series_dataset =
          stat_data.reduce({}) do |h, e|
            h.merge(e.created_at => e[desired_field])
          end
        {
          name: I18n.t("projects.form_early.level.#{level}"),
          data: series_dataset
        }
      end

    render_json_fast dataset
  end

  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  # GET /:locale/project_stats/percent_earning.json
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def percent_earning
    cache_until_next_stat

    # Retrieve just the data we need
    stat_data = ProjectStat.select(
      :created_at, :percent_ge_0,
      :percent_ge_100, :percent_1_ge_100, :percent_2_ge_100
    )

    dataset =
      [0, 1, 2].map do |level|
        desired_field =
          "percent#{level.positive? ? '_' + level.to_s : ''}_ge_100"
        series_dataset =
          stat_data.reduce({}) do |h, e|
            h.merge(e.created_at =>
              e[desired_field].to_i * 100.0 / e['percent_ge_0'].to_i)
          end
        {
          name: I18n.t("projects.form_early.level.#{level}"),
           data: series_dataset
        }
      end

    render_json_fast dataset
  end

  # Return JSON-formatted chart data with the given fields
  # rubocop: disable Metrics/MethodLength
  def create_line_chart(fields)
    # Retrieve just the data we need
    database_fields = [:created_at] + fields.map(&:to_sym)
    stat_data = ProjectStat.select(*database_fields)

    dataset = []
    fields.each do |field|
      # Add "field" to dataset
      active_dataset =
        stat_data.reduce({}) do |h, e|
          h.merge(e.created_at => e[field])
        end
      dataset << {
        name: I18n.t("project_stats.index.#{field}"),
        data: active_dataset
      }
    end
    dataset
  end
  # rubocop: end Metrics/MethodLength

  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  # GET /:locale/project_stats/percent_earning.json
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def user_statistics
    cache_until_next_stat

    dataset =
      create_line_chart(
        %w[
          users
          github_users
          local_users
          users_created_since_yesterday
          users_updated_since_yesterday
          users_with_projects
          users_without_projects
          users_with_multiple_projects
          users_with_passing_projects
          users_with_silver_projects
          users_with_gold_projects
        ]
      )

    render_json_fast dataset
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
# rubocop:enable Metrics/ClassLength
