require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  def setup
  end

  test 'markdown - simple' do
    assert_equal "<p>hi</p>\n", ApplicationHelper.markdown('hi')
  end

  test 'markdown - emphasis' do
    assert_equal "<p><em>hi</em></p>\n", ApplicationHelper.markdown('*hi*')
  end

  test 'markdown - bare URL' do
    assert_equal(
      '<p><a href="http://www.dwheeler.com">' \
      "http://www.dwheeler.com</a></p>\n",
      ApplicationHelper.markdown('http://www.dwheeler.com'))
  end

  test 'markdown - angles around URL' do
    assert_equal(
      '<p><a href="http://www.dwheeler.com">' \
      "http://www.dwheeler.com</a></p>\n",
      ApplicationHelper.markdown('<http://www.dwheeler.com>'))
  end

  test 'markdown - no script HTML' do
    assert_equal(
      "<p>Hello</p>\n",
      ApplicationHelper.markdown('<script src="hi"></script>Hello'))
  end
end
