class CreateTrainingMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :training_metrics do |t|
      t.references :training_run, null: false, foreign_key: true
      t.integer :step
      t.float :epoch
      t.float :loss
      t.float :learning_rate
      t.json :raw_metrics

      t.timestamps
    end
  end
end
