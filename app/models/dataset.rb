class Dataset < ApplicationRecord
  belongs_to :project

  has_many :dataset_examples, dependent: :destroy
  has_many :training_runs, dependent: :restrict_with_error
  has_one_attached :file

  validates :name, presence: true
  validates :format, presence: true, inclusion: { in: %w[jsonl] }
  validates :status, presence: true, inclusion: { in: %w[uploaded processing ready failed] }

  scope :ready, -> { where(status: 'ready') }

  def accepted_count
    dataset_examples.where(accepted: true).count
  end

  def rejected_count
    dataset_examples.where(accepted: false).count
  end

  def needs_review_count
    dataset_examples.where(accepted: nil).count
  end

  def with_errors_count
    dataset_examples.where.not(validation_errors: nil).where.not(validation_errors: '[]').count
  end

  def ready?
    status == 'ready'
  end

  def processing?
    status == 'processing'
  end
end
