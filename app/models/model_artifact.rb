class ModelArtifact < ApplicationRecord
  belongs_to :training_run

  has_one :project, through: :training_run
  has_one :dataset, through: :training_run

  validates :name, presence: true
  validates :version, presence: true
  validates :base_model, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def adapter_attached?
    training_run.adapter.attached?
  end

  def adapter
    training_run.adapter
  end

  def display_name
    "#{name} #{version}"
  end
end
