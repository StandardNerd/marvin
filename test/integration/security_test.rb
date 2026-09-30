require 'test_helper'

class SecurityTest < ActionDispatch::IntegrationTest
  setup do
    sign_in(users(:demo))
  end

  test 'cannot access other users projects' do
    get project_path(projects(:other_project))
    assert_response :not_found
  end

  test 'cannot access other users datasets' do
    get project_dataset_path(projects(:other_project), datasets(:other_dataset))
    assert_response :not_found
  end

  test 'cannot access other users training runs' do
    get project_training_run_path(projects(:other_project), training_runs(:other_run))
    assert_response :not_found
  end
end
