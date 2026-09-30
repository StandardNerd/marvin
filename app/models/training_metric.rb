class TrainingMetric < ApplicationRecord
  belongs_to :training_run

  validates :step, presence: true
  validates :loss, presence: true

  scope :ordered, -> { order(step: :asc) }
  scope :recent, -> { order(step: :desc) }
end
