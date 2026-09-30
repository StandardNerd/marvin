class Project < ApplicationRecord
  belongs_to :user

  has_many :datasets, dependent: :destroy
  has_many :training_runs, dependent: :destroy
  has_many :model_artifacts, through: :training_runs

  validates :name, presence: true
  validates :base_model, presence: true

  def default_base_model
    ENV.fetch('DEFAULT_BASE_MODEL', 'Qwen/Qwen3-8B')
  end
end
