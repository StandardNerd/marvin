class CreateEvaluations < ActiveRecord::Migration[8.1]
  def change
    create_table :evaluations do |t|
      t.references :training_run, null: false, foreign_key: true
      t.string :name
      t.string :status, default: "pending"
      t.json :metrics
      t.json :results

      t.timestamps
    end
  end
end
