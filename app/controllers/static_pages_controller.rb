# frozen_string_literal: true

class StaticPagesController < ApplicationController
  def home
    render "home.#{locale}"
  end

  def background; end

  def criteria
    render "criteria.#{locale}"
  end

  # Send a 404 ("not found") page.  Inspired by:
  # http://rubyjunky.com/cleaning-up-rails-4-production-logging.html
  def error_404
    # The default router already logs things, so we don't need to do more.
    # You can do something like this to log more information, but be sure
    # to escape attacker data to counter log forging:
    # logger.info 'Page not found'
    render(
      template: 'static_pages/error_404',
      layout: false,
      status: 404
    )
  end
end
