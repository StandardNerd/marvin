require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  test 'requires name' do
    project = Project.new(user: users(:demo), base_model: 'test')
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end

  test 'requires base_model' do
    project = Project.new(user: users(:demo), name: 'Test')
    assert_not project.valid?
    assert_includes project.errors[:base_model], "can't be blank"
  end

  test 'valid project' do
    project = Project.new(user: users(:demo), name: 'Test', base_model: 'Qwen/Qwen3-8B')
    assert project.valid?
  end

  test 'has many datasets' do
    assert_respond_to projects(:support_bot), :datasets
  end

  test 'has many training_runs' do
    assert_respond_to projects(:support_bot), :training_runs
  end
end
