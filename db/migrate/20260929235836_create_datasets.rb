class CreateDatasets < ActiveRecord::Migration[8.1]
  def change
    create_table :datasets do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.string :format
      t.string :status, default: "uploaded"
      t.integer :examples_count, default: 0

      t.timestamps
    end
  end
end
