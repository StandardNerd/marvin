class CreateDatasetExamples < ActiveRecord::Migration[8.1]
  def change
    create_table :dataset_examples do |t|
      t.references :dataset, null: false, foreign_key: true
      t.json :messages
      t.json :metadata
      t.boolean :accepted
      t.json :validation_errors

      t.timestamps
    end
  end
end
