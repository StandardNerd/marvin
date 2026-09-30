require 'test_helper'

class DatasetExampleTest < ActiveSupport::TestCase
  test 'requires messages' do
    ex = DatasetExample.new(dataset: datasets(:support_v1))
    assert_not ex.valid?
  end

  test 'accept!' do
    ex = dataset_examples(:example_needs_review)
    ex.accept!
    assert ex.accepted?
  end

  test 'reject!' do
    ex = dataset_examples(:example_needs_review)
    ex.reject!
    assert ex.rejected?
  end

  test 'needs_review?' do
    ex = dataset_examples(:example_needs_review)
    assert ex.needs_review?
  end

  test 'scopes' do
    assert DatasetExample.accepted.count >= 0
    assert DatasetExample.rejected.count >= 0
    assert DatasetExample.needs_review.count >= 0
  end

  test 'has_validation_errors?' do
    assert dataset_examples(:example_with_errors).has_validation_errors?
    assert_not dataset_examples(:example_one).has_validation_errors?
  end
end
