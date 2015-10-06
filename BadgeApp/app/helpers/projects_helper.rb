module ProjectsHelper

  FIELD_CATEGORIES = {
    "description_sufficient" => "MUST",
    "interact" => "MUST",
    "contribution" => "MUST",
    "contribution_criteria" => "SHOULD",
    "license_location" => "MUST",
    "oss_license" => "MUST",
    "oss_license_osi" => "SUGGESTED",
    "documentation_basics" => "MUST",
    "documentation_interface" => "MUST",
    "repo_url" => "MUST",
    "repo_track" => "MUST",
    "repo_interim" => "MUST",
    "repo_distributed" => "SUGGESTED",
    "version_unique" => "MUST",
    "version_semver" => "SUGGESTED",
    "version_tags" => "SUGGESTED",
    "changelog" => "MUST",
    "changelog_vulns" => "MUST",
    "report_tracker" => "SUGGESTED",
    "report_process" => "MUST",
    "report_responses" => "MUST",
    "enhancement_responses" => "SHOULD",
    "report_archive" => "MUST",
    "vulnerability_report_process" => "MUST",
    "vulnerability_report_private" => "MUST",
    "vulnerability_report_response" => "MUST",
    "build" => "MUST",
    "build_common_tools" => "SUGGESTED",
    "build_oss_tools" => "SHOULD",
    "test" => "MUST",
    "test_invocation" => "SHOULD",
    "test_most" => "SUGGESTED",
    "test_policy" => "MUST",
    "tests_are_added" => "MUST",
    "tests_documented_added" => "SUGGESTED",
    "warnings" => "MUST",
    "warnings_fixed" => "MUST",
    "warnings_strict" => "SUGGESTED",
    "know_secure_design" => "MUST",
    "know_common_errors" => "MUST",
    "crypto_published" => "MUST",
    "crypto_call" => "MUST",
    "crypto_oss" => "MUST",
    "crypto_keylength" => "MUST",
    "crypto_working" => "MUST",
    "crypto_pfs" => "SHOULD",
    "crypto_password_storage" => "MUST",
    "crypto_random" => "MUST",
    "delivery_mitm" => "MUST",
    "delivery_unsigned" => "MUST",
    "vulnerabilities_fixed_60_days" => "MUST",
    "vulnerabilities_critical_fixed" => "SHOULD",
    "static_analysis" => "MUST",
    "static_analysis_common_vulnerabilities" => "SUGGESTED",
    "static_analysis_fixed" => "MUST",
    "static_analysis_often" => "SUGGESTED",
    "dynamic_analysis_unsafe" => "MUST",
    "dynamic_analysis_enable_assertions" => "SUGGESTED",
    "dynamic_analysis_fixed" => "MUST" }


    def badge?(project)
      FIELD_CATEGORIES.each do |key, value|
        if value == "MUST"
          criteria = (key + "_status")
          unless project[criteria] == "Met"
            return false
          end
        end
        return true
      end
    end


end
