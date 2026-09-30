require 'test_helper'

class DatasetProcessingJobTest < ActiveJob::TestCase
  test 'processes valid JSONL' do
    dataset = datasets(:support_v1)
    # Attach a test file
    content = '{"messages":[{"role":"user","content":"Hello"},{"role":"assistant","content":"Hi!"}]}' + "\n"
    content += '{"messages":[{"role":"user","content":"Help"},{"role":"assistant","content":"Sure!"}]}' + "\n"

    dataset.file.attach(
      io: StringIO.new(content),
      filename: 'test.jsonl',
      content_type: 'application/x-jsonl'
    )
    dataset.dataset_examples.destroy_all
    dataset.update!(status: 'uploaded', examples_count: 0)

    DatasetProcessingJob.perform_now(dataset.id)

    dataset.reload
    assert_equal 'ready', dataset.status
    assert_equal 2, dataset.dataset_examples.count
  end

  test 'handles invalid JSON lines' do
    dataset = datasets(:support_v1)
    content = "not valid json\n"
    content += '{"messages":[{"role":"user","content":"Hi"},{"role":"assistant","content":"Hello"}]}' + "\n"

    dataset.file.attach(
      io: StringIO.new(content),
      filename: 'test.jsonl',
      content_type: 'application/x-jsonl'
    )
    dataset.dataset_examples.destroy_all
    dataset.update!(status: 'uploaded', examples_count: 0)

    DatasetProcessingJob.perform_now(dataset.id)

    dataset.reload
    assert_equal 'ready', dataset.status
    assert_equal 1, dataset.dataset_examples.count
  end

  test 'handles missing messages field' do
    dataset = datasets(:support_v1)
    content = '{"data":"no messages"}' + "\n"

    dataset.file.attach(
      io: StringIO.new(content),
      filename: 'test.jsonl',
      content_type: 'application/x-jsonl'
    )
    dataset.dataset_examples.destroy_all
    dataset.update!(status: 'uploaded', examples_count: 0)

    DatasetProcessingJob.perform_now(dataset.id)

    dataset.reload
    assert_equal 'ready', dataset.status
    assert_equal 0, dataset.dataset_examples.count
  end

  test 'handles no file attached' do
    dataset = datasets(:support_v1)
    dataset.file.purge if dataset.file.attached?
    dataset.dataset_examples.destroy_all
    dataset.update!(status: 'uploaded', examples_count: 0)

    DatasetProcessingJob.perform_now(dataset.id)

    dataset.reload
    assert_equal 'failed', dataset.status
  end

  test 'validates roles' do
    dataset = datasets(:support_v1)
    content = '{"messages":[{"role":"invalid_role","content":"test"},{"role":"assistant","content":"ok"}]}' + "\n"

    dataset.file.attach(
      io: StringIO.new(content),
      filename: 'test.jsonl',
      content_type: 'application/x-jsonl'
    )
    dataset.dataset_examples.destroy_all
    dataset.update!(status: 'uploaded', examples_count: 0)

    DatasetProcessingJob.perform_now(dataset.id)

    dataset.reload
    example = dataset.dataset_examples.first
    assert example.has_validation_errors?
  end
end
