require 'test_helper'

class SymbolTest < ActiveSupport::TestCase
  test '#status' do
    assert_equal :test.status, :test_status
  end

  test '#justification' do
    assert_equal :test.justification, :test_justification
  end
end
