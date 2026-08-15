class ChangeTicketEmbeddingDimension < ActiveRecord::Migration[8.1]
  def up
    remove_index :tickets, :embedding if index_exists?(:tickets, :embedding)
    change_column :tickets, :embedding, :vector, limit: 768
    add_index :tickets, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end

  def down
    remove_index :tickets, :embedding if index_exists?(:tickets, :embedding)
    change_column :tickets, :embedding, :vector, limit: 1536
    add_index :tickets, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
