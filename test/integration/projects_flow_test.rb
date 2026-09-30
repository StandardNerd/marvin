require 'test_helper'

class ProjectsFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in(users(:demo))
  end

  test 'can view projects' do
    get projects_path
    assert_response :success
    assert_select 'h1', 'Projects'
  end

  test 'can create a project' do
    assert_difference 'Project.count', 1 do
      post projects_path, params: {
        project: { name: 'New Project', base_model: 'Qwen/Qwen3-8B', description: 'Test' }
      }
    end
    assert_redirected_to project_path(Project.last)
  end

  test 'can view a project' do
    get project_path(projects(:support_bot))
    assert_response :success
  end

  test 'can edit a project' do
    patch project_path(projects(:support_bot)), params: {
      project: { name: 'Updated Name' }
    }
    assert_redirected_to project_path(projects(:support_bot))
    projects(:support_bot).reload
    assert_equal 'Updated Name', projects(:support_bot).name
  end

  test 'can delete a project' do
    project = Project.create!(user: users(:demo), name: 'Delete Me', base_model: 'test')
    assert_difference 'Project.count', -1 do
      delete project_path(project)
    end
  end
end
