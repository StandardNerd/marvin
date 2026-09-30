require 'test_helper'

class ApiCallbacksTest < ActionDispatch::IntegrationTest
  test 'rejects requests without API key' do
    post metrics_api_v1_training_callback_path(training_runs(:completed_run)),
         params: { step: 1, loss: 1.0 }.to_json,
         headers: { 'Content-Type' => 'application/json' }
    assert_response :unauthorized
  end

  test 'accepts metrics with valid API key' do
    post metrics_api_v1_training_callback_path(training_runs(:completed_run)),
         params: { step: 200, epoch: 3.0, loss: 0.5, learning_rate: 0.0001 }.to_json,
         headers: {
           'Content-Type' => 'application/json',
           'X-API-Key' => 'dev-worker-key'
         }
    assert_response :success
  end

  test 'can complete a training run via callback' do
    post complete_api_v1_training_callback_path(training_runs(:pending_run)),
         headers: {
           'Content-Type' => 'application/json',
           'X-API-Key' => 'dev-worker-key'
         }
    assert_response :success
    training_runs(:pending_run).reload
    assert_equal 'completed', training_runs(:pending_run).status
  end

  test 'can fail a training run via callback' do
    post fail_api_v1_training_callback_path(training_runs(:pending_run)),
         params: { error_message: 'GPU error' }.to_json,
         headers: {
           'Content-Type' => 'application/json',
           'X-API-Key' => 'dev-worker-key'
         }
    assert_response :success
    training_runs(:pending_run).reload
    assert_equal 'failed', training_runs(:pending_run).status
  end
end
