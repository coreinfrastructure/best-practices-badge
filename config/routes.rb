# frozen_string_literal: true
# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  resources :project_stats
  get 'sessions/new'

  get 'signup' => 'users#new'
  get 'home' => 'static_pages#home'
  get 'background' => 'static_pages#background'
  get 'criteria' => 'static_pages#criteria'

  get 'feed' => 'projects#feed', defaults: { format: 'atom' }
  get 'reminders' => 'projects#reminders_summary'

  resources :projects do
    member do
      get 'badge', defaults: { format: 'svg' }
    end
  end

  resources :users
  resources :account_activations, only: [:edit]
  resources :password_resets,     only: %i(new create edit update)
  resources :projects
  match(
    'projects/:id/edit' => 'projects#update',
    :via => %i(put patch), :as => :put_project
  )
  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  delete 'logout' => 'sessions#destroy'

  get 'auth/:provider/callback' => 'sessions#create'
  get '/signout' => 'sessions#destroy', as: :signout

  # The priority is based upon order of creation: first created ->
  # highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'static_pages#home'

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

  # If no route found in some cases, just redirect to a 404 page.
  # The production site is constantly hit by nonsense paths,
  # and while Rails has a built-in mechanism to handle nonsense,
  # Rails' built-in mechanism creates very noisy logs.
  # Ideally we'd redirect all no-match cases quickly to a 404 handler.
  # Unfortunately, the noise-reduction approach for Rails 4 noted here:
  # http://rubyjunky.com/cleaning-up-rails-4-production-logging.html
  # works in development but does NOT work in production.
  # So instead, we'll select a few common cases where we have nothing
  # and there's no possible security problem, and fast-path its rejection
  # by redirecting to a 404 (without a lengthy log of the cause).
  # wp-login.php queries are evidences of WordPress brute-force attacks:
  # http://www.inmotionhosting.com/support/edu/wordpress/
  # wp-login-brute-force-attack
  match 'wp-login.php', via: :all, to: 'static_pages#error_404'
  match '.well-known/*path', via: :all, to: 'static_pages#error_404'
end
# rubocop:enable Metrics/BlockLength
