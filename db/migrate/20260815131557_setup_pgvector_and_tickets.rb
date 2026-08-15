class SetupPgvectorAndTickets < ActiveRecord::Migration[8.1]
  def change
    # 1. PostgreSQL ka vector math extension enable karna
    enable_extension "vector" unless extension_enabled?("vector")

    # 2. Tickets table structure define karna
    create_table :tickets do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.string :category
      t.string :priority
      t.string :sentiment
      t.string :status, default: "pending", null: false
      
      # 1536-dimensional float array (text-embedding-3-small standard)
      t.vector :embedding, limit: 1536

      t.timestamps
    end

    # 3. Fast semantic search ke liye HNSW vector index
    add_index :tickets, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end