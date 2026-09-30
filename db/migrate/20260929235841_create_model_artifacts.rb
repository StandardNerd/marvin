class CreateModelArtifacts < ActiveRecord::Migration[8.1]
  def change
    create_table :model_artifacts do |t|
      t.references :training_run, null: false, foreign_key: true
      t.string :name
      t.string :version
      t.string :base_model
      t.text :description
      t.integer :file_size

      t.timestamps
    end
  end
end
