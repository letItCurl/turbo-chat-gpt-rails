class CreateEmbeddings < ActiveRecord::Migration[7.1]
  def change
    create_table :embeddings, id: :uuid do |t|
      t.string :url
      t.text :text
      t.integer :version
      t.vector :embedding, limit: 1536
      t.timestamps
    end
  end
end
