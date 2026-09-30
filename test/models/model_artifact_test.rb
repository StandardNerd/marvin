require 'test_helper'

class ModelArtifactTest < ActiveSupport::TestCase
  test 'requires name' do
    a = ModelArtifact.new(training_run: training_runs(:completed_run), version: 'v1', base_model: 'test')
    assert_not a.valid?
  end

  test 'requires version' do
    a = ModelArtifact.new(training_run: training_runs(:completed_run), name: 'test', base_model: 'test')
    assert_not a.valid?
  end

  test 'display_name' do
    assert_equal 'support-assistant v1', model_artifacts(:support_adapter).display_name
  end
end
