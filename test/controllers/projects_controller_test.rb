# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'
require 'ostruct'

# rubocop:disable Metrics/ClassLength
class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    @project_two = projects(:two)
    @project_no_repo = projects(:no_repo)
    @perfect_passing_project = projects(:perfect_passing)
    @user = users(:test_user)
    @user2 = users(:test_user_melissa) # password 'password1'
    @admin = users(:admin_user)
  end

  # Ensure that every criterion that is *supposed* to be in this level is
  # selectable, and that every criterion that is *not* supposed to be in this
  # level is not selectable.
  # rubocop:disable Metrics/MethodLength
  def only_correct_criteria_selectable(level)
    Criteria.keys do |query_level|
      Criteria[query_level].each do |criterion|
        if query_level == level
          assert_select '#' + criterion.to_s
          assert_select "#project_#{criterion}_status_met"
        elsif !Criteria[level].key?(criterion)
          # This is criterion in another level, *not* this one
          assert_select '#' + criterion.to_s, false
          assert_select "#project_#{criterion}_status_met", false
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  test 'should get index' do
    get '/en/projects'
    assert_response :success
    assert_includes @response.body, 'Badge status'
    assert_not_includes @response.body, 'target=[^ >]+>'
    assert_equal 'Accept-Encoding, Origin', @response.headers['Vary']
  end

  test 'new but not logged in' do
    get '/en/projects/new'
    assert_response :success
    assert_includes @response.body, 'Log in with '
    assert_not_includes @response.body,
                        'What is the URL for the project home page ' \
                        '(the URL for the project as a whole)'
  end

  test 'should get new' do
    log_in_as(@user)
    get '/en/projects/new'
    assert_response :success
    assert_not_includes @response.body, 'Log in with '
    assert_includes @response.body,
                    'What is the URL for the project home page ' \
                    '(the URL for the project as a whole)'
  end

  test 'should create project' do
    log_in_as(@user)
    stub_request(:get, 'https://api.github.com/user/repos')
      .to_return(status: 200, body: '', headers: {})
    # Use assert_difference to verify that project record created & email sent
    assert_difference [
      'Project.count', 'ActionMailer::Base.deliveries.size'
    ] do
      post '/en/projects', params: { # Routes to 'create'
        project: {
          description: @project.description,
          license: @project.license,
          name: @project.name,
          repo_url: 'https://www.example.org/code',
          homepage_url: @project.homepage_url
        }
      }
    end
    # Ensure that we actually created the project with those values
    new_project = Project.find_by(repo_url: 'https://www.example.org/code')
    assert_equal @project.description, new_project.description
    assert_equal @project.license, new_project.license
    assert_equal @project.name, new_project.name
    assert_equal 'https://www.example.org/code', new_project.repo_url
    assert_equal @project.homepage_url, new_project.homepage_url
    assert new_project.id != @project.id
  end

  test 'should create project with empty repo' do
    log_in_as(@user)
    stub_request(:get, 'https://api.github.com/user/repos')
      .to_return(status: 200, body: '', headers: {})
    assert_difference [
      'Project.count', 'ActionMailer::Base.deliveries.size'
    ] do
      post '/en/projects', params: { # Routes to 'create'
        project: {
          description: @project.description,
          license: @project.license,
          name: @project.name,
          repo_url: '',
          homepage_url: @project.homepage_url
        }
      }
    end
  end

  test 'should fail to create project with duplicate repo' do
    log_in_as(@user)
    stub_request(:get, 'https://api.github.com/user/repos')
      .to_return(status: 200, body: '', headers: {})
    assert_no_difference [
      'Project.count', 'ActionMailer::Base.deliveries.size'
    ] do
      post '/en/projects', params: { # Routes to 'create'
        project: {
          description: 'Some other project',
          license: @project.license,
          name: @project.name,
          repo_url: @project.repo_url,
          homepage_url: @project_two.homepage_url
        }
      }
    end
  end

  test 'should fail to create project as blocked user' do
    blocked_user = users(:blocked_github_user)
    log_in_as(blocked_user)
    stub_request(:get, 'https://api.github.com/user/repos')
      .to_return(status: 200, body: '', headers: {})
    # Use assert_difference to verify that project record created & email sent
    # This actually raises an exception, so we'll need to catch & ignore it
    # rubocop:disable Style/RescueStandardError
    assert_no_difference [
      'Project.count', 'ActionMailer::Base.deliveries.size'
    ] do
      post '/en/projects', params: { # Routes to 'create'
        project: {
          description: @project.description,
          license: @project.license,
          name: @project.name,
          repo_url: 'https://www.example.org/code',
          homepage_url: @project.homepage_url
        }
      }
    rescue
      # We don't care what the exception is
    end
    # rubocop:enable Style/RescueStandardError
  end

  test 'should fail to create project' do
    log_in_as(@user)
    # We simplify this test by stubbing out the request to GitHub to
    # retrieve information about user repositories.
    # Stub GitHub API request (matches any query parameters)
    stub_request(:get, %r{https://api\.github\.com/user/repos})
      .to_return(status: 200, body: '', headers: {})
    assert_no_difference('Project.count') do # Post routes to 'create'
      post '/en/projects', params: { project: { name: @project.name } }
    end
    assert_no_difference('Project.count') do
      post '/en/projects.json', params: {
        project: { name: @project.name }
      }
    end
  end

  test 'should show project' do
    get "/en/projects/#{@project.id}/passing"
    assert_response :success
    assert_includes @response.body,
                    'What is the human-readable name of the project'
    assert_select(+'a[href=?]', 'https://www.nasa.gov')
    assert_select(+'a[href=?]', 'https://www.nasa.gov/pathfinder')
    # Check semver description, which has HTML - make sure it's not escaped:
    assert @response.body.include?(
      I18n.t('criteria.0.version_semver.description')
    )
    assert_not_includes @response.body, 'target=[^ >]+>'
    assert_includes @response.body, "<img src='/projects/#{@project.id}/badge"
    assert_equal 'Accept-Encoding, Origin', @response.headers['Vary']
  end

  test 'should show passing project' do
    get "/en/projects/#{@perfect_passing_project.id}/passing"
    assert_response :success
    assert_includes @response.body,
                    'What is the human-readable name of the project'
    assert_select(+'a[href=?]', 'https://www.example.org')
    assert_includes @response.body, "<img src='/badge_static/passing'"
    assert_equal 'Accept-Encoding, Origin', @response.headers['Vary']
  end

  test 'should NOT show project if invalid id given' do
    get "/en/projects/#{@project.id}junk"
    assert_response :missing
  end

  test 'should show project with criteria_level=1' do
    # Use "/silver" suffix to indicate criteria_level=1
    get "/en/projects/#{@project.id}/silver"
    assert_response :success
    assert_select(+'a[href=?]', 'https://www.nasa.gov')
    assert_select(+'a[href=?]', 'https://www.nasa.gov/pathfinder')
    only_correct_criteria_selectable('1')
    assert_equal 'Accept-Encoding, Origin', @response.headers['Vary']
  end

  test 'should show project with criteria_level=2' do
    # Use path-based criteria_level
    get "/en/projects/#{@project.id}/gold"
    assert_response :success
    assert_select(+'a[href=?]', 'https://www.nasa.gov')
    assert_select(+'a[href=?]', 'https://www.nasa.gov/pathfinder')
    only_correct_criteria_selectable('2')
  end

  test 'should show project with criteria_level=baseline-1' do
    # Test baseline-1 level view
    get "/en/projects/#{@project.id}/baseline-1"
    assert_response :success
    assert_select(+'a[href=?]', 'https://www.nasa.gov')
    assert_select(+'a[href=?]', 'https://www.nasa.gov/pathfinder')
    only_correct_criteria_selectable('baseline-1')
  end

  test 'should redirect project JSON with locale to non-locale JSON' do
    get "/en/projects/#{@project.id}.json"
    assert_response :moved_permanently
    assert_redirected_to "/projects/#{@project.id}.json"
    follow_redirect!
    assert_response :success
    body = response.parsed_body
    assert_equal 'Pathfinder OS', body['name']
    assert_equal 'Operating system for Pathfinder rover', body['description']
    assert_equal 'https://www.nasa.gov', body['homepage_url']
    assert_equal 'in_progress', body['badge_level']
  end

  test 'should show project JSON data without locale' do
    get "/projects/#{@project.id}.json"
    assert_response :success
    body = response.parsed_body
    assert_equal 'Pathfinder OS', body['name']
    assert_equal 'Operating system for Pathfinder rover', body['description']
    assert_equal 'https://www.nasa.gov', body['homepage_url']
    assert_equal 'in_progress', body['badge_level']
    assert_equal [], body['additional_rights']
  end

  test 'should redirect well-formed criteria_level query param to path' do
    # Legacy URL format: /projects/1?criteria_level=1
    # Handled by redirect_to_default_section action
    # Should redirect to: /projects/1/silver
    get "/en/projects/#{@project.id}?criteria_level=1"
    assert_response :moved_permanently
    assert_redirected_to "/en/projects/#{@project.id}/silver"
  end

  test 'should redirect malformed criteria_level query param to path' do
    # Malformed URL format: /projects/1?criteria_level,2
    # Handled by redirect_to_default_section action
    # Should redirect to: /projects/1/gold
    get "/en/projects/#{@project.id}?criteria_level,2"
    assert_response :moved_permanently
    assert_redirected_to "/en/projects/#{@project.id}/gold"
  end

  test 'should show markdown for all levels when level not said' do
    # Redirects to default section, then follow to get markdown
    get "/en/projects/#{@project.id}.md"
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_includes @response.body, 'The project website MUST provide information on how'
    assert_includes @response.body, 'Passing'
    # When following redirect, we only get the default section (passing)
    # not all levels, so don't assert for Silver/Gold
  end

  test 'should show markdown for one given level' do
    # Use new path-based format instead of query parameter
    get "/en/projects/#{@project.id}/passing.md"
    assert_response :success
    assert_includes @response.body, 'The project website MUST provide information on how'
    assert_includes @response.body, 'Passing'
    assert_not_includes @response.body, 'Silver'
    assert_not_includes @response.body, 'Gold'
  end

  test 'Markdown generates correctly for French' do
    # Use new path-based format instead of query parameter
    get "/fr/projects/#{@project.id}/silver.md"
    assert_response :success
    # Split up text to fool spellchecker. "Project" is easily misspelled
    # and there's no mechanism to disable spellchecking for a specific line.
    assert_includes @response.body,
                    ('Le ' \
                     'pro' \
                     'jet ' + 'DOIT atteindre un badge de niveau basique')
    assert_not_includes @response.body, '[Basique]' # "Passing"
    assert_includes @response.body, '[Argent]' # "Silver"
    assert_not_includes @response.body, 'Passing'
    assert_not_includes @response.body, 'Silver'
    assert_not_includes @response.body, 'Gold'
  end

  test 'should raise error for permissions section in markdown format' do
    # Permissions section doesn't support markdown format
    assert_raises(ActionController::RoutingError) do
      get "/en/projects/#{@project.id}/permissions.md"
    end
  end

  test 'validate_section accepts canonical section names' do
    # Test the defensive validation accepts canonical sections
    controller = ProjectsController.new
    # Should not raise for canonical sections
    Sections::ALL_CANONICAL_NAMES.each do |section|
      assert_nothing_raised do
        controller.send(:validate_section, section)
      end
    end
  end

  test 'validate_section rejects invalid section names' do
    # Test the defensive validation rejects invalid sections
    controller = ProjectsController.new
    # Should raise for invalid sections
    error =
      assert_raises(ActionController::RoutingError) do
        controller.send(:validate_section, 'invalid_section_name')
      end
    assert_match(/Invalid section/, error.message)
  end

  test 'should get edit' do
    log_in_as(@project.user)
    assert_equal(
      'Logged in! Last login: (No previous time recorded.)', flash['success']
    )
    get "/en/projects/#{@project.id}/passing/edit"
    assert_response :success
    assert_includes @response.body, 'Edit Project Badge Status'
  end

  test 'should get edit for baseline-1' do
    log_in_as(@project.user)
    get "/en/projects/#{@project.id}/baseline-1/edit"
    assert_response :success
    assert_includes @response.body, 'Edit Project Badge Status'
  end

  test 'should get edit for silver' do
    log_in_as(@project.user)
    get "/en/projects/#{@project.id}/silver/edit"
    assert_response :success
    assert_includes @response.body, 'Edit Project Badge Status'
  end

  test 'should get edit for gold' do
    log_in_as(@project.user)
    get "/en/projects/#{@project.id}/gold/edit"
    assert_response :success
    assert_includes @response.body, 'Edit Project Badge Status'
  end

  test 'should get edit as additional rights user' do
    test_user = users(:test_user_mark)
    # Create additional rights during test, not as a fixure.
    # The fixture would require correct references to *other* fixture ids.
    new_right = AdditionalRight.new(
      user_id: test_user.id,
      project_id: @project.id
    )
    new_right.save!
    log_in_as(test_user)
    get "/en/projects/#{@project.id}/passing/edit" # Invokes "edit"
    assert_response :success
    assert_includes @response.body, 'Edit Project Badge Status'
  end

  # rubocop:disable Metrics/BlockLength
  test 'can add users with additional rights using "+"' do
    log_in_as(@project.user)
    # Ensure that our test setup is correct & get current state
    assert_not AdditionalRight.exists?(
      project_id: @project.id,
      user_id: users(:test_user_mark).id
    )
    assert_not AdditionalRight.exists?(
      project_id: @project.id,
      user_id: users(:test_user_melissa).id
    )
    assert_not AdditionalRight.exists?(
      project_id: @project.id,
      user_id: @admin.id
    )
    previous_update = @project.updated_at
    # Run patch (the point of the test), which invokes the 'update' method
    patch "/en/projects/#{@project.id}", params: {
      project: { name: @project.name }, # *Something* so not empty.
      additional_rights_changes:
        "+ #{users(:test_user_mark).id}, #{users(:test_user_melissa).id}"
    }
    # Check that results are what was expected
    assert_redirected_to project_section_path(assigns(:project), 'passing')
    assert AdditionalRight.exists?(
      project_id: @project.id,
      user_id: users(:test_user_mark).id
    )
    assert AdditionalRight.exists?(
      project_id: @project.id,
      user_id: users(:test_user_melissa).id
    )
    # Ensure that updated_at has changed
    @project.reload
    assert_not_equal previous_update, @project.updated_at
  end
  # rubocop:enable Metrics/BlockLength

  test 'can remove a user with additional rights using "-"' do
    AdditionalRight.new(
      user_id: users(:test_user_melissa).id,
      project_id: @project.id
    ).save!
    AdditionalRight.new(
      user_id: users(:test_user_mark).id,
      project_id: @project.id
    ).save!
    assert_equal 2, AdditionalRight.for_project(@project.id).count
    log_in_as(@project.user)
    # Run patch (the point of the test), which invokes the 'update' method
    patch "/en/projects/#{@project.id}", params: {
      project: { name: @project.name }, # *Something* so not empty.
      additional_rights_changes:
        "- #{users(:test_user_melissa).id}, #{users(:test_user_mark).id}"
    }
    # TODO: Weird http/https discrepancy in test
    # assert_redirected_to project_section_path(@project, 'passing', locale: :en)
    assert_equal 0, AdditionalRight.for_project(@project.id).count
  end

  # Negative test
  test 'cannot remove a user with only additional rights using "-"' do
    AdditionalRight.new(
      user_id: users(:test_user_melissa).id,
      project_id: @project.id
    ).save!
    AdditionalRight.new(
      user_id: users(:test_user_mark).id,
      project_id: @project.id
    ).save!
    assert_equal 2, AdditionalRight.for_project(@project.id).count
    log_in_as(users(:test_user_melissa))
    # Run patch (the point of the test), which invokes the 'update' method
    patch "/en/projects/#{@project.id}", params: {
      project: { name: @project.name }, # *Something* so not empty.
      additional_rights_changes: "- #{users(:test_user_mark).id}"
    }
    # TODO: Currently we don't report an error if a non-owner
    # tries to remove an "additional rights" user, we just ignore it.
    # If we add an error report, we should check for that error report here.
    assert_redirected_to root_path(locale: 'en')
    assert_equal 2, AdditionalRight.for_project(@project.id).count
  end

  # Negative test
  test 'should not get edit page as user without additional rights' do
    # This *expressly* tests that a normal logged-in
    # user cannot request the edit page of another project's data
    # without authorization.
    # Without additional rights, you can't edit.  This is paired with the
    # previous test, to ensure that *only* the additional right provides
    # the necessary rights.
    test_user = users(:test_user_mark)
    log_in_as(test_user)
    get "/en/projects/#{@project.id}/passing/edit" # Routes to 'edit'
    assert_redirected_to root_url
  end

  # Having trouble translating this test, will do later.
  # test 'should fail to get edit page due to old session' do
  #   log_in_as(@project.user)
  #   assert_equal(
  #     'Logged in! Last login: (No previous time recorded.)', flash['success']
  #   )
  #   session[:time_last_used] = 1000.days.ago.utc
  #   get "/en/projects/#{@project.id}/edit" # Routes to 'edit'
  #   assert_response 302
  #   assert_redirected_to login_path
  #   # follow_redirect!
  #   # refute_includes @response.body, 'Edit Project Badge Status'
  # end

  # test 'should fail to edit due to session time missing' do
  #   log_in_as(@project.user, time_last_used: 1000.days.ago.utc)
  #   session.delete(:time_last_used)
  #   get :edit, params: { id: @project, locale: :en }
  #   assert_response 302
  #   assert_redirected_to login_path
  # end

  test 'should update project (using patch)' do
    log_in_as(@project.user)
    new_name = @project.name + '_updated'
    # Run patch (the point of the test), which invokes the 'update' method
    patch "/en/projects/#{@project.id}", params: {
      project: {
        description: @project.description,
        license: @project.license,
        name: new_name,
        repo_url: @project.repo_url,
        homepage_url: @project.homepage_url
      }
    }
    assert_redirected_to project_section_path(assigns(:project), 'passing')
    follow_redirect! # Follow redirect to /en/projects/:id/passing
    assert_response :success # Should render the show page
    @project.reload
    assert_equal @project.name, new_name
    # Ensure that replied page uses a /badge_static badge image.
    # We omit the specific level, since that will change as automation changes.
    assert_includes @response.body, '/badge_static/'
  end

  test 'should update project (using put)' do
    log_in_as(@project.user)
    new_name = @project.name + '_updated'
    # Run put (the point of the test), which invokes the 'update' method
    # A separate test uses "patch" instead; both should work.
    put "/en/projects/#{@project.id}", params: {
      project: {
        description: @project.description,
        license: @project.license,
        name: new_name,
        repo_url: @project.repo_url,
        homepage_url: @project.homepage_url
      }
    }
    assert_redirected_to project_section_path(assigns(:project), 'passing')
    @project.reload
    assert_equal @project.name, new_name
  end

  test 'should update baseline-1 criteria' do
    log_in_as(@project.user)
    # Update a baseline-1 criterion (osps_ac_01_01)
    patch "/en/projects/#{@project.id}", params: {
      criteria_level: 'baseline-1',
      project: {
        osps_ac_01_01_status: 'Met',
        osps_ac_01_01_justification: 'We use MFA for all contributors'
      }
    }
    # Redirects with criteria_level parameter included
    assert_response :redirect
    @project.reload
    # When it's *stored* it's converted into an integer, so we must
    # check against the integer stored.
    assert_equal CriterionStatus::MET, @project.osps_ac_01_01_status
    assert_equal 'We use MFA for all contributors',
                 @project.osps_ac_01_01_justification
  end

  # Negative test
  test 'should fail to update project if not logged in' do
    # NOTE: no log_in_as
    old_name = @project.name
    new_name = old_name + '_updated'
    # Run patch (the point of the test), which invokes the 'update' method
    patch "/en/projects/#{@project.id}", params: {
      project: {
        description: @project.description,
        license: @project.license,
        name: new_name,
        repo_url: @project.repo_url,
        homepage_url: @project.homepage_url
      }
    }
    # Verify that we didn't really change the name
    @project.reload
    assert_equal @project.name, old_name
  end

  test 'should fail to update project if providing bad URL' do
    log_in_as(@project.user)
    new_project_data = {
      description: '',
      license: '',
      name: '',
      homepage_url: 'example.org' # bad url
    }
    # Run patch (the point of the test), which invokes the 'update' method
    patch "/en/projects/#{@project.id}", params: { project: new_project_data }
    # "Success" here only in the HTTP sense - we *do* get a form...
    assert_response :success
    # ... but we just get the edit form.
    assert_includes @response.body, 'Edit Project Badge Status'

    # Do the same thing, but as for JSON
    patch "/en/projects/#{@project.id}.json", params: {
      project: new_project_data
    }
    assert_response :unprocessable_content
  end

  # rubocop: disable Metrics/BlockLength
  test 'should fail to update stale project due to optimistic locking' do
    # Check for proper handling of project[lock_version] in the HTML like
    # <input type="hidden" value="73" name="project[lock_version]"
    # id="project_lock_version" />
    new_name1 = @project.name + '_updated-1'
    new_project_data1 = { name: new_name1 }
    new_name2 = @project.name + '_updated-2'
    new_project_data2 = {
      name: new_name2,
      lock_version: @project.lock_version
    }
    log_in_as(@project.user)
    patch "/en/projects/#{@project.id}", params: { project: new_project_data1 }
    assert_redirected_to project_section_path(@project, 'passing', locale: :en)
    get "/en/projects/#{@project.id}/passing/edit"
    assert_includes @response.body, 'Edit Project Badge Status'
    assert_includes @response.body, new_name1
    assert_not_includes @response.body, new_name2
    patch "/en/projects/#{@project.id}", params: { project: new_project_data2 }
    assert_includes flash['danger'],
                    'Another user has made a change to that record ' \
                    'since you accessed the edit form.'
    assert_includes @response.body, 'Edit Project Badge Status'
    # Return to the user the *unsaved* values in the edit field, along with
    # the error message. That way, the user can store them separately
    # (say as a printout).
    assert_not_includes @response.body, new_name1
    assert_includes @response.body, new_name2
    # Now reload the actually-stored record to check on what's in the database.
    assert_difference '@project.lock_version' do
      @project.reload
    end
    assert_equal @project.name, new_name1
  end
  # rubocop: enable Metrics/BlockLength

  test 'should fail update project with invalid control in name' do
    log_in_as(@project.user)
    old_name = @project.name
    new_name = @project.name + "\x0c"
    patch "/en/projects/#{@project.id}", params: {
      project: {
        description: @project.description,
        license: @project.license,
        name: new_name,
        repo_url: @project.repo_url,
        homepage_url: @project.homepage_url
      }
    }
    # "Success" here only in the HTTP sense - we *do* get a form...
    assert_response :success
    # ... but we just get the edit form.
    assert_includes @response.body, 'Edit Project Badge Status'
    assert_equal @project.name, old_name
  end

  test 'should fail to update other users project' do
    old_name = @project_two.name
    new_name = old_name + '_updated'
    assert_not_equal @user, @project_two.user
    log_in_as(@user)
    patch "/en/projects/#{@project_two.id}", params: {
      project: { name: new_name }
    }
    assert_redirected_to root_url(locale: :en)
    @project_two.reload
    assert_equal old_name, @project_two.name
  end

  test 'admin can update other users project' do
    new_name = @project.name + '_updated'
    log_in_as(@admin)
    assert_not_equal @admin, @project.user
    patch "/en/projects/#{@project.id}", params: {
      project: { name: new_name }
    }
    assert_redirected_to project_section_path(assigns(:project), 'passing')
    @project.reload
    assert_equal new_name, @project.name
  end

  test 'admin can change owner of other users project' do
    log_in_as(@admin)
    old_user = @project.user
    assert_not_equal @admin.id, old_user.id
    # We SHOULD see the option to change the owner id in the permissions form
    get "/en/projects/#{@project.id}/permissions/edit"
    assert_response :success
    assert_includes @response.body, 'Repeated new owner id'

    # Ensure it won't change if we don't give repeat id
    patch "/en/projects/#{@project.id}", params: {
      project: { user_id: @admin.id }
    }
    assert_redirected_to project_section_path(assigns(:project), 'passing')
    @project.reload
    assert_not_equal @admin.id, @project.user_id
    assert_equal old_user.id, @project.user_id

    # Ensure it won't change if we repeat id doesn't match
    patch "/en/projects/#{@project.id}", params: {
      project: { user_id: @admin.id, repeat_user_id: @admin.id + 1 }
    }
    assert_redirected_to project_section_path(assigns(:project), 'passing')
    @project.reload
    assert_equal old_user.id, @project.user_id

    # Ensure it won't change if user doesn't exist
    # Admin will own this project after this instruction.
    # We'll assume this does not exist :-)
    no_such_uid = 999_999_999_999_999
    patch "/en/projects/#{@project.id}", params: {
      project: { user_id: no_such_uid, user_id_repeat: no_such_uid }
    }
    assert_redirected_to project_section_path(assigns(:project), 'passing')
    @project.reload
    assert_not_equal no_such_uid, @project.user_id
    assert_equal old_user.id, @project.user_id

    # Let's ensure we CAN change it.
    # Admin will own this project after this instruction.
    patch "/en/projects/#{@project.id}", params: {
      project: { user_id: @admin.id, user_id_repeat: @admin.id }
    }
    assert_redirected_to project_section_path(assigns(:project), 'passing')
    @project.reload
    assert_equal @admin.id, @project.user_id
  end

  # We allow normal users of their own project to change
  # the owner to anyone else.
  # If recipient doesn't want it, they can reassign again.
  test 'Normal user change ownership of their own project' do
    # Verify test setup - @project is owned by @user
    assert_equal @project.user_id, @user.id
    log_in_as(@user)

    get "/en/projects/#{@project.id}/permissions/edit"
    assert_response :success
    # We should see the option to change the owner id in the permissions form
    assert_includes @response.body, 'Repeated new owner id'

    # Let's ensure we can change it.
    patch "/en/projects/#{@project.id}", params: {
      project: { user_id: @admin.id, user_id_repeat: @admin.id }
    }
    assert_redirected_to project_section_path(assigns(:project), 'passing')
    @project.reload
    # Notice that ownership has changed.
    assert_equal @project.user_id, @admin.id
  end

  # Don't allow users other than admin or owner to change the owner.
  test 'Normal user cannot change ownership of a project they do not own' do
    test_user = users(:test_user_mark)
    # Create additional rights during test, not as a fixure.
    # The fixture would require correct references to *other* fixture ids.
    new_right = AdditionalRight.new(
      user_id: test_user.id,
      project_id: @project.id
    )
    new_right.save!
    log_in_as(test_user)

    get "/en/projects/#{@project.id}/passing/edit"
    assert_response :success
    # We should NOT see the option to change the owner id
    assert_not_includes @response.body, 'Repeated new owner id'

    # Let's ensure we can't change it.
    patch "/en/projects/#{@project.id}", params: {
      project: { user_id: @admin.id, user_id_repeat: @admin.id }
    }
    assert_redirected_to project_section_path(assigns(:project), 'passing')
    @project.reload
    # Notice that nothing has changed.
    assert_not_equal @project.user_id, @admin.id
  end

  test 'Cannot evade /badge match with /badge/..' do
    get "/projects/#{@perfect_passing_project.id}/badge/..",
        params: { format: 'svg' }
    assert_response :not_found
    assert_equal 'Accept-Encoding, Origin', @response.headers['Vary']
    assert_nil @response.headers['Access-Control-Allow-Origin']
  end

  test 'Cannot evade /badge match with /projects/NUM/../badge' do
    get "/projects/#{@perfect_passing_project.id}/../badge",
        params: { format: 'svg' }
    assert_response :not_found
    assert_equal 'Accept-Encoding', @response.headers['Vary']
    assert_nil @response.headers['Access-Control-Allow-Origin']
  end

  test 'CORS Cannot evade /badge match with /badge.json/..' do
    get "/projects/#{@perfect_passing_project.id}/badge.json/..",
        headers: { Origin: 'example.com' }
    assert_response :not_found
    assert_equal 'Accept-Encoding, Origin', @response.headers['Vary']
    assert_equal '*', @response.headers['Access-Control-Allow-Origin']
  end

  test 'Cannot evade /badge match with /projects/NUM/../badge.json' do
    get "/projects/#{@perfect_passing_project.id}/../badge.json",
        headers: { Origin: 'example.com' }
    assert_response :not_found
    # We don't really care about these for a "not found":
    # assert_equal 'Accept-Encoding', @response.headers['Vary']
    # assert_equal '*', @response.headers['Access-Control-Allow-Origin']
  end

  test 'A perfect passing project should have the passing badge' do
    # NOTICE!! Badge URLs do *NOT* have a locale prefix
    get "/projects/#{@perfect_passing_project.id}/badge",
        params: { format: 'svg' }
    assert_response :success
    assert_equal contents('badge-passing.svg'), @response.body
    # NOTE: Requesters MUST use the ".json"
    # suffix to request the data in JSON format
    # (and NOT use the HTTP Accept header to try to select the output format).
    # Therefore we don't need to include "Accept" as part of "Vary".
    assert_equal 'Accept-Encoding', @response.headers['Vary']
    # No origin stated, so shouldn't see one as a response.
    assert_nil @response.headers['Access-Control-Allow-Origin']
  end

  test 'A perfect passing project requested with CORS' do
    get "/en/projects/#{@project.id}/badge.json",
        headers: { Origin: 'example.com' }
    assert_equal 'Accept-Encoding', @response.headers['Vary']
  end

  test 'A perfect silver project should have the silver badge' do
    @perfect_silver_project = projects(:perfect_silver)
    get "/projects/#{@perfect_silver_project.id}/badge",
        params: { format: 'svg' }
    assert_response :success
    assert_equal contents('badge-silver.svg'), @response.body
  end

  test 'A perfect silver project should have the silver badge in JSON' do
    @perfect_silver_project = projects(:perfect_silver)
    get "/projects/#{@perfect_silver_project.id}/badge.json"
    assert_response :success
    json_data = JSON.parse(@response.body)
    assert_equal 'silver', json_data['badge_level']
    assert_equal @perfect_silver_project.id, json_data['id'].to_i
    assert_equal 'Accept-Encoding', @response.headers['Vary']
  end

  test 'A perfect project should have the gold badge' do
    @perfect_project = projects(:perfect)
    get "/projects/#{@perfect_project.id}/badge"
    assert_response :success
    assert_equal contents('badge-gold.svg'), @response.body
  end

  test 'A perfect unjustified project should have in progress badge' do
    @perfect_unjustified_project = projects(:perfect_unjustified)
    get "/projects/#{@perfect_unjustified_project.id}/badge"
    assert_response :success
    assert_includes @response.body, 'in progress'
  end

  test 'An in-progress project must reply in_progress in JSON' do
    get "/projects/#{@project.id}/badge.json"
    assert_response :success
    json_data = JSON.parse(@response.body)
    assert_equal 'in_progress', json_data['badge_level']
    assert_equal @project.id, json_data['id'].to_i
  end

  test 'An empty project should not have a badge; it should be in progress' do
    get "/projects/#{@project.id}/badge"
    assert_response :success
    assert_includes @response.body, 'in progress'
  end

  test 'Achievement datetimes set' do
    log_in_as(@admin)
    assert_nil @perfect_passing_project.lost_passing_at
    assert_not_nil @perfect_passing_project.achieved_passing_at
    patch "/en/projects/#{@perfect_passing_project.id}", params: {
      project: { interact_status: 'Unmet' }
    }
    follow_redirect!
    @perfect_passing_project.reload
    assert_not_nil @perfect_passing_project.lost_passing_at
    assert @perfect_passing_project.lost_passing_at > 5.minutes.ago.utc
    assert_not_nil @perfect_passing_project.achieved_passing_at
    patch "/en/projects/#{@perfect_passing_project.id}", params: {
      project: { interact_status: 'Met' }
    }
    assert_not_nil @perfect_passing_project.lost_passing_at
    assert_not_nil @perfect_passing_project.achieved_passing_at
    # These tests should work, but don't; it appears our workaround for
    # the inadequately reset database interferes with them.
    # assert @perfect_passing_project.achieved_passing_at > 5.minutes.ago.utc
    # assert @perfect_passing_project.achieved_passing_at >
    #        @perfect_passing_project.lost_passing_at
  end

  test 'Can display delete form' do
    log_in_as(@project.user)
    get "/en/projects/#{@project.id}/delete_form"
    assert_response :success
    assert_includes @response.body, 'Warning'
  end

  test 'should destroy own project if rationale adequate' do
    log_in_as(@project.user)
    num = ActionMailer::Base.deliveries.size
    assert_difference('Project.count', -1) do
      # The "delete" request routes to the controller method "destroy"
      delete "/en/projects/#{@project.id}",
             params: {
               deletion_rationale: 'The front page is not purple enough.'
             }
    end
    assert_equal 'Project was successfully deleted.', flash['success']
    assert_redirected_to projects_path
    assert_equal num + 1, ActionMailer::Base.deliveries.size
  end

  test 'should NOT destroy own project if rationale too short' do
    log_in_as(@project.user)
    assert_no_difference('Project.count',
                         ActionMailer::Base.deliveries.size) do
      delete "/en/projects/#{@project.id}",
             params: { deletion_rationale: 'Nah.' }
    end
    assert_equal 'Must have at least 20 characters.', flash['danger']
    assert_redirected_to delete_form_project_path(@project)
  end

  test 'should NOT destroy own project if rationale has few non-whitespace' do
    log_in_as(@project.user)
    assert_no_difference('Project.count',
                         ActionMailer::Base.deliveries.size) do
      delete "/en/projects/#{@project.id}",
             params: { deletion_rationale: ' x y ' + ("\n" * 30) }
    end
    assert_equal 'Must have at least 15 non-whitespace characters.',
                 flash['danger']
    assert_redirected_to delete_form_project_path(@project)
  end

  test 'Admin can destroy any project' do
    log_in_as(@admin)
    num = ActionMailer::Base.deliveries.size
    assert_not_equal @admin, @project.user
    assert_difference('Project.count', -1) do
      delete "/en/projects/#{@project.id}" # calls controller method "destroy"
    end
    assert_redirected_to projects_path(locale: :en)
    assert_equal num + 1, ActionMailer::Base.deliveries.size
  end

  # Negative test
  test 'should not destroy project if logged in as different user' do
    log_in_as(@user2, password: 'password1')
    # Verify that we are actually logged in
    assert_equal @user2.id, session[:user_id]
    assert_no_difference('Project.count',
                         ActionMailer::Base.deliveries.size) do
      delete "/en/projects/#{@project.id}" # calls controller method "destroy"
    end
  end

  # Negative test
  test 'should not destroy project if not logged in' do
    # Notice that we do *not* call log_in_as.
    assert_no_difference('Project.count',
                         ActionMailer::Base.deliveries.size) do
      delete "/en/projects/#{@project.id}" # calls controller method "destroy"
    end
  end

  test 'should redirect to project page if project repo exists' do
    log_in_as(@user)
    assert_no_difference('Project.count') do
      post '/en/projects', params: { # Routes to 'create'
        project: { repo_url: @project.repo_url }
      }
    end
    assert_redirected_to project_section_path(@project, 'passing', locale: :en)
  end

  test 'should succeed and then fail to change non-blank repo_url' do
    # We rate limit changing repo_url - ensure that works.
    assert @project_two.user.id, @user2.id # Check test fixtures
    log_in_as(@user2, password: 'password1')
    # Verify that we are actually logged in
    assert_equal @user2.id, session[:user_id]
    new_repo_url = @project.repo_url + '_new'
    patch "/en/projects/#{@project_two.id}", params: {
      project: { repo_url:  new_repo_url }
    }
    # Check for success
    @project_two.reload
    assert_equal new_repo_url, @project_two.repo_url

    # Now let's do it again. *This* should fail, it's too soon.
    second_repo_url = new_repo_url + '_second'
    patch "/en/projects/#{@project_two.id}", params: {
      project: { repo_url:  second_repo_url }
    }
    # Ensure the second attempt failed.
    assert_not_empty flash
    assert_includes @response.body, 'Edit Project Badge Status'
    @project_two.reload
    assert_equal new_repo_url, @project_two.repo_url
    assert_not_equal second_repo_url, @project_two.repo_url
  end

  test 'should change https to http in non-blank repo_url' do
    assert_equal @project_two.user.id, @user2.id # Check test fixtures match
    log_in_as(@user2, password: 'password1')
    # Verify that we are actually logged in
    assert_equal @user2.id, session[:user_id]
    old_repo_url = @project_two.repo_url
    new_repo_url = 'http://www.nasa.gov/mav'
    old_description = @project_two.description
    new_description = 'Mars Ascent Vehicle project'

    # Get version count before update
    version_count_before = @project_two.versions.count

    patch "/en/projects/#{@project_two.id}", params: { # Invokes "update"
      project: { repo_url: new_repo_url, description: new_description }
    }
    @project_two.reload

    # Verify fields were updated
    assert_not_equal @project_two.repo_url, old_repo_url
    assert_equal @project_two.repo_url, new_repo_url
    assert_equal @project_two.description, new_description

    # Verify PaperTrail created exactly one new version
    assert_equal version_count_before + 1, @project_two.versions.count

    # Check that PaperTrail properly recorded the version
    last_version = @project_two.versions.last
    assert_equal 'update', last_version.event

    # CRITICAL: Verify whodunnit contains the logged-in user's ID
    # This validates that our user_for_paper_trail override correctly
    # returns @session_user_id set by setup_authentication_state
    assert_equal @user2.id, last_version.whodunnit.to_i

    # Use PaperTrail to retrieve old version and verify old field values
    # This assumes we're storing this using JSON (probably jsonb),
    # *not* the default YAML. YAML stores very specific data types, including
    # a specialized timezone type, that we don't want. By storing with
    # JSON we reduce storage use, increase query speed, and avoid
    # various deserialization problems.
    old_version = last_version.reify
    assert_equal old_repo_url, old_version.repo_url
    assert_equal old_description, old_version.description
  end

  test 'admin can change other users non-blank repo_url' do
    log_in_as(@admin)
    assert_not_equal @admin, @project.user
    new_repo_url = @project.repo_url + '_new'
    patch "/en/projects/#{@project_two.id}", params: { # Invokes "update"
      project: { repo_url: new_repo_url }
    }
    @project_two.reload
    assert_equal @project_two.repo_url, new_repo_url
  end

  test 'should redirect with empty query params removed' do
    get '/en/projects?q=&status=passing' # Calls controller method "index"
    assert_redirected_to '/en/projects?status=passing'
  end

  test 'should redirect with all query params removed' do
    get '/en/projects?q=&status='
    assert_redirected_to '/en/projects'
  end

  test 'should remove invalid parameter' do
    get '/en/projects?bogus1=bogus2&status=passing'
    assert_redirected_to '/en/projects?status=passing'
  end

  test 'query JSON for passing projects' do
    get '/en/projects.json?gteq=100'
    assert_response :success
    body = response.parsed_body
    # We don't want to have to edit this test if we merely add new
    # test fixtures, so we'll just make sure we have at least 3 and
    # do a sanity check of the response.
    assert body.length >= 3
    0.upto(body.length - 1) do |i|
      assert body[i]['badge_percentage_0'] >= 100
    end
  end

  test 'query for passing projects has correct i18n query string' do
    # It'd be easy to drop the query string in cross-referenced locale links,
    # e.g., to refer to "/projects" when we should have "/projects?gteq=100".
    # Many of the Rails url-querying methods intentionally
    # *omit* the query string (which is often fine, but not in this case).
    # Specifically test to ensure the query string is retained.
    #
    get '/en/projects?gteq=100'
    assert_response :success

    # There's a weird test environment artifact I haven't been
    # able to track down.  The view response sometimes has an original url of
    # http://127.0.0.1:31337 and other times it's http://www.example.com.
    # Values such as "request.host" are consistently the second value.
    # This doesn't happen when we only test this file, but instead happens
    # when there's a full "rails test" - which means some other test
    # causes this.  It seems to be an artifact of the test environment, and
    # not actually a bug in the deployed code, so the test here will be
    # flexible to handle the variations that occur in the test environment.
    # See also: static_pages_controller_test.rb

    assert_includes I18n.available_locales, :en
    assert_includes I18n.available_locales, :fr
    I18n.available_locales.each do |loc|
      assert_match \
        %r{<link\ rel="alternate"\ hreflang="#{loc}"
         \ href="https?://[a-z0-9.:]+/#{loc}/projects\?gteq=100"\ />}x,
        @response.body
      # User locale selector (useful for users)
      assert_match \
        %r{<li><a\ href="https?://[a-z0-9.:]+/#{loc}/projects\?gteq=100">}x,
        @response.body
    end
    assert_match \
      %r{<link\ rel="alternate"\ hreflang="x-default"
       \ href="https?://[a-z0-9.:]+/projects\?gteq=100"\ />}x,
      @response.body
  end

  test 'as=badge works in simple case (single result)' do
    expected_id = projects(:perfect).id
    get '/en/projects?as=badge&' \
        'url=https%3A%2F%2Fgithub.com%2Fbestpracticestest%2Ftest-repo-shared'
    assert_redirected_to "/projects/#{expected_id}/badge"
  end

  test 'as=badge works with trailing space and slash' do
    expected_id = projects(:perfect).id
    get '/en/projects?as=badge&' \
        'url=https%3A%2F%2Fgithub.com%2Fbestpracticestest%2Ftest-repo-shared%2F%20'
    assert_redirected_to "/projects/#{expected_id}/badge"
  end

  test 'as=badge works in simple case returning JSON' do
    expected_id = projects(:perfect).id
    get '/en/projects.json?as=badge&' \
        'url=https%3A%2F%2Fgithub.com%2Fbestpracticestest%2Ftest-repo-shared'
    assert_redirected_to "/projects/#{expected_id}/badge.json"
  end

  test 'as=badge redirects simple case when using pq=' do
    expected_id = projects(:perfect).id
    get '/en/projects?as=badge&' \
        'pq=https%3A%2F%2Fgithub.com%2Fbestpracticestest%2Ftest-repo-shared'
    assert_redirected_to "/projects/#{expected_id}/badge"
  end

  test 'as=badge returns status 404 if not found' do
    get '/en/projects?as=badge&url=https%3A%2F%2FNO_SUCH_THING'
    assert_response :not_found
  end

  test 'as=badge returns status 409 (conflict) if >1 match' do
    get '/en/projects?as=badge&pq=https%3A%2F%2F'
    assert_response :conflict
  end

  test 'as=entry works in simple case (single result)' do
    expected_id = projects(:perfect).id
    get '/en/projects?as=entry&' \
        'url=https%3A%2F%2Fgithub.com%2Fbestpracticestest%2Ftest-repo-shared'
    assert_redirected_to "/en/projects/#{expected_id}"
  end

  test 'as=entry quietly returns project list if >1 match' do
    get '/en/projects?as=entry&pq=https%3A%2F%2F'
    assert_response :success
    assert_includes @response.body, 'Projects'
  end

  test 'Check ids= projects index query' do
    # %2c is the comma
    get "/en/projects.json?ids=#{@project.id}%2c#{@project_two.id}"
    follow_redirect!
    assert_response :success
    body = response.parsed_body
    assert_equal 2, body.length
    assert_equal @project.id, body[0]['id']
    assert_equal @project_two.id, body[1]['id']
  end

  test 'should redirect http to https' do
    # Rails.application.config.force_ssl is off in testing, turn it on.
    # This is NOT a thread-safe test.
    old = Rails.application.config.force_ssl
    Rails.application.config.force_ssl = true
    get 'http://test.host/en/projects'
    assert_redirected_to 'https://test.host/en/projects'
    Rails.application.config.force_ssl = old
  end

  test 'sanity test of reminders' do
    # The test framework does not reliably reset the test values for the
    # late_project (we don't know why). So in this test we manually force the
    # correct test values so our test will work reliably.
    # This makes the test reliable (I've re-run "rails test:all" 177 times after doing this),
    # and doing this lets us remove the gem "database_cleaner" (which shouldn't be necessary).
    # We generally want to minimize dependencies, so adding a few lines to set up a test
    # is a good trade-off.

    # Here are debug statements if you want to investigate this again:
    # projects_to_remind = Project.projects_to_remind
    # projects_to_remind_ids = projects_to_remind.map(&:id) # Return a list
    # puts('')
    # puts('Expect: project name=Pathfinder OS id=980190962 badge_percentage_0=0 '
    #      'last_reminder_at= lost_passing_at= updated_at=2000-01-01 00:00:00 UTC')
    # p = projects_to_remind.first
    # p = Project.find_by(id: 980190962)
    # puts("Sanity: project name=#{p.name} id=#{p.id} badge_percentage_0=#{p.badge_percentage_0} '
    #      "last_reminder_at=#{p.last_reminder_at} lost_passing_at=#{p.lost_passing_at} "
    #      "updated_at=#{p.updated_at}")
    # byebug if projects_to_remind_ids.size == 0

    # Manually force the correct test values so our test will work reliably.
    late_project = Project.find_by(name: 'Pathfinder OS')
    late_project.last_reminder_at = nil
    late_project.lost_passing_at = nil
    late_project.save!(touch: false)

    result = ProjectsController.send :send_reminders
    assert_not_equal 0, result.size
    late_project.reload
    assert_not_nil late_project.last_reminder_at
    # assert_equal late_project.id, result[0]
  end

  # This is a unit test of a private method in ProjectsController.
  test 'URL cleaning works' do
    p = ProjectsController.new
    # Use "send" to do unit test of private method.
    assert_equal 'xyz', p.send(:clean_url, 'xyz')
    assert_equal 'xyz', p.send(:clean_url, 'xyz/')
    assert_equal 'xyz', p.send(:clean_url, 'xyz//')
    assert_nil p.send(:clean_url, nil)
    assert_equal 'x/z', p.send(:clean_url, 'x/z')
  end

  # Test repo_data with mock client to check basic functionality
  test 'repo_data with valid github client returns processed repos' do
    controller = ProjectsController.new

    # Mock github client that returns successful data
    mock_github = Object.new
    mock_github.define_singleton_method(:auto_paginate=) { |value| }
    mock_github.define_singleton_method(:repos) do |_user, **_options|
      [
        # rubocop:disable Style/OpenStructUse, Performance/OpenStruct
        OpenStruct.new(
          html_url: 'https://github.com/user/testrepo',
          full_name: 'user/testrepo',
          fork: false,
          homepage: 'https://example.com'
        ),
        OpenStruct.new(
          html_url: 'https://github.com/user/anotherepo',
          full_name: 'user/anotherepo',
          fork: true,
          homepage: nil
        )
        # rubocop:enable Style/OpenStructUse, Performance/OpenStruct
      ]
    end

    result = controller.send(:repo_data, mock_github)

    assert_not_nil result
    assert_equal 2, result.length
    assert_equal 'user/anotherepo', result[0][0] # Should be sorted by name
    assert_equal true, result[0][1] # fork status
    assert_equal 'user/testrepo', result[1][0]
    assert_equal false, result[1][1] # fork status
  end

  test 'repo_data with unauthorized exception returns nil' do
    controller = ProjectsController.new

    # Create a mock object that mimics the Octokit client
    mock_github_class =
      Class.new do
        def auto_paginate=(value)
          # Mock implementation
        end

        def repos(_user, **)
          raise Octokit::Unauthorized.new(response_status: 401, response_body: 'Unauthorized')
        end
      end
    mock_github = mock_github_class.new

    result = controller.send(:repo_data, mock_github)

    assert_nil result
  end

  test 'repo_data with empty repos returns nil' do
    controller = ProjectsController.new

    # Mock github client that returns empty array
    mock_github = Object.new
    mock_github.define_singleton_method(:auto_paginate=) { |value| }
    mock_github.define_singleton_method(:repos) do |_user, **_options|
      []
    end

    result = controller.send(:repo_data, mock_github)

    assert_nil result
  end

  test 'repo_data filters out existing projects' do
    controller = ProjectsController.new
    existing_repo_url = 'https://github.com/user/existingrepo'

    # Create a project with existing repo URL
    # Use fixture directly to avoid class reloading issues
    Project.create!(
      name: 'Existing Project',
      repo_url: existing_repo_url,
      homepage_url: 'https://example.com',
      user: users(:test_user)
    )

    # Mock github client that returns repos including the existing one
    mock_github = Object.new
    mock_github.define_singleton_method(:auto_paginate=) { |value| }
    mock_github.define_singleton_method(:repos) do |_user, **_options|
      [
        # rubocop:disable Style/OpenStructUse, Performance/OpenStruct
        OpenStruct.new(
          html_url: existing_repo_url,
          full_name: 'user/existingrepo',
          fork: false,
          homepage: nil
        ),
        OpenStruct.new(
          html_url: 'https://github.com/user/newrepo',
          full_name: 'user/newrepo',
          fork: false,
          homepage: nil
        )
        # rubocop:enable Style/OpenStructUse, Performance/OpenStruct
      ]
    end

    result = controller.send(:repo_data, mock_github)

    assert_not_nil result
    assert_equal 1, result.length
    assert_equal 'user/newrepo', result[0][0] # Only the new repo should be returned
  end

  test 'repo_data with nil repos returns nil' do
    controller = ProjectsController.new

    # Mock github client that returns nil
    mock_github = Object.new
    mock_github.define_singleton_method(:auto_paginate=) { |value| }
    mock_github.define_singleton_method(:repos) do |_user, **_options|
      nil
    end

    result = controller.send(:repo_data, mock_github)

    assert_nil result
  end

  test 'repo_data sorts repositories by full_name' do
    controller = ProjectsController.new

    # Mock github client with unsorted repos
    mock_github = Object.new
    mock_github.define_singleton_method(:auto_paginate=) { |value| }
    mock_github.define_singleton_method(:repos) do |_user, **_options|
      [
        # rubocop:disable Style/OpenStructUse, Performance/OpenStruct
        OpenStruct.new(
          html_url: 'https://github.com/user/zrepo',
          full_name: 'user/zrepo',
          fork: false,
          homepage: nil
        ),
        OpenStruct.new(
          html_url: 'https://github.com/user/arepo',
          full_name: 'user/arepo',
          fork: true,
          homepage: 'https://example.com'
        )
        # rubocop:enable Style/OpenStructUse, Performance/OpenStruct
      ]
    end

    result = controller.send(:repo_data, mock_github)

    assert_not_nil result
    assert_equal 2, result.length
    assert_equal 'user/arepo', result[0][0] # Should be first after sorting
    assert_equal 'user/zrepo', result[1][0] # Should be second after sorting
  end

  test 'should handle missing criteria_level by redirecting to passing' do
    # When no criteria_level specified, redirect to passing (302)
    get "/en/projects/#{@project.id}"
    assert_response :found # 302
    assert_redirected_to "/en/projects/#{@project.id}/passing"
  end

  test 'should handle bronze as synonym for passing' do
    # Bronze redirects to passing (301)
    get "/en/projects/#{@project.id}/bronze"
    assert_response :moved_permanently
    assert_redirected_to "/en/projects/#{@project.id}/passing"
  end

  test 'should get permissions edit form' do
    log_in_as(@project.user)
    get "/en/projects/#{@project.id}/permissions/edit"
    assert_response :success
    assert_includes @response.body, 'Project Permissions'
    assert_includes @response.body, 'Ownership Transfer'
    assert_includes @response.body, 'Collaborator Management'
    # Should display current additional rights
    assert_includes @response.body, 'Currently:'
  end

  test 'should handle permissions form submission' do
    log_in_as(@project.user)
    get "/en/projects/#{@project.id}/permissions/edit"
    assert_response :success
    # Verify the form can be accessed and rendered
  end

  test 'permissions not accessible by non-owner without rights' do
    log_in_as(@user2)
    get "/en/projects/#{@project.id}/permissions/edit"
    assert_response :redirect
    # Should redirect since user2 is not the owner
  end

  test 'passing form should not contain ownership fields' do
    log_in_as(@project.user)
    get "/en/projects/#{@project.id}/passing/edit"
    assert_response :success
    assert_not_includes @response.body, 'project[user_id_repeat]'
    assert_not_includes @response.body, 'new_owner_repeat'
  end

  test 'passing form should not contain additional_rights fields' do
    log_in_as(@project.user)
    get "/en/projects/#{@project.id}/passing/edit"
    assert_response :success
    assert_not_includes @response.body, 'additional_rights_changes'
  end

  test 'permissions form displays current additional rights' do
    # Add an additional right for testing
    test_user = users(:test_user_mark)
    AdditionalRight.create!(
      user_id: test_user.id,
      project_id: @project.id
    )

    log_in_as(@project.user)
    get "/en/projects/#{@project.id}/permissions/edit"
    assert_response :success

    # Should show the current additional rights with user ID
    assert_includes @response.body, 'Currently:'
    assert_includes @response.body, test_user.id.to_s
  end

  test 'accessing project without criteria_level redirects to passing' do
    get "/en/projects/#{@project.id}"
    assert_response :redirect
    assert_redirected_to "/en/projects/#{@project.id}/passing"
  end

  test 'redirect to passing uses temporary redirect (302)' do
    get "/en/projects/#{@project.id}"
    assert_response :found # Temporary redirect, not 301 permanent
  end

  # Test redirects for paths without locale (should detect locale and redirect)
  test 'project show without locale redirects with locale detection' do
    get "/projects/#{@project.id}",
        headers: { HTTP_ACCEPT_LANGUAGE: 'fr,en-US;q=0.7,en;q=0.3' }
    assert_response :found # 302 temporary (locale redirect)
    # First redirect adds locale
    assert_redirected_to "/fr/projects/#{@project.id}"
    follow_redirect!
    # Second redirect adds default section
    assert_response :found # 302 temporary (section redirect)
    assert_redirected_to "/fr/projects/#{@project.id}/passing"
  end

  test 'project edit without locale redirects with locale detection' do
    log_in_as(@project.user)
    get "/projects/#{@project.id}/edit",
        headers: { HTTP_ACCEPT_LANGUAGE: 'de,en-US;q=0.7,en;q=0.3' }
    # Route doesn't exist - edit requires section parameter
    assert_response :not_found
  end

  # Test redirects for edit paths without criteria_level
  test 'project edit with locale but no criteria_level returns 404' do
    log_in_as(@project.user)
    get "/en/projects/#{@project.id}/edit"
    # Route doesn't exist - edit requires section parameter
    assert_response :not_found
  end

  # Test that markdown redirects to default section with format preserved
  test 'project markdown without locale redirects to default section' do
    get "/projects/#{@project.id}.md",
        headers: { HTTP_ACCEPT_LANGUAGE: 'fr,en-US;q=0.7,en;q=0.3' }
    # First redirect for locale detection
    assert_response :found
    assert_redirected_to "/fr/projects/#{@project.id}.md"
    follow_redirect!
    # Second redirect to default section
    assert_response :found
    assert_redirected_to "/fr/projects/#{@project.id}/passing.md"
  end

  test 'project JSON with locale redirects to non-locale JSON' do
    get "/en/projects/#{@project.id}.json"
    assert_response :moved_permanently
    assert_redirected_to "/projects/#{@project.id}.json"
    follow_redirect!
    assert_response :success
    body = response.parsed_body
    assert_equal 'Pathfinder OS', body['name']
  end

  test 'project markdown with locale redirects to default section markdown' do
    get "/en/projects/#{@project.id}.md"
    assert_response :found
    assert_redirected_to "/en/projects/#{@project.id}/passing.md"
    follow_redirect!
    assert_response :success
    assert_includes @response.body, 'Passing'
  end

  # Unit tests for private helper methods
  test 'current_working_level returns criteria_level for baseline levels' do
    controller = ProjectsController.new
    project = projects(:perfect_passing)
    result = controller.send(:current_working_level, 'baseline-1', project)
    assert_equal 'baseline-1', result
  end

  test 'current_working_level returns project badge_level for non-baseline' do
    controller = ProjectsController.new
    project = projects(:perfect_passing)
    result = controller.send(:current_working_level, 'silver', project)
    assert_equal 'passing', result # project is at passing level
  end

  test 'badge_level_lost? returns false for baseline gain' do
    controller = ProjectsController.new
    result = controller.send(:badge_level_lost?, 'in_progress', 'baseline-1')
    assert_equal false, result
  end

  test 'badge_level_lost? detects loss for baseline level downgrade' do
    controller = ProjectsController.new
    # Going from baseline-2 to baseline-1 is a loss
    result = controller.send(:badge_level_lost?, 'baseline-2', 'baseline-1')
    assert_equal true, result
  end

  test 'badge_level_lost? returns false for baseline level upgrade' do
    controller = ProjectsController.new
    # Going from baseline-1 to baseline-2 is not a loss
    result = controller.send(:badge_level_lost?, 'baseline-1', 'baseline-2')
    assert_equal false, result
  end

  test 'badge_level_lost? detects loss from baseline to in_progress' do
    controller = ProjectsController.new
    result = controller.send(:badge_level_lost?, 'baseline-1', 'in_progress')
    assert_equal true, result
  end

  test 'badge_level_lost? detects loss for traditional levels' do
    controller = ProjectsController.new
    result = controller.send(:badge_level_lost?, 'passing', 'in_progress')
    assert_equal true, result
  end

  test 'update with continue and criteria_level redirects correctly' do
    # Test line 957: continue with criteria_level set
    log_in_as(@project.user)
    patch update_project_path(@project, 'baseline-1'),
          params: {
            project: { name: @project.name },
            continue: 'Quality'
          }
    assert_response :redirect
    # Should redirect to baseline-1/edit with anchor
    assert_redirected_to edit_project_section_path(@project, 'baseline-1') + '#Quality'
  end

  # Test SQL fieldname quoting functionality
  test 'quoted_sql_fieldname quotes field names with non-simple letters' do
    # Field names with mixed case (like 2FA) should be quoted
    result = ProjectsController.quoted_sql_fieldname('require_2FA_status')
    assert_equal '"require_2FA_status"', result,
                 'Field with 2FA should be quoted'

    result = ProjectsController.quoted_sql_fieldname('secure_2FA_justification')
    assert_equal '"secure_2FA_justification"', result,
                 'Field with 2FA should be quoted'

    result = ProjectsController.quoted_sql_fieldname('Field-Name')
    assert_match(/^".*"$/, result,
                 'Field with hyphen should be quoted')

    result = ProjectsController.quoted_sql_fieldname('field name')
    assert_match(/^".*"$/, result,
                 'Field with space should be quoted')
  end

  test 'quoted_sql_fieldname does not quote simple field names' do
    # Simple lowercase field names should not be quoted
    result = ProjectsController.quoted_sql_fieldname('id')
    assert_equal 'id', result,
                 'Simple field id should not be quoted'

    result = ProjectsController.quoted_sql_fieldname('user_id')
    assert_equal 'user_id', result,
                 'Simple field user_id should not be quoted'

    result = ProjectsController.quoted_sql_fieldname('created_at')
    assert_equal 'created_at', result,
                 'Simple field created_at should not be quoted'

    result = ProjectsController.quoted_sql_fieldname('description_good_status')
    assert_equal 'description_good_status', result,
                 'Simple field with multiple underscores should not be quoted'
  end

  # Test defense-in-depth measure in convert_status_params_of_hash!
  # When an invalid status value is provided, it should not be converted
  # so model validation can catch it and provide a proper error message.
  test 'convert_status_params_of_hash! does not convert invalid status values' do
    controller = ProjectsController.new
    test_hash = { description_good_status: 'invalid_value' }

    # Call the private method using send
    controller.send(:convert_status_params_of_hash!, test_hash)

    # Verify the invalid value was NOT converted (left as-is for validation)
    assert_equal 'invalid_value', test_hash[:description_good_status],
                 'Invalid status value should not be converted'
  end

  # Test that valid status values ARE converted
  test 'convert_status_params_of_hash! converts valid status values' do
    controller = ProjectsController.new
    test_hash = { description_good_status: 'Met' }

    controller.send(:convert_status_params_of_hash!, test_hash)

    # Verify the valid value was converted to integer
    assert_equal CriterionStatus::MET, test_hash[:description_good_status],
                 'Valid status value "Met" should be converted to integer 3'
  end

  # Test that empty justification strings are converted to nil
  test 'convert_justification_params_of_hash! converts empty strings to nil' do
    controller = ProjectsController.new
    test_hash = {
      description_good_justification: '',
      know_common_errors_justification: 'Some text'
    }

    controller.send(:convert_justification_params_of_hash!, test_hash)

    # Verify empty string was converted to nil
    assert_nil test_hash[:description_good_justification],
               'Empty justification string should be converted to nil'
    # Verify non-empty string was preserved
    assert_equal 'Some text', test_hash[:know_common_errors_justification],
                 'Non-empty justification should be preserved'
  end

  # Test that nil justifications remain nil
  test 'convert_justification_params_of_hash! preserves nil values' do
    controller = ProjectsController.new
    test_hash = { description_good_justification: nil }

    controller.send(:convert_justification_params_of_hash!, test_hash)

    # Verify nil was preserved
    assert_nil test_hash[:description_good_justification],
               'Nil justification should remain nil'
  end

  # Integration test: verify empty justification strings are converted on update
  test 'empty justification strings converted to nil on update' do
    log_in_as(@admin)

    patch "/en/projects/#{@project.id}", params: {
      project: {
        description_good_justification: '', # Empty string
        name: 'Test Project'
      }
    }

    @project.reload
    assert_nil @project.description_good_justification,
               'Empty justification should be stored as nil in database'
  end

  # Baseline badge tests
  test 'baseline_badge returns SVG for project' do
    get "/projects/#{@project.id}/baseline", params: { format: 'svg' }
    assert_response :success
    assert_includes @response.body, '<svg'
    assert_equal 'image/svg+xml', @response.media_type
  end

  test 'baseline_badge returns JSON for project' do
    get "/projects/#{@project.id}/baseline.json"
    assert_response :success
    json_data = JSON.parse(@response.body)
    assert_equal @project.id, json_data['id']
    assert_equal @project.name, json_data['name']
    # Badge level should be a percentage (0-99) when not achieved
    assert json_data.key?('badge_level')
    assert json_data.key?('badge_percentage')
  end

  test 'baseline_badge has CDN caching headers' do
    get "/projects/#{@project.id}/baseline"
    assert_response :success
    # Verify Vary header for proper CDN caching
    assert_equal 'Accept-Encoding', @response.headers['Vary']
    # Verify Surrogate-Key header for Fastly CDN purging
    # This key is used to purge all cached versions when project data changes
    assert_equal @project.record_key, @response.headers['Surrogate-Key']
  end

  test 'baseline_badge JSON has CDN caching headers' do
    get "/projects/#{@project.id}/baseline.json"
    assert_response :success
    assert_equal 'Accept-Encoding', @response.headers['Vary']
    assert_equal @project.record_key, @response.headers['Surrogate-Key']
  end
end
# rubocop:enable Metrics/ClassLength
