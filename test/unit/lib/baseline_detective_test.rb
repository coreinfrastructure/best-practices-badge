# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# Test the BaselineDetective which handles baseline-unique automated checks.
# Most baseline automation is now handled by extending existing detectives
# (e.g., FlossLicenseDetective outputs both metal and baseline fields).
# This detective only handles checks unique to baseline.
class BaselineDetectiveTest < ActiveSupport::TestCase
  # Mock repo_files with SECURITY.md
  class MockRepoFilesWithSecurity
    def present?
      true
    end

    def get_info(_pattern)
      [
        { 'type' => 'file', 'name' => 'SECURITY.md', 'size' => 100 }
      ]
    end
  end

  # Mock repo_files with security.txt
  class MockRepoFilesWithSecurityTxt
    def present?
      true
    end

    def get_info(_pattern)
      [
        { 'type' => 'file', 'name' => 'SECURITY.txt', 'size' => 100 }
      ]
    end
  end

  # Mock repo_files with lowercase security.md
  class MockRepoFilesWithLowercaseSecurity
    def present?
      true
    end

    def get_info(_pattern)
      [
        { 'type' => 'file', 'name' => 'security.md', 'size' => 100 }
      ]
    end
  end

  # Mock repo_files without security file
  class MockRepoFilesNoSecurity
    def present?
      true
    end

    def get_info(_pattern)
      [
        { 'type' => 'file', 'name' => 'README.md', 'size' => 100 }
      ]
    end
  end

  setup do
    @detective = BaselineDetective.new
  end

  # Test license declaration (osps_le_02_01)
  test 'marks license declaration met when license is present' do
    results = @detective.analyze(nil, license: 'MIT')

    assert results.key?(:osps_le_02_01_status)
    assert_equal 'Met', results[:osps_le_02_01_status][:value]
    assert results[:osps_le_02_01_status][:confidence] >= 4
  end

  test 'does not mark license met for NOASSERTION' do
    results = @detective.analyze(nil, license: 'NOASSERTION')

    assert_not results.key?(:osps_le_02_01_status)
  end

  test 'does not mark license met for NONE' do
    results = @detective.analyze(nil, license: 'NONE')

    assert_not results.key?(:osps_le_02_01_status)
  end

  # Test security policy detection (osps_gv_02_01, osps_gv_03_01)
  test 'marks security policy met when SECURITY.md exists' do
    repo_files = MockRepoFilesWithSecurity.new
    results = @detective.analyze(nil, repo_files: repo_files)

    assert results.key?(:osps_gv_02_01_status)
    assert_equal 'Met', results[:osps_gv_02_01_status][:value]
    assert results[:osps_gv_02_01_status][:confidence] >= 3

    assert results.key?(:osps_gv_03_01_status)
    assert_equal 'Met', results[:osps_gv_03_01_status][:value]
  end

  test 'finds SECURITY.txt file' do
    repo_files = MockRepoFilesWithSecurityTxt.new
    results = @detective.analyze(nil, repo_files: repo_files)

    assert results.key?(:osps_gv_02_01_status)
    assert_equal 'Met', results[:osps_gv_02_01_status][:value]
  end

  test 'finds security file case-insensitively' do
    repo_files = MockRepoFilesWithLowercaseSecurity.new
    results = @detective.analyze(nil, repo_files: repo_files)

    assert results.key?(:osps_gv_02_01_status)
  end

  test 'does not mark security policy met when no SECURITY file' do
    repo_files = MockRepoFilesNoSecurity.new
    results = @detective.analyze(nil, repo_files: repo_files)

    assert_not results.key?(:osps_gv_02_01_status)
    assert_not results.key?(:osps_gv_03_01_status)
  end

  # Test that we don't create false positives
  test 'returns empty hash when no criteria can be determined' do
    results = @detective.analyze(nil, {})

    assert results.is_a?(Hash)
    assert results.empty?
  end

  test 'handles combination of license and security file' do
    repo_files = MockRepoFilesWithSecurity.new

    results = @detective.analyze(
      nil,
      license: 'Apache-2.0',
      repo_files: repo_files
    )

    # Should have both license and security criteria
    assert results.key?(:osps_le_02_01_status)
    assert results.key?(:osps_gv_02_01_status)
    assert results.key?(:osps_gv_03_01_status)
  end
end
