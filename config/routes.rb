# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

# rubocop:disable Metrics/BlockLength

# The priority is based upon order of creation:
# first created -> highest priority.
# See how all your routes lay out with "rake routes".

Rails.application.routes.draw do
  LEGAL_LOCALE = /#{I18n.available_locales.join("|")}/

  # First, handle routing of special cases.
  # Warning: Routes that don't take a :locale value must include a
  # "skip_before_action :redir_missing_locale ..." in their controller.

  # The "robots.txt" file is always at the root of the
  # document tree, and locale is irrelevant to it. Handle it specially.
  get '/robots.txt' => 'static_pages#robots',
      defaults: { format: 'text' }, as: :robots

  # The /projects/NUMBER/badge image route needs speed and never depends
  # on the locale. Perhaps most importantly, badge images need to have
  # a single canonical name so that the CDN caches will work correctly.
  # If we use a single canonical name for a badge image, we can then
  # change or invalidate a single CDN cache to update a badge image.
  # If we had different routes for each locale, there'd be much
  # more work to change or invalidate them, with no purpose.
  # Therefore, instead of redirecting the badge image to a locale if
  # one is not listed, we do *NOT* support locale URLs in this case.
  get '/projects/:id/badge' => 'projects#badge',
      defaults: { format: 'svg' }

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

    resources :project_stats

    get 'sessions/new'

    get 'signup' => 'users#new'
    get 'home' => 'static_pages#home'
    get 'criteria' => 'static_pages#criteria'
    get 'cookies' => 'static_pages#cookies'

    get 'feed' => 'projects#feed', defaults: { format: 'atom' }
    get 'reminders' => 'projects#reminders_summary'

    VALID_CRITERIA_LEVEL = /[0-2]/
    resources :projects do
      member do
        get 'delete_form' => 'projects#delete_form'
        get '' => 'projects#show_json',
            constraints: ->(req) { req.format == :json }
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

    get 'login' => 'sessions#new'
    post 'login' => 'sessions#create'
    get 'auth/:provider/callback' => 'sessions#create'
    get '/signout' => 'sessions#destroy', as: :signout
    delete 'logout' => 'sessions#destroy'

    # This route applies when we have a non-empty locale
    # but the path doesn't match anything.
    # Redirect this to a 404 error code. If we don't do this, we'll be
    # stuck in a redirection loop caused by the code that redirects the
    # no-locale-in-URL case to this case (a path with a prefixed locale).
    match '*path',
          to: 'static_pages#error_404_no_locale_redir', via: :all,
          constraints: ->(req) { req.path_parameters[:locale].present? }
  end

  # Immediately stop processing some well-known garbage requests,
  # as a minor optimization, instead of processing their redirection later.
  # There's no point in redirecting the locales in
  # these cases, because a human is unlikely to read the error message.
  # wp-login.php queries are evidences of WordPress brute-force attacks:
  # http://www.inmotionhosting.com/support/edu/wordpress/
  # wp-login-brute-force-attack
  # Again, we provide a default locale to prevent locale redirection.
  match 'kk.php',
        via: :all, to: 'static_pages#error_404_no_locale_redir'
  match 'wp-login.php',
        via: :all, to: 'static_pages#error_404_no_locale_redir'
  match '.well-known/*path',
        via: :all, to: 'static_pages#error_404_no_locale_redir'

  # No other route and no (allowed) locale - send a 404 ("not found").
  # This will be intercepted and turned into a web browser redirect
  # to the best-matching locale. If the web browser follows the redirect
  # we provide, that new request will match the locale-specific 404 above.
  # That will enable us to send a locale-specific 404 message.
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
