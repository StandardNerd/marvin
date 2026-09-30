require 'test_helper'

class EvaluationTest < ActiveSupport::TestCase
  test 'requires name' do
    e = Evaluation.new(training_run: training_runs(:completed_run), status: 'pending')
    assert_not e.valid?
  end

  test 'requires valid status' do
    e = Evaluation.new(training_run: training_runs(:completed_run), name: 'Test', status: 'invalid')
    assert_not e.valid?
  end

  test 'completed?' do
    assert evaluations(:completed_eval).completed?
  end

  test 'aggregate_score' do
    assert_not_nil evaluations(:completed_eval).aggregate_score
  end
end
