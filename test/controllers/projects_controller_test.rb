# frozen_string_literal: true

# Copyright 2015-2017, the Linux Foundation, IDA, and the
# CII Best Practices badge contributors
# SPDX-License-Identifier: MIT

require 'test_helper'

# rubocop:disable Metrics/ClassLength
# TODO: ActionController::TestCase is obsolete. This should switch to using
# ActionDispatch::IntegrationTest and then remove rails-controller-testing.
# See: https://github.com/rails/rails/issues/22496
class ProjectsControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
    @project_two = projects(:two)
    @project_no_repo = projects(:no_repo)
    @perfect_unjustified_project = projects(:perfect_unjustified)
    @perfect_passing_project = projects(:perfect_passing)
    @perfect_silver_project = projects(:perfect_silver)
    @perfect_project = projects(:perfect)
    @user = users(:test_user)
    @user2 = users(:test_user_melissa)
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
    get :index, params: { locale: :en }
    assert_response :success
    assert_not_nil assigns(:projects)
    assert_includes @response.body, 'Badge status'
    refute_includes @response.body, 'target=[^ >]+>'
  end

  test 'new but not logged in' do
    get :new, params: { locale: :en }
    assert_response :success
    assert_includes @response.body, 'Log in with '
  end

  test 'should get new' do
    log_in_as(@user)
    get :new, params: { locale: :en }
    assert_response :success
    assert_includes @response.body,
                    'What is the URL for the project home page ' \
                    '(the URL for the project as a whole)'
  end

  test 'should create project' do
    log_in_as(@user)
    stub_request(:get, 'https://api.github.com/user/repos')
      .to_return(status: 200, body: '', headers: {})
    assert_difference [
      'Project.count', 'ActionMailer::Base.deliveries.size'
    ] do
      post :create, params: {
        project: {
          description: @project.description,
          license: @project.license,
          name: @project.name,
          repo_url: 'https://www.example.org/code',
          homepage_url: @project.homepage_url
        },
        locale: :en
      }
    end
  end

  test 'should create project with empty repo' do
    log_in_as(@user)
    stub_request(:get, 'https://api.github.com/user/repos')
      .to_return(status: 200, body: '', headers: {})
    assert_difference [
      'Project.count', 'ActionMailer::Base.deliveries.size'
    ] do
      post :create, params: {
        project: {
          description: @project.description,
          license: @project.license,
          name: @project.name,
          repo_url: '',
          homepage_url: @project.homepage_url
        },
        locale: :en
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
      post :create, params: {
        project: {
          description: 'Some other project',
          license: @project.license,
          name: @project.name,
          repo_url: @project.repo_url,
          homepage_url: @project_two.homepage_url
        },
        locale: :en
      }
    end
  end

  test 'should fail to create project' do
    log_in_as(@user)
    # We simplify this test by stubbing out the request to GitHub to
    # retrieve information about user repositories.
    url = 'https://api.github.com/user/repos?per_page=50&sort=pushed'
    stub_request(:get, url).to_return(status: 200, body: '', headers: {})
    assert_no_difference('Project.count') do
      post :create, params: { project: { name: @project.name } }
    end
    assert_no_difference('Project.count') do
      post :create, format: :json, params: {
        project: { name: @project.name }
      }
    end
  end

  test 'should show project' do
    get :show, params: { id: @project, locale: :en }
    assert_response :success
    assert_includes @response.body,
                    'What is the human-readable name of the project'
    assert_select(+'a[href=?]', 'https://www.nasa.gov')
    assert_select(+'a[href=?]', 'https://www.nasa.gov/pathfinder')
    # Check semver description, which has HTML - make sure it's not escaped:
    assert @response.body.include?(
      I18n.t('criteria.0.version_semver.description')
    )
    refute_includes @response.body, 'target=[^ >]+>'
  end

  test 'should show project with criteria_level=1' do
    get :show, params: { id: @project, criteria_level: '1', locale: :en }
    assert_response :success
    assert_select(+'a[href=?]', 'https://www.nasa.gov')
    assert_select(+'a[href=?]', 'https://www.nasa.gov/pathfinder')
    only_correct_criteria_selectable('1')
  end

  test 'should show project with criteria_level=2' do
    get :show, params: { id: @project, criteria_level: '2', locale: :en }
    assert_response :success
    assert_select(+'a[href=?]', 'https://www.nasa.gov')
    assert_select(+'a[href=?]', 'https://www.nasa.gov/pathfinder')
    only_correct_criteria_selectable('2')
  end

  test 'should show project JSON data with locale' do
    get :show_json, params: { id: @project, format: :json, locale: :en }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 'Pathfinder OS', body['name']
    assert_equal 'Operating system for Pathfinder rover', body['description']
    assert_equal 'https://www.nasa.gov', body['homepage_url']
    assert_equal 'in_progress', body['badge_level']
  end

  test 'should show project JSON data without locale' do
    get :show_json, params: { id: @project, format: :json }
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
    get :edit, params: { id: @project, locale: :en }
    assert_response :success
    assert_not_empty flash
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
    get :edit, params: { id: @project, locale: :en }
    assert_response :success
    assert_not_empty flash
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
    # Run patch (the point of the test)
    patch :update, params: {
      id: @project,
      project: { name: @project.name }, # *Something* so not empty.
      additional_rights_changes:
        "+ #{users(:test_user_mark).id}, #{users(:test_user_melissa).id}",
      locale: :en
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
    patch :update, params: {
      id: @project.id,
      project: { name: @project.name }, # *Something* so not empty.
      additional_rights_changes:
        "- #{users(:test_user_melissa).id}, #{users(:test_user_mark).id}",
      locale: :en
    }
    # TODO: Weird http/https discrepancy in test
    # assert_redirected_to project_path(@project, locale: :en)
    assert_equal 0, AdditionalRight.where(project_id: @project.id).count
  end

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
    patch :update, params: {
      id: @project.id,
      project: { name: @project.name }, # *Something* so not empty.
      additional_rights_changes:
        "- #{users(:test_user_mark).id}",
      locale: :en
    }
    assert_redirected_to project_path(assigns(:project))
    assert_equal 2, AdditionalRight.where(project_id: @project.id).count
  end

  test 'should not get edit as user without additional rights' do
    # This *expressly* tests that a normal logged-in
    # user cannot edit another project's data without authorization.
    # Without additional rights, can't edit.  This is paired with
    # previous test, to ensure that *only* the additional right provides
    # the necessary rights.  This is a key test: we *prevent* users
    # logged in with one normal account from editing others' data.
    test_user = users(:test_user_mark)
    log_in_as(test_user)
    get :edit, params: { id: @project, locale: :en }
    assert_response 302
    assert_redirected_to root_path
  end

  test 'should fail to edit due to old session' do
    log_in_as(@project.user, time_last_used: 1000.days.ago.utc)
    get :edit, params: { id: @project, locale: :en }
    assert_response 302
    assert_redirected_to login_path
  end

  test 'should fail to edit due to session time missing' do
    log_in_as(@project.user, time_last_used: 1000.days.ago.utc)
    session.delete(:time_last_used)
    get :edit, params: { id: @project, locale: :en }
    assert_response 302
    assert_redirected_to login_path
  end

  test 'should update project' do
    log_in_as(@project.user)
    new_name = @project.name + '_updated'
    patch :update, params: {
      id: @project, locale: :en, project: {
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

  test 'should fail to update project if not logged in' do
    # Note: no log_in_as
    old_name = @project.name
    new_name = old_name + '_updated'
    patch :update, params: {
      id: @project, project: {
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
    patch :update, params: {
      id: @project, project: new_project_data, locale: :en
    }
    # "Success" here only in the HTTP sense - we *do* get a form...
    assert_response :success
    # ... but we just get the edit form.
    assert_template :edit

    # Do the same thing, but as for JSON
    patch :update, params: {
      id: @project, format: :json, project: new_project_data, locale: :en
    }
    assert_response :unprocessable_entity
  end

  test 'should fail to update stale project' do
    new_name1 = @project.name + '_updated-1'
    new_project_data1 = { name: new_name1 }
    new_name2 = @project.name + '_updated-2'
    new_project_data2 = {
      name: new_name2,
      lock_version: @project.lock_version
    }
    log_in_as(@project.user)
    patch :update, params: {
      id: @project, project: new_project_data1, locale: :en
    }
    assert_redirected_to project_path(@project, locale: :en)
    get :edit, params: { id: @project, locale: :en }
    patch :update, params: {
      id: @project, project: new_project_data2, locale: :en
    }
    assert_not_empty flash
    assert_template :edit
    assert_difference '@project.lock_version' do
      @project.reload
    end
    assert_equal @project.name, new_name1
  end

  test 'should fail update project with invalid control in name' do
    log_in_as(@project.user)
    old_name = @project.name
    new_name = @project.name + "\x0c"
    patch :update, params: {
      id: @project, project: {
        description: @project.description,
        license: @project.license,
        name: new_name,
        repo_url: @project.repo_url,
        homepage_url: @project.homepage_url
      },
      locale: :en
    }
    # "Success" here only in the HTTP sense - we *do* get a form...
    assert_response :success
    # ... but we just get the edit form.
    assert_template :edit
    assert_equal @project.name, old_name
  end

  test 'should fail to update other users project' do
    new_name = @project_two.name + '_updated'
    assert_not_equal @user, @project_two.user
    log_in_as(@user)
    patch :update, params: {
      id: @project_two, project: { name: new_name }, locale: :en
    }
    assert_redirected_to root_url(locale: :en)
  end

  test 'admin can update other users project' do
    new_name = @project.name + '_updated'
    log_in_as(@admin)
    assert_not_equal @admin, @project.user
    patch :update, params: {
      id: @project, project: { name: new_name }, locale: :en
    }
    assert_redirected_to project_path(assigns(:project))
    @project.reload
    assert_equal @project.name, new_name
  end

  test 'A perfect passing project should have the passing badge' do
    get :badge,
        params: { id: @perfect_passing_project, format: 'svg', locale: :en }
    assert_response :success
    assert_equal contents('badge-passing.svg'), @response.body
  end

  test 'A perfect silver project should have the silver badge' do
    get :badge,
        params: { id: @perfect_silver_project, format: 'svg', locale: :en }
    assert_response :success
    assert_equal contents('badge-silver.svg'), @response.body
  end

  test 'A perfect silver project should have the silver badge in JSON' do
    get :badge,
        params: { id: @perfect_silver_project, format: 'json', locale: :en }
    assert_response :success
    json_data = JSON.parse(@response.body)
    assert_equal 'silver', json_data['badge_level']
    assert_equal @perfect_silver_project.id, json_data['id'].to_i
  end

  test 'A perfect project should have the gold badge' do
    get :badge, params: { id: @perfect_project, format: 'svg' }
    assert_response :success
    assert_equal contents('badge-gold.svg'), @response.body
  end

  test 'A perfect unjustified project should have in progress badge' do
    get :badge, params: { id: @perfect_unjustified_project, format: 'svg' }
    assert_response :success
    assert_includes @response.body, 'in progress'
  end

  test 'An in-progress project must reply in_progress in JSON' do
    get :badge, params: { id: @project, format: 'json' }
    assert_response :success
    json_data = JSON.parse(@response.body)
    assert_equal 'in_progress', json_data['badge_level']
    assert_equal @project.id, json_data['id'].to_i
  end

  test 'An empty project should not have the badge; it should be in progress' do
    get :badge, params: { id: @project, format: 'svg' }
    assert_response :success
    assert_includes @response.body, 'in progress'
  end

  test 'Achievement datetimes set' do
    log_in_as(@admin)
    assert_nil @perfect_passing_project.lost_passing_at
    assert_not_nil @perfect_passing_project.achieved_passing_at
    patch :update, params: {
      id: @perfect_passing_project, project: {
        interact_status: 'Unmet'
      },
      locale: :en
    }
    @perfect_passing_project.reload
    assert_not_nil @perfect_passing_project.lost_passing_at
    assert @perfect_passing_project.lost_passing_at > 5.minutes.ago.utc
    assert_not_nil @perfect_passing_project.achieved_passing_at
    patch :update, params: {
      id: @perfect_passing_project, project: {
        interact_status: 'Met'
      },
      locale: :en
    }
    assert_not_nil @perfect_passing_project.lost_passing_at
    # These tests should work, but don't; it appears our workaround for
    # the inadequately reset database interferes with them.
    # assert_not_nil @perfect_passing_project.achieved_passing_at
    # assert @perfect_passing_project.achieved_passing_at > 5.minutes.ago.utc
    # assert @perfect_passing_project.achieved_passing_at >
    #        @perfect_passing_project.lost_passing_at
  end

  test 'Can display delete form' do
    log_in_as(@project.user)
    get :delete_form, params: { id: @project, locale: :en }
    assert_response :success
    assert_includes @response.body, 'Warning'
  end

  test 'should destroy own project if rationale adequate' do
    log_in_as(@project.user)
    num = ActionMailer::Base.deliveries.size
    assert_difference('Project.count', -1) do
      delete :destroy,
             params:
             {
               id: @project,
               deletion_rationale: 'The front page is not purple enough.',
               locale: :en
             }
    end
    assert_not_empty flash
    assert_redirected_to projects_path
    assert_equal num + 1, ActionMailer::Base.deliveries.size
  end

  test 'should NOT destroy own project if rationale too short' do
    log_in_as(@project.user)
    assert_no_difference('Project.count', ActionMailer::Base.deliveries.size) do
      delete :destroy,
             params:
             {
               id: @project,
               deletion_rationale: 'Nah.',
               locale: :en
             }
    end
    assert_not_empty flash
    assert_redirected_to delete_form_project_path(@project)
  end

  test 'should NOT destroy own project if rationale has few non-whitespace' do
    log_in_as(@project.user)
    assert_no_difference('Project.count', ActionMailer::Base.deliveries.size) do
      delete :destroy,
             params:
             {
               id: @project,
               deletion_rationale: ' x y ' + ("\n" * 30),
               locale: :en
             }
    end
    assert_not_empty flash
    assert_redirected_to delete_form_project_path(@project)
  end

  test 'Admin can destroy any project' do
    log_in_as(@admin)
    num = ActionMailer::Base.deliveries.size
    assert_not_equal @admin, @project.user
    assert_difference('Project.count', -1) do
      delete :destroy, params: { id: @project, locale: :en }
    end

    assert_redirected_to projects_path(locale: :en)
    assert_equal num + 1, ActionMailer::Base.deliveries.size
  end

  test 'should not destroy project if no one is logged in' do
    log_in_as(@user2)
    assert_no_difference('Project.count', ActionMailer::Base.deliveries.size) do
      delete :destroy, params: { id: @project, locale: :en }
    end
  end

  test 'should not destroy project if logged in as different user' do
    # Notice that we do *not* call log_in_as.
    assert_no_difference('Project.count', ActionMailer::Base.deliveries.size) do
      delete :destroy, params: { id: @project, locale: :en }
    end
  end

  test 'should redirect to project page if project repo exists' do
    log_in_as(@user)
    assert_no_difference('Project.count') do
      post :create, params: {
        project: { repo_url: @project.repo_url }, locale: :en
      }
    end
    assert_redirected_to project_path(@project, locale: :en)
  end

  test 'should succeed and fail to change tail of non-blank repo_url' do
    new_repo_url = @project_two.repo_url + '_new'
    log_in_as(@project_two.user)
    patch :update, params: {
      id: @project_two, project: {
        repo_url:  new_repo_url
      },
      locale: :en
    }
    # Check for success
    @project_two.reload
    assert_equal @project_two.repo_url, new_repo_url

    # Now let's do it again. *This* should fail, it's too soon.
    second_repo_url = new_repo_url + '_second'
    patch :update, params: {
      id: @project_two, project: {
        repo_url:  second_repo_url
      },
      locale: :en
    }
    # Ensure the second attempt failed.
    assert_not_empty flash
    assert_template :edit
    @project_two.reload
    assert_not_equal @project_two.repo_url, second_repo_url
    assert_equal @project_two.repo_url, new_repo_url
  end

  test 'should change https to http in non-blank repo_url' do
    old_repo_url = @project_two.repo_url
    new_repo_url = 'http://www.nasa.gov/mav'
    log_in_as(@project_two.user)
    patch :update, params: {
      id: @project_two, project: {
        repo_url:  new_repo_url
      },
      locale: :en
    }
    @project_two.reload
    assert_not_equal @project_two.repo_url, old_repo_url
    assert_equal @project_two.repo_url, new_repo_url
  end

  test 'admin can change other users non-blank repo_url' do
    new_repo_url = @project_two.repo_url + '_new'
    log_in_as(@admin)
    assert_not_equal @admin, @project.user
    patch :update, params: {
      id: @project_two, project: {
        repo_url:  new_repo_url
      },
      locale: :en
    }
    @project_two.reload
    assert_equal @project_two.repo_url, new_repo_url
  end

  test 'should redirect with empty query params removed' do
    get :index, params: { q: '', status: 'passing', locale: :en }
    assert_redirected_to 'http://test.host/en/projects?status=passing'
  end

  test 'should redirect with all query params removed' do
    get :index, params: { q: '', status: '', locale: :en }
    assert_redirected_to 'http://test.host/en/projects'
  end

  test 'should remove invalid parameter' do
    get :index, params: { role: 'admin', status: 'passing', locale: :en }
    assert_redirected_to 'http://test.host/en/projects?status=passing'
  end

  test 'query JSON for passing projects' do
    get :index, params: { gteq: '100', format: 'json', locale: :en }
    assert_response :success
    body = JSON.parse(response.body)
    # Current test fixtures have 3 cases - this test will need to be
    # modified if new ones are added.
    assert_equal 3, body.length
    0.upto(body.length - 1) do |i|
      assert_equal 100, body[i]['badge_percentage_0']
    end
  end

  test 'query for passing projects has correct i18n query string' do
    # It'd be easy to drop the query string in cross-referenced locale links,
    # e.g., to refer to "/projects" when we should have "/projects?gteq=100".
    # Many of the Rails url-querying methods intentionally
    # *omit* the query string (which is often fine, but not in this case).
    # Specifically test to ensure the query string is retained.
    #
    get :index, params: { gteq: '100', locale: :en }
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

  test 'Check ids= projects index query' do
    get :index, params: {
      format: :json,
      ids: "#{@project.id},#{@project_two.id}",
      locale: :en
    }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body.length
  end

  test 'should redirect http to https' do
    old = Rails.application.config.force_ssl
    Rails.application.config.force_ssl = true
    get :index, params: { locale: :en }
    assert_redirected_to 'https://test.host/en/projects'
    Rails.application.config.force_ssl = old
  end

  test 'sanity test of reminders' do
    result = ProjectsController.send :send_reminders
    assert_equal 1, result.size
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
