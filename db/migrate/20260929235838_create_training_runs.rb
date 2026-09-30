class CreateTrainingRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :training_runs do |t|
      t.references :project, null: false, foreign_key: true
      t.references :dataset, null: false, foreign_key: true
      t.string :name
      t.string :base_model
      t.string :status, default: "pending"
      t.json :configuration
      t.json :metrics
      t.datetime :started_at
      t.datetime :finished_at
      t.text :error_message

      t.timestamps
    end
  end
end
