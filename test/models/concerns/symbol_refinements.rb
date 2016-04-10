require 'test_helper'

class SymbolRefinementsNegativeTest < ActiveSupport::TestCase
  test '#status unpatched' do
    assert_raises(NoMethodError) { :test.status }
  end

  test '#justification unpatched' do
    assert_raises(NoMethodError) { :test.justification }
  end
end

class SymbolRefinementsPositiveTest < ActiveSupport::TestCase
  using SymbolRefinements

  test '#status' do
    assert_equal :test.status, :test_status
  end

  test '#justification' do
    assert_equal :test.justification, :test_justification
  end
end
