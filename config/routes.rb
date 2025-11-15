# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop:disable Metrics/BlockLength

# The priority is based upon order of creation:
# first created -> highest priority.
# See how all your routes lay out with "rake routes".

# This regex defines all legal locale values:
LEGAL_LOCALE ||= /(?:#{I18n.available_locales.join('|')})/

# Canonical lists of valid criteria level names are defined in:
# config/initializers/00_criteria_levels.rb
# This includes: METAL_LEVEL_NAMES, METAL_LEVEL_NUMBERS, BASELINE_LEVEL_NAMES,
# LEVEL_SYNONYMS, SPECIAL_FORMS, and ALL_CRITERIA_LEVEL_NAMES

# This regex is used to verify criteria levels in routes:
# Built from ALL_CRITERIA_LEVEL_NAMES - DO NOT edit this directly
# To add new levels, update config/initializers/00_criteria_levels.rb
VALID_CRITERIA_LEVEL ||= /#{Regexp.union(ALL_CRITERIA_LEVEL_NAMES)}/

# Confirm that number-only id is provided
VALID_ID ||= /[1-9][0-9]*/

# Valid values for static badge display
VALID_STATIC_VALUE ||= /0|[1-9]{1,2}|passing|silver|gold/

Rails.application.routes.draw do
  # First, handle routing of special cases.
  # Warning: Routes that don't take a :locale value must include a
  # "skip_before_action :redir_missing_locale ..." in their controller.

  # The "robots.txt" file is always at the root of the
  # document tree and has no locale. Handle it specially.
  get '/robots.txt' => 'static_pages#robots',
      defaults: { format: 'text' }, as: :robots

  # The /projects/NUMBER/badge image route needs speed and never uses a
  # locale. Perhaps most importantly, badge images need to have
  # a single canonical name so that the CDN caches will work correctly.
  # If we use a single canonical name for a badge image, we can then
  # change or invalidate a single CDN cache to update a badge image.
  # If we had different routes for each locale, there'd be much
  # more work to change or invalidate them, with no purpose.
  # Therefore, instead of redirecting the badge image to a locale if
  # one is not listed, we do *NOT* support locale URLs in this case.
  get '/projects/:id/badge' => 'projects#badge',
      constraints: { id: VALID_ID },
      defaults: { format: 'svg' }

  # The /badge_static/:value route needs speed and never uses a locale.
  # Beware: This route produces a result unconnected to a project's status.
  # Do NOT use this route on a project's README.md page!
  get '/badge_static/:value' => 'badge_static#show',
      constraints: { value: VALID_STATIC_VALUE },
      defaults: { format: 'svg' }

  # These routes never use locales, so that the cache is shared across locales.
  get '/project_stats/total_projects', to: 'project_stats#total_projects',
    as: 'total_projects_project_stats',
    constraints: ->(req) { req.format == :json }
  get '/project_stats/nontrivial_projects',
      to: 'project_stats#nontrivial_projects',
      as: 'nontrivial_projects_project_stats',
      constraints: ->(req) { req.format == :json }
  get '/project_stats/silver', to: 'project_stats#silver',
    as: 'silver_project_stats',
    constraints: ->(req) { req.format == :json }
  get '/project_stats/gold', to: 'project_stats#gold',
    as: 'gold_project_stats',
    constraints: ->(req) { req.format == :json }

  # Weird special case: for David A. Wheeler to get log issues from Google,
  # we have to let Google verify this.  Locale is irrelevant.
  # It isn't really HTML, even though the filename extension is .html. See:
  # https://github.com/coreinfrastructure/best-practices-badge/issues/1223
  get '/google75f94b1182a77eb8.html' => 'static_pages#google_verifier',
      defaults: { format: 'text' }

  # Now handle the normal case: routes with an optional locale prefix.
  # We include almost all routes inside a :locale header,
  # where the locale is optional.  This approach (using an optional value)
  # is easier to use in Rails than some alternatives.  For example,
  # by doing this, helpers like root_path accept a locale parameter but work
  # without one (as expected).
  # If a locale is not provided, the ApplicationController will normally
  # send the web browser a redirect to the best locale it can identify.
  scope '(:locale)', locale: LEGAL_LOCALE do
    # TODO: Force a canonical URL for the top (root) level (with or without
    # a trailing slash), by redirecting the other.
    # For now, we just accept either.
    # The system itself always generates root URLs *without* a trailing slash.
    root to: 'static_pages#home'

    get '/project_stats', to: 'project_stats#index', as: 'project_stats'
    get '/project_stats/activity_30', to: 'project_stats#activity_30',
      as: 'activity_30_project_stats',
      constraints: ->(req) { req.format == :json }
    get '/project_stats/daily_activity', to: 'project_stats#daily_activity',
      as: 'daily_activity_project_stats',
      constraints: ->(req) { req.format == :json }
    get '/project_stats/reminders', to: 'project_stats#reminders',
      as: 'reminders_project_stats',
      constraints: ->(req) { req.format == :json }
    get '/project_stats/silver_and_gold', to: 'project_stats#silver_and_gold',
      as: 'silver_and_gold_project_stats',
      constraints: ->(req) { req.format == :json }
    get '/project_stats/percent_earning', to: 'project_stats#percent_earning',
      as: 'percent_earning_project_stats',
      constraints: ->(req) { req.format == :json }
    get '/project_stats/user_statistics', to: 'project_stats#user_statistics',
      as: 'user_statistics_project_stats',
      constraints: ->(req) { req.format == :json }
    # The following route isn't very useful; we may remove it in the future:
    get '/project_stats/:id', to: 'project_stats#show',
        constraints: { id: VALID_ID }

    get 'sessions/new'

    get 'signup' => 'users#new'

    # Handle "static" pages (get-only pages)
    get 'home' => 'static_pages#home'
    get 'criteria_stats' => 'static_pages#criteria_stats'
    get 'criteria_discussion' => 'static_pages#criteria_discussion'
    get 'cookies' => 'static_pages#cookies'

    get 'feed' => 'projects#feed', defaults: { format: 'atom' }
    get 'reminders' => 'projects#reminders_summary'

    # PERFORMANCE NOTE: These route-level redirects are processed early in the request
    # cycle, before controllers/models are loaded, using minimal memory. They return
    # 301 Permanent Redirect responses directly from the routing layer.

    # Permanent redirects for old numeric criteria levels to new canonical names
    # These are single-hop redirects: 0 → passing (not 0 → bronze → passing)
    get '/:locale/projects/:id/0(.:format)', to: redirect { |params, _req|
      format_suffix = params[:format] ? ".#{params[:format]}" : ''
      "/#{params[:locale]}/projects/#{params[:id]}/passing#{format_suffix}"
    }, status: 301, constraints: { locale: LEGAL_LOCALE, id: VALID_ID }
    get '/:locale/projects/:id/1(.:format)', to: redirect { |params, _req|
      format_suffix = params[:format] ? ".#{params[:format]}" : ''
      "/#{params[:locale]}/projects/#{params[:id]}/silver#{format_suffix}"
    }, status: 301, constraints: { locale: LEGAL_LOCALE, id: VALID_ID }
    get '/:locale/projects/:id/2(.:format)', to: redirect { |params, _req|
      format_suffix = params[:format] ? ".#{params[:format]}" : ''
      "/#{params[:locale]}/projects/#{params[:id]}/gold#{format_suffix}"
    }, status: 301, constraints: { locale: LEGAL_LOCALE, id: VALID_ID }
    get '/:locale/projects/:id/0/edit(.:format)', to: redirect { |params, _req|
      format_suffix = params[:format] ? ".#{params[:format]}" : ''
      "/#{params[:locale]}/projects/#{params[:id]}/passing/edit#{format_suffix}"
    }, status: 301, constraints: { locale: LEGAL_LOCALE, id: VALID_ID }
    get '/:locale/projects/:id/1/edit(.:format)', to: redirect { |params, _req|
      format_suffix = params[:format] ? ".#{params[:format]}" : ''
      "/#{params[:locale]}/projects/#{params[:id]}/silver/edit#{format_suffix}"
    }, status: 301, constraints: { locale: LEGAL_LOCALE, id: VALID_ID }
    get '/:locale/projects/:id/2/edit(.:format)', to: redirect { |params, _req|
      format_suffix = params[:format] ? ".#{params[:format]}" : ''
      "/#{params[:locale]}/projects/#{params[:id]}/gold/edit#{format_suffix}"
    }, status: 301, constraints: { locale: LEGAL_LOCALE, id: VALID_ID }

    # Redirect "bronze" to "passing" (common synonym)
    # Single-hop redirect to canonical form
    get '/:locale/projects/:id/bronze(.:format)', to: redirect { |params, _req|
      format_suffix = params[:format] ? ".#{params[:format]}" : ''
      "/#{params[:locale]}/projects/#{params[:id]}/passing#{format_suffix}"
    }, status: 301, constraints: { locale: LEGAL_LOCALE, id: VALID_ID }
    get '/:locale/projects/:id/bronze/edit(.:format)', to: redirect { |params, _req|
      format_suffix = params[:format] ? ".#{params[:format]}" : ''
      "/#{params[:locale]}/projects/#{params[:id]}/passing/edit#{format_suffix}"
    }, status: 301, constraints: { locale: LEGAL_LOCALE, id: VALID_ID }

    resources :projects, constraints: { id: VALID_ID } do
      member do
        get 'delete_form' => 'projects#delete_form'
        get '' => 'projects#show_json',
            constraints: ->(req) { req.format == :json }
        get '' => 'projects#show_markdown',
            constraints: ->(req) { req.format == :md }
        get ':criteria_level(.:format)' => 'projects#show',
            constraints: { criteria_level: VALID_CRITERIA_LEVEL }
        get ':criteria_level/edit(.:format)' => 'projects#edit',
            constraints: { criteria_level: VALID_CRITERIA_LEVEL }
      end
    end
    match(
      'projects/:id/(:criteria_level/)edit' => 'projects#update',
      via: %i[put patch], as: :put_project,
      constraints: { criteria_level: VALID_CRITERIA_LEVEL }
    )

    resources :users
    resources :account_activations, only: [:edit]
    resources :password_resets,     only: %i[new create edit update]

    get 'criteria/:criteria_level', to: 'criteria#show'
    get 'criteria', to: 'criteria#index'

    get 'login' => 'sessions#new'
    post 'login' => 'sessions#create'
    get 'auth/:provider/callback' => 'sessions#create'
    get '/signout' => 'sessions#destroy', as: :signout
    delete 'logout' => 'sessions#destroy'

    get 'unsubscribe' => 'unsubscribe#edit'
    post 'unsubscribe' => 'unsubscribe#create'

    # No other route, send a 404 ("not found").
    match '*path', via: :all, to: 'static_pages#error_404'
  end

  # No other route ("locale" wasn't allowed), so send a 404 ("not found").
  match '*path', via: :all, to: 'static_pages#error_404'

  # Here are some examples of routes.

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions
  # automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
# rubocop:enable Metrics/BlockLength
