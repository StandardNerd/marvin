require 'test_helper'

class TrainingRunsFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in(users(:demo))
  end

  test 'can view a training run' do
    get project_training_run_path(projects(:support_bot), training_runs(:completed_run))
    assert_response :success
  end

  test 'can create a training run' do
    assert_difference 'TrainingRun.count', 1 do
      post project_training_runs_path(projects(:support_bot)), params: {
        training_run: {
          name: 'new-experiment',
          dataset_id: datasets(:support_v1).id,
          base_model: 'Qwen/Qwen3-8B',
          configuration: {
            lora_r: 16,
            lora_alpha: 32
          }
        }
      }
    end
  end

  test 'can view training metrics as json' do
    get metrics_project_training_run_path(
      projects(:support_bot), training_runs(:completed_run), format: :json
    )
    assert_response :success
    data = JSON.parse(response.body)
    assert_equal 'completed', data['status']
  end

  test 'can start a pending training run' do
    assert_enqueued_with(job: TrainingRunJob) do
      post start_project_training_run_path(
        projects(:support_bot), training_runs(:pending_run)
      )
    end
  end
end
