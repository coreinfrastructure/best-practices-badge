# frozen_string_literal: true
require File.expand_path('../production', __FILE__)

Rails.application.configure do
  config.force_ssl = false
end
