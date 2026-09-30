require 'test_helper'

class DatasetTest < ActiveSupport::TestCase
  test 'requires name' do
    ds = Dataset.new(project: projects(:support_bot), format: 'jsonl', status: 'uploaded')
    assert_not ds.valid?
    assert_includes ds.errors[:name], "can't be blank"
  end

  test 'requires valid format' do
    ds = Dataset.new(project: projects(:support_bot), name: 'test', format: 'csv', status: 'uploaded')
    assert_not ds.valid?
  end

  test 'requires valid status' do
    ds = Dataset.new(project: projects(:support_bot), name: 'test', format: 'jsonl', status: 'invalid')
    assert_not ds.valid?
  end

  test 'accepted_count' do
    count = datasets(:support_v1).accepted_count
    assert count >= 0
  end

  test 'rejected_count' do
    count = datasets(:support_v1).rejected_count
    assert count >= 0
  end

  test 'needs_review_count' do
    count = datasets(:support_v1).needs_review_count
    assert count >= 0
  end

  test 'ready scope' do
    assert Dataset.ready.include?(datasets(:support_v1))
  end
end
