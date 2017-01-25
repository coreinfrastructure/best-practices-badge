# frozen_string_literal: true
class StaticPagesController < ApplicationController
  def home; end

  def background; end

  def criteria; end

  # Send a 404 ("not found") page.  Inspired by:
  # http://rubyjunky.com/cleaning-up-rails-4-production-logging.html
  def error_404
    # The default router already logs things, so we don't need to do more.
    # You can do something like this to log more information, but be sure
    # to escape attacker data to counter log forging:
    # logger.info 'Page not found'
    render status: 404
  end
end
