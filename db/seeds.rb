# frozen_string_literal: true
# This file should contain all the record creation needed to seed the database
# with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db
# with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
User.create!(
  name: 'Admin User', email: 'admin@example.org',
  password: 'p@$$w0rd',
  password_confirmation: 'p@$$w0rd',
  provider: 'local',
  role: 'admin', activated: true,
  activated_at: Time.zone.now
)

User.create!(
  name:  'Test User',
  email: 'test@example.org',
  password:              'password',
  password_confirmation: 'password',
  provider: 'local',
  activated: true,
  activated_at: Time.zone.now
)

100.times do |n|
  name  = Faker::Name.name
  email = "test-#{n + 1}@example.org"
  password = 'password'
  User.create!(
    name:  name,
    email: email,
    password:              password,
    password_confirmation: password,
    provider: 'local',
    activated: true,
    activated_at: Time.zone.now
  )
end

ProjectStat.create!

# Projects for testing
user = User.find_by(email: 'test@example.org')
user.projects.create!(
  user_id: user.id,
  name:  'BadgeApp',
  description: 'Badge Application',
  homepage_url:
                          'https://github.com/linuxfoundation/cii-best-practices-badge',
  repo_url:
                          'https://github.com/linuxfoundation/cii-best-practices-badge',
  license: 'MIT',
  badge_percentage: 0,
  homepage_url_status: '?',
  sites_https_status: '?',
  description_good_status: '?',
  interact_status: '?',
  contribution_status: '?',
  contribution_requirements_status: '?',
  license_location_status: '?',
  floss_license_status: '?',
  floss_license_osi_status: '?',
  documentation_basics_status: '?',
  documentation_interface_status: '?',
  discussion_status: '?',
  english_status: '?',
  repo_public_status: '?',
  repo_track_status: '?',
  repo_interim_status: '?',
  repo_distributed_status: '?',
  version_unique_status: '?',
  version_semver_status: '?',
  version_tags_status: '?',
  release_notes_status: '?',
  release_notes_vulns_status: '?',
  report_url_status: '?',
  report_tracker_status: '?',
  report_process_status: '?',
  report_responses_status: '?',
  enhancement_responses_status: '?',
  report_archive_status: '?',
  vulnerability_report_process_status: '?',
  vulnerability_report_private_status: '?',
  vulnerability_report_response_status: '?',
  build_status: '?',
  build_common_tools_status: '?',
  build_floss_tools_status: '?',
  test_status: '?',
  test_invocation_status: '?',
  test_most_status: '?',
  test_policy_status: '?',
  tests_are_added_status: '?',
  tests_documented_added_status: '?',
  warnings_status: '?',
  warnings_fixed_status: '?',
  warnings_strict_status: '?',
  know_secure_design_status: '?',
  know_common_errors_status: '?',
  crypto_published_status: '?',
  crypto_call_status: '?',
  crypto_floss_status: '?',
  crypto_keylength_status: '?',
  crypto_working_status: '?',
  crypto_pfs_status: '?',
  crypto_password_storage_status: '?',
  crypto_random_status: '?',
  delivery_mitm_status: '?',
  delivery_unsigned_status: '?',
  vulnerabilities_fixed_60_days_status: '?',
  vulnerabilities_critical_fixed_status: '?',
  hardening_status: '?',
  no_leaked_credentials_status: '?',
  static_analysis_status: '?',
  static_analysis_common_vulnerabilities_status: '?',
  static_analysis_fixed_status: '?',
  static_analysis_often_status: '?',
  dynamic_analysis_status: '?',
  dynamic_analysis_unsafe_status: '?',
  dynamic_analysis_enable_assertions_status: '?',
  dynamic_analysis_fixed_status: '?'
)

ProjectStat.create!

100.times do |n|
  name = "test-name-#{n + 1}"
  description = "test-description#{n + 1}"
  homepage_url = 'https://' + "test-project-url-#{n + 1}.org"
  repo_url = 'https://' + "test-repo-url-#{n + 1}.org"
  license = [
    'MIT', 'Apache-2.0', 'GPL-2.0', 'GPL-2.0+', 'GPL-3.0+', 'MPL-2.0',
    'BSD-3-Clause', 'BSD-2-Clause', '(Apache-2.0 OR GPL-2.0+)'
  ].sample
  user.projects.create!(
    user_id: user.id,
    name: name,
    description: description,
    homepage_url: homepage_url,
    repo_url: repo_url,
    license: license,
    badge_percentage: 0,
    homepage_url_status: '?',
    sites_https_status: '?',
    description_good_status: '?',
    interact_status: '?',
    contribution_status: '?',
    contribution_requirements_status: '?',
    license_location_status: '?',
    floss_license_status: '?',
    floss_license_osi_status: '?',
    documentation_basics_status: '?',
    documentation_interface_status: '?',
    discussion_status: '?',
    english_status: '?',
    repo_public_status: '?',
    repo_track_status: '?',
    repo_interim_status: '?',
    repo_distributed_status: '?',
    version_unique_status: '?',
    version_semver_status: '?',
    version_tags_status: '?',
    release_notes_status: '?',
    release_notes_vulns_status: '?',
    report_url_status: '?',
    report_tracker_status: '?',
    report_process_status: '?',
    report_responses_status: '?',
    enhancement_responses_status: '?',
    report_archive_status: '?',
    vulnerability_report_process_status: '?',
    vulnerability_report_private_status: '?',
    vulnerability_report_response_status: '?',
    build_status: '?',
    build_common_tools_status: '?',
    build_floss_tools_status: '?',
    test_status: '?',
    test_invocation_status: '?',
    test_most_status: '?',
    test_policy_status: '?',
    tests_are_added_status: '?',
    tests_documented_added_status: '?',
    warnings_status: '?',
    warnings_fixed_status: '?',
    warnings_strict_status: '?',
    know_secure_design_status: '?',
    know_common_errors_status: '?',
    crypto_published_status: '?',
    crypto_call_status: '?',
    crypto_floss_status: '?',
    crypto_keylength_status: '?',
    crypto_working_status: '?',
    crypto_pfs_status: '?',
    crypto_password_storage_status: '?',
    crypto_random_status: '?',
    delivery_mitm_status: '?',
    delivery_unsigned_status: '?',
    vulnerabilities_fixed_60_days_status: '?',
    vulnerabilities_critical_fixed_status: '?',
    hardening_status: '?',
    no_leaked_credentials_status: '?',
    static_analysis_status: '?',
    static_analysis_common_vulnerabilities_status: '?',
    static_analysis_fixed_status: '?',
    static_analysis_often_status: '?',
    dynamic_analysis_status: '?',
    dynamic_analysis_unsafe_status: '?',
    dynamic_analysis_enable_assertions_status: '?',
    dynamic_analysis_fixed_status: '?'
  )
end

ProjectStat.create!
