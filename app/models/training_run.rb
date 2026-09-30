class TrainingRun < ApplicationRecord
  belongs_to :project
  belongs_to :dataset

  has_many :training_metrics, dependent: :destroy
  has_many :evaluations, dependent: :destroy
  has_one :model_artifact, dependent: :destroy
  has_one_attached :adapter
  has_one_attached :training_log

  validates :name, presence: true
  validates :base_model, presence: true
  validates :status, presence: true, inclusion: {
    in: %w[pending queued running completed failed cancelled]
  }
  validates :configuration, presence: true

  scope :active, -> { where(status: %w[pending queued running]) }
  scope :completed, -> { where(status: 'completed') }
  scope :recent, -> { order(created_at: :desc) }

  VALID_STATUSES = %w[pending queued running completed failed cancelled].freeze
  ACTIVE_STATUSES = %w[pending queued running].freeze
  TERMINAL_STATUSES = %w[completed failed cancelled].freeze

  DEFAULT_CONFIGURATION = {
    'method' => 'qlora',
    'lora_r' => 16,
    'lora_alpha' => 32,
    'lora_dropout' => 0.05,
    'learning_rate' => 0.0002,
    'epochs' => 3,
    'batch_size' => 1,
    'gradient_accumulation_steps' => 8,
    'max_seq_length' => 2048,
    'quantization' => '4bit_nf4'
  }.freeze

  def active?
    ACTIVE_STATUSES.include?(status)
  end

  def terminal?
    TERMINAL_STATUSES.include?(status)
  end

  def completed?
    status == 'completed'
  end

  def running?
    status == 'running'
  end

  def failed?
    status == 'failed'
  end

  def pending?
    status == 'pending'
  end

  def duration
    return nil unless started_at
    end_time = finished_at || Time.current
    end_time - started_at
  end

  def formatted_duration
    return nil unless duration
    total_seconds = duration.to_i
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    seconds = total_seconds % 60
    if hours > 0
      format('%dh %dm %ds', hours, minutes, seconds)
    elsif minutes > 0
      format('%dm %ds', minutes, seconds)
    else
      format('%ds', seconds)
    end
  end

  def latest_metrics
    training_metrics.order(step: :desc).first
  end

  def latest_loss
    latest_metrics&.loss
  end

  def latest_epoch
    latest_metrics&.epoch
  end

  def total_epochs
    configuration&.dig('epochs') || 3
  end

  def queue!
    update!(status: 'queued')
  end

  def start!
    update!(status: 'running', started_at: Time.current)
  end

  def complete!
    update!(status: 'completed', finished_at: Time.current)
  end

  def fail!(message)
    update!(status: 'failed', finished_at: Time.current, error_message: message)
  end

  def cancel!
    update!(status: 'cancelled', finished_at: Time.current)
  end
end
