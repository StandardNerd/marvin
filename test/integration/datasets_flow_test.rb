require 'test_helper'

class DatasetsFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in(users(:demo))
  end

  test 'can view a dataset' do
    get project_dataset_path(projects(:support_bot), datasets(:support_v1))
    assert_response :success
  end

  test 'can filter examples' do
    get project_dataset_path(projects(:support_bot), datasets(:support_v1), filter: 'accepted')
    assert_response :success
  end

  test 'can upload a dataset' do
    content = '{"messages":[{"role":"user","content":"Hi"},{"role":"assistant","content":"Hello"}]}'
    file = Rack::Test::UploadedFile.new(StringIO.new(content), 'application/x-jsonl', original_filename: 'test.jsonl')

    assert_difference 'Dataset.count', 1 do
      post project_datasets_path(projects(:support_bot)), params: {
        dataset: {
          name: 'test-upload',
          file: file
        }
      }
    end
  end

  test 'can accept an example' do
    example = dataset_examples(:example_needs_review)
    post accept_project_dataset_dataset_example_path(
      projects(:support_bot), datasets(:support_v1), example
    )
    example.reload
    assert example.accepted?
  end

  test 'can reject an example' do
    example = dataset_examples(:example_needs_review)
    post reject_project_dataset_dataset_example_path(
      projects(:support_bot), datasets(:support_v1), example
    )
    example.reload
    assert example.rejected?
  end

  test 'can delete an example' do
    example = dataset_examples(:example_rejected)
    assert_difference 'DatasetExample.count', -1 do
      delete project_dataset_dataset_example_path(
        projects(:support_bot), datasets(:support_v1), example
      )
    end
  end

  test 'bulk accept' do
    post bulk_action_project_dataset_dataset_examples_path(
      projects(:support_bot), datasets(:support_v1)
    ), params: {
      bulk_action: 'accept',
      example_ids: [dataset_examples(:example_needs_review).id]
    }
    dataset_examples(:example_needs_review).reload
    assert dataset_examples(:example_needs_review).accepted?
  end
end
