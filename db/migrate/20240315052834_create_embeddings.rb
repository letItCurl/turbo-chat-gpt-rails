class CreateEmbeddings < ActiveRecord::Migration[7.1]
  def up
    create_table :embeddings, id: :uuid do |t|
      t.string :url
      t.text :text
      t.integer :version
      t.timestamps
    end

    sql = "ALTER TABLE embeddings ADD COLUMN embedding vector(1536);"
    ActiveRecord::Base.connection.execute(sql)
  end

  def down
    drop_table :embeddings
  end
end
