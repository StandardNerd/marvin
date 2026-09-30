class Evaluation < ApplicationRecord
  belongs_to :training_run

  validates :name, presence: true
  validates :status, presence: true, inclusion: {
    in: %w[pending running completed failed]
  }

  VALID_STATUSES = %w[pending running completed failed].freeze

  def completed?
    status == 'completed'
  end

  def running?
    status == 'running'
  end

  def failed?
    status == 'failed'
  end

  def aggregate_score
    metrics&.dig('aggregate_score')
  end

  def exact_match_score
    metrics&.dig('exact_match')
  end

  def similarity_score
    metrics&.dig('text_similarity')
  end
end
