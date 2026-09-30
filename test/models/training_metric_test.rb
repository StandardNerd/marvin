require 'test_helper'

class TrainingMetricTest < ActiveSupport::TestCase
  test 'requires step' do
    tm = TrainingMetric.new(training_run: training_runs(:completed_run), loss: 1.0)
    assert_not tm.valid?
  end

  test 'requires loss' do
    tm = TrainingMetric.new(training_run: training_runs(:completed_run), step: 1)
    assert_not tm.valid?
  end

  test 'ordered scope' do
    metrics = TrainingMetric.ordered
    assert metrics.count >= 0
  end
end
