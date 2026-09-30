class DatasetExample < ApplicationRecord
  belongs_to :dataset, counter_cache: :examples_count

  validates :messages, presence: true

  scope :accepted, -> { where(accepted: true) }
  scope :rejected, -> { where(accepted: false) }
  scope :needs_review, -> { where(accepted: nil) }
  scope :with_errors, -> { where.not(validation_errors: nil).where.not(validation_errors: '[]') }

  def accept!
    update!(accepted: true)
  end

  def reject!
    update!(accepted: false)
  end

  def needs_review?
    accepted.nil?
  end

  def accepted?
    accepted == true
  end

  def rejected?
    accepted == false
  end

  def has_validation_errors?
    validation_errors.present? && validation_errors != []
  end

  def conversation_messages
    messages || []
  end
end
