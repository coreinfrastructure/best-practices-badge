# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# OpenSSF Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

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
    url = 'https://api.github.com/user/repos?per_page=50&sort=pushed'
    stub_request(:get, url).to_return(status: 200, body: '', headers: {})
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
    get "/en/projects/#{@project.id}"
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
    get "/en/projects/#{@perfect_passing_project.id}"
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

  # DEPRECATED CAPABILITY. We eventually want to require people to use
  # "/en/projects/:id.json" if they want JSON. However, as long as this
  # capability exists, we should test that it works. We also want to test
  # that it has STOPPED working once we've removed that functionality.
  # We have documented this deprecation in doc/api.md.
  test 'should project JSON data if HTTP header Accept: application/json ' do
    get "/en/projects/#{@project.id}", headers: { Accept: 'application/json' }
    assert_response :success
    # The JSON looks like {...} and has "id", while the HTML does not.
    assert_equal '{', response.body[0]
    assert_equal '}', response.body[-1]
    assert_includes response.body, '"id"'
  end

  test 'should show project with criteria_level=1' do
    # Use "/1" suffix to indicate criteria_level=1
    get "/en/projects/#{@project.id}/1"
    assert_response :success
    assert_select(+'a[href=?]', 'https://www.nasa.gov')
    assert_select(+'a[href=?]', 'https://www.nasa.gov/pathfinder')
    only_correct_criteria_selectable('1')
    assert_equal 'Accept-Encoding, Origin', @response.headers['Vary']
  end

  test 'should show project with criteria_level=2' do
    # Use parameter criteria_level
    get "/en/projects/#{@project.id}?criteria_level=2"
    assert_response :success
    assert_select(+'a[href=?]', 'https://www.nasa.gov')
    assert_select(+'a[href=?]', 'https://www.nasa.gov/pathfinder')
    only_correct_criteria_selectable('2')
  end

  test 'should show project JSON data with locale' do
    get "/en/projects/#{@project.id}.json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 'Pathfinder OS', body['name']
    assert_equal 'Operating system for Pathfinder rover', body['description']
    assert_equal 'https://www.nasa.gov', body['homepage_url']
    assert_equal 'in_progress', body['badge_level']
  end

  test 'should show project JSON data without locale' do
    get "/projects/#{@project.id}.json"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 'Pathfinder OS', body['name']
    assert_equal 'Operating system for Pathfinder rover', body['description']
    assert_equal 'https://www.nasa.gov', body['homepage_url']
    assert_equal 'in_progress', body['badge_level']
    assert_equal [], body['additional_rights']
  end

  test 'should get edit' do
    log_in_as(@project.user)
    assert_equal(
      'Logged in! Last login: (No previous time recorded.)', flash['success']
    )
    get "/en/projects/#{@project.id}/edit"
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
    get "/en/projects/#{@project.id}/edit" # Invokes "edit"
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
    assert_redirected_to project_path(assigns(:project))
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
    assert_equal 2, AdditionalRight.where(project_id: @project.id).count
    log_in_as(@project.user)
    # Run patch (the point of the test), which invokes the 'update' method
    patch "/en/projects/#{@project.id}", params: {
      project: { name: @project.name }, # *Something* so not empty.
      additional_rights_changes:
        "- #{users(:test_user_melissa).id}, #{users(:test_user_mark).id}"
    }
    # TODO: Weird http/https discrepancy in test
    # assert_redirected_to project_path(@project, locale: :en)
    assert_equal 0, AdditionalRight.where(project_id: @project.id).count
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
    assert_equal 2, AdditionalRight.where(project_id: @project.id).count
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
    assert_equal 2, AdditionalRight.where(project_id: @project.id).count
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
    get "/en/projects/#{@project.id}/edit" # Routes to 'edit'
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
    assert_redirected_to project_path(assigns(:project))
    follow_redirect!
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
    assert_redirected_to project_path(assigns(:project))
    @project.reload
    assert_equal @project.name, new_name
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
    assert_response :unprocessable_entity
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
    assert_redirected_to project_path(@project, locale: :en)
    get "/en/projects/#{@project.id}/edit"
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
    assert_redirected_to project_path(assigns(:project))
    @project.reload
    assert_equal new_name, @project.name
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
    # NOTE: Requestors MUST use the ".json"
    # suffix to requst the data in JSON format
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
    assert_redirected_to project_path(@project, locale: :en)
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
    assert @project_two.user.id, @user2.id # Check test fixtures
    log_in_as(@user2, password: 'password1')
    # Verify that we are actually logged in
    assert_equal @user2.id, session[:user_id]
    old_repo_url = @project_two.repo_url
    new_repo_url = 'http://www.nasa.gov/mav'
    patch "/en/projects/#{@project_two.id}", params: { # Invokes "update"
      project: { repo_url:  new_repo_url }
    }
    @project_two.reload
    assert_not_equal @project_two.repo_url, old_repo_url
    assert_equal @project_two.repo_url, new_repo_url
    # Check that PaperTrail properly recorded the old version
    assert_equal 'update', @project_two.versions.last.event
    assert_equal @project_two.user.id,
                 @project_two.versions.last.whodunnit.to_i
    assert_equal old_repo_url, @project_two.versions.last.reify.repo_url
  end

  test 'admin can change other users non-blank repo_url' do
    log_in_as(@admin)
    assert_not_equal @admin, @project.user
    new_repo_url = @project.repo_url + '_new'
    patch "/en/projects/#{@project_two.id}", params: { # Invokes "update"
      project: { repo_url:  new_repo_url }
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
    body = JSON.parse(response.body)
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
        'url=https%3A%2F%2Fgithub.com%2Fciitest2%2Ftest-repo-shared'
    assert_redirected_to "/projects/#{expected_id}/badge"
  end

  test 'as=badge works with trailing space and slash' do
    expected_id = projects(:perfect).id
    get '/en/projects?as=badge&' \
        'url=https%3A%2F%2Fgithub.com%2Fciitest2%2Ftest-repo-shared%2F%20'
    assert_redirected_to "/projects/#{expected_id}/badge"
  end

  test 'as=badge works in simple case returning JSON' do
    expected_id = projects(:perfect).id
    get '/en/projects.json?as=badge&' \
        'url=https%3A%2F%2Fgithub.com%2Fciitest2%2Ftest-repo-shared'
    assert_redirected_to "/projects/#{expected_id}/badge.json"
  end

  test 'as=badge redirects simple case when using pq=' do
    expected_id = projects(:perfect).id
    get '/en/projects?as=badge&' \
        'pq=https%3A%2F%2Fgithub.com%2Fciitest2%2Ftest-repo-shared'
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
        'url=https%3A%2F%2Fgithub.com%2Fciitest2%2Ftest-repo-shared'
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
    body = JSON.parse(response.body)
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
    assert_equal 1, result.size
    assert_equal late_project.id, result[0]
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
end
# rubocop:enable Metrics/ClassLength
