require 'test_helper'

class TrainingRunTest < ActiveSupport::TestCase
  test 'requires name' do
    tr = TrainingRun.new(project: projects(:support_bot), dataset: datasets(:support_v1),
                         base_model: 'test', status: 'pending', configuration: {})
    assert_not tr.valid?
  end

  test 'requires valid status' do
    tr = TrainingRun.new(project: projects(:support_bot), dataset: datasets(:support_v1),
                         name: 'test', base_model: 'test', status: 'invalid', configuration: {})
    assert_not tr.valid?
  end

  test 'requires configuration' do
    tr = TrainingRun.new(project: projects(:support_bot), dataset: datasets(:support_v1),
                         name: 'test', base_model: 'test', status: 'pending')
    assert_not tr.valid?
  end

  test 'status transitions' do
    tr = training_runs(:pending_run)
    assert tr.pending?
    assert tr.active?
    assert_not tr.terminal?

    tr.queue!
    assert_equal 'queued', tr.status

    tr.start!
    assert_equal 'running', tr.status
    assert_not_nil tr.started_at

    tr.complete!
    assert_equal 'completed', tr.status
    assert_not_nil tr.finished_at
    assert tr.terminal?
  end

  test 'fail! sets error message' do
    tr = training_runs(:pending_run)
    tr.fail!('Something went wrong')
    assert_equal 'failed', tr.status
    assert_equal 'Something went wrong', tr.error_message
  end

  test 'cancel!' do
    tr = training_runs(:pending_run)
    tr.cancel!
    assert_equal 'cancelled', tr.status
  end

  test 'formatted_duration' do
    tr = training_runs(:completed_run)
    assert_not_nil tr.formatted_duration
  end

  test 'DEFAULT_CONFIGURATION' do
    config = TrainingRun::DEFAULT_CONFIGURATION
    assert_equal 'qlora', config['method']
    assert_equal 16, config['lora_r']
  end
end
