require 'test_helper'

class ExperimentsFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in(users(:demo))
  end

  test 'can view all experiments' do
    get experiments_path
    assert_response :success
  end

  test 'can compare experiments' do
    ids = [training_runs(:completed_run).id, training_runs(:pending_run).id].join(',')
    get compare_experiments_path(ids: ids)
    assert_response :success
  end
end
