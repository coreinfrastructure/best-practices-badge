# frozen_string_literal: true
require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  def setup
    @user = users(:test_user)
    @project = @user.projects.build(
      homepage_url: 'https://www.example.org',
      repo_url: 'https://www.example.org/code'
    )
  end

  test 'should be valid' do
    assert @project.valid?
  end

  test 'user id should be present' do
    @project.user_id = nil
    assert_not @project.valid?
  end

  test '#contains_url?' do
    assert Project.new.contains_url? 'https://www.example.org'
    assert Project.new.contains_url? 'http://www.example.org'
    assert Project.new.contains_url? 'See also http://x.org.'
    assert Project.new.contains_url? 'See also <http://x.org>.'
    refute Project.new.contains_url? 'mailto://mail@example.org'
    refute Project.new.contains_url? 'abc'
    refute Project.new.contains_url? 'See also http://x for more information.'
    refute Project.new.contains_url? 'www.google.com'
  end

  test 'Rigorous project and repo URL checker' do
    regex = UrlValidator::URL_REGEX
    my_url = 'https://github.com/linuxfoundation/cii-best-practices-badge'
    assert my_url =~ regex

    # Here we just the regex directly, to make sure it's okay.
    assert 'https://kernel.org' =~ regex
    refute 'https://' =~ regex
    refute 'www.google.com' =~ regex
    refute 'See also http://x.org for more information.' =~ regex
    refute 'See also <http://x.org>.' =~ regex

    # Here we use the full validator.  We stub out the info necessary
    # to create a validator instance to test (we won't really use them).
    validator = UrlValidator.new(attributes: %i(repo_url project_url))
    assert validator.url_acceptable?(my_url)
    assert validator.url_acceptable?('https://kernel.org')
    assert validator.url_acceptable?('') # Empty allowed.
    refute validator.url_acceptable?('https://')
    refute validator.url_acceptable?('www.google.com')
    refute validator.url_acceptable?('See also http://x.org for more.')
    refute validator.url_acceptable?('See also <http://x.org>.')
    assert validator.url_acceptable?('http://google.com')
    # We don't allow '?'
    refute validator.url_acceptable?('http://google.com?hello')
    # We do allow fragments, e.g., #
    refute validator.url_acceptable?('http://google.com#hello')

    # Accept U+0020 (space) and U+00E9 c3 a9 "LATIN SMALL LETTER E WITH ACUTE"
    assert validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    'cii-best-practices-badge%20%c3%a9')
    # Accept U+8C0A Unicode Han Character 'friendship; appropriate, suitable'
    # encoded in UTF-8 as 0xE8 0xB0 0x8A (e8b08a); see
    # http://www.fileformat.info/info/unicode/char/8c0a/index.htm
    assert validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    '%E8%B0%8A')
    # Accept U+1000 Unicode Character 'MYANMAR LETTER KA'
    # encoded in UTF-8 as 0xE1 0x80 0x80
    # http://www.fileformat.info/info/unicode/char/1000/index.htm
    assert validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    '%e1%80%80')
    # Don't accept "c0 80", an overlong (2-byte) encoding of U+0000 (NUL).
    # Note that "modified UTF-8" does accept this.
    refute validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    'cii-best-practices-badge%20%c0%80')
    # Don't accept non-UTF-8, even if the individual bytes are acceptable.
    refute validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    'cii-best-practices-badge%eex')
    refute validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    'cii-best-practices-badge%ee')
    refute validator.url_acceptable?('https://github.com/linuxfoundation/' \
                                    'cii-best-practices-badge%ff%ff')
  end
end
