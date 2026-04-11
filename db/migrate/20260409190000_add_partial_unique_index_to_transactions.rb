class AddPartialUniqueIndexToTransactions < ActiveRecord::Migration[7.2]
  def up
    now_sql = connection.adapter_name.downcase.include?("sqlite") ? "CURRENT_TIMESTAMP" : "NOW()"

    execute <<~SQL
      UPDATE transactions
      SET status = 4,
          updated_at = #{now_sql}
      WHERE id IN (
        SELECT id FROM (
          SELECT id,
                 ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY created_at DESC, id DESC) AS rn
          FROM transactions
          WHERE status = 1
        ) t
        WHERE t.rn > 1
      );
    SQL

    execute <<~SQL
      UPDATE products
      SET sale_status = 0,
          updated_at = #{now_sql}
      WHERE sale_status = 1
        AND NOT EXISTS (
          SELECT 1 FROM transactions
          WHERE transactions.product_id = products.id
            AND transactions.status = 1
        );
    SQL

    execute <<~SQL
      UPDATE transactions
      SET status = 2,
          completed_at = COALESCE(completed_at, #{now_sql}),
          updated_at = #{now_sql}
      WHERE status = 1
        AND product_id IN (
          SELECT id FROM products WHERE sale_status = 2
        );
    SQL

    add_index :transactions,
              :product_id,
              unique: true,
              where: "status = 1",
              name: "idx_only_one_active_transaction_per_product"
  end

  def down
    remove_index :transactions, name: "idx_only_one_active_transaction_per_product"
  end
end
