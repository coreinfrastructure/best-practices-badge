# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require_relative '../lib/locale_utils'

# rubocop:disable Metrics/BlockLength

# The priority is based upon order of creation:
# first created -> highest priority.
# See how all your routes lay out with "rake routes".

# Note that:
# - Sections::VALID_SECTION_REGEX has a regex of all valid
# section names (e.g., 'passing', 'baseline-1', 'permissions', and
# even obsolete ones that get redirected like '0' or 'bronze').
# - Sections::REDIRECTS maps obsolete level names to their
# canonical equivalents (e.g., '0' => 'passing').

# Define regexes for legal locale values
LEGAL_LOCALE ||= /(?:#{I18n.available_locales.join('|')})/
LEGAL_LOCALE_FULL ||= /\A#{LEGAL_LOCALE.source}\z/

# Confirm that number-only id is provided
VALID_ID ||= /[1-9][0-9]*/
VALID_ID_FULL ||= /\A#{VALID_ID.source}\z/

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

  # JSON API route (locale-independent, outside scope for performance)
  # GET /projects/:id.json (extension required)
  # This is the expected common case, so it's matched first
  get '/projects/:id.json' => 'projects#show_json',
      constraints: { id: VALID_ID },
      defaults: { format: 'json' },
      as: :project_json

  # Redirect localized JSON to non-localized version (301 permanent)
  # GET /:locale/projects/:id.json → /projects/:id.json
  # Handle common mistake of adding locale to JSON URLs
  get '/:locale/projects/:id' => redirect('/projects/%{id}.json', status: 301),
      constraints: lambda { |req|
        req.params[:id] =~ VALID_ID_FULL &&
          req.params[:locale] =~ LEGAL_LOCALE_FULL &&
          req.format == :json
      }

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

    # Standard RESTful routes for projects
    # Excludes :show and :edit (custom routes below handle sections)
    # Excludes :update (custom route below with section parameter)
    resources :projects, only: %i[index new create destroy],
              constraints: { id: VALID_ID }

    # Delete confirmation form (specific route before generic :section)
    # GET (/:locale)/projects/:id/delete_form
    get 'projects/:id/delete_form' => 'projects#delete_form',
        constraints: { id: VALID_ID },
        as: :delete_form_project

    # Edit with section (before show to avoid conflicts)
    # GET (/:locale)/projects/:id/:section/edit
    # Use PRIMARY_SECTION_REGEX to reject obsolete sections in edit URLs
    get 'projects/:id/:section/edit' => 'projects#edit',
        constraints: {
          id: VALID_ID,
          section: Sections::PRIMARY_SECTION_REGEX
        },
        as: :edit_project_section

    # Show section with format (HTML or Markdown)
    # GET (/:locale)/projects/:id/:section(.:format)
    # Use VALID_SECTION_REGEX to accept obsolete sections (controller will redirect)
    # Controller also handles query parameter format: ?criteria_level=LEVEL
    get 'projects/:id/:section' => 'projects#show',
        constraints: {
          id: VALID_ID,
          section: Sections::VALID_SECTION_REGEX
        },
        as: :project_section,
        defaults: { format: 'html' }

    # Redirect to default section (handles all formats except JSON)
    # GET (/:locale)/projects/:id(.:format) → redirects to default section
    # Also handles legacy query parameter: ?criteria_level=LEVEL
    # JSON format handled by non-localized routes above
    get 'projects/:id' => 'projects#redirect_to_default_section',
        constraints: { id: VALID_ID },
        as: :project_redirect

    # Update project (PUT/PATCH) - section optional
    # PUT/PATCH (/:locale)/projects/:id(/:section)
    # Accepts patterns with or without section in URL
    # Section in URL indicates where to redirect after successful update
    # IMPORTANT: ANY project field can be updated regardless of section
    # Use PRIMARY_SECTION_REGEX to reject obsolete sections in update URLs
    match 'projects/:id(/:section)' => 'projects#update',
          via: %i[put patch],
          constraints: {
            id: VALID_ID,
            section: Sections::PRIMARY_SECTION_REGEX
          },
          as: :update_project

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
