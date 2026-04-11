class HardenProductsConstraints < ActiveRecord::Migration[7.2]
  def up
    fail_if_invalid_products_in_production!
    delete_invalid_products_in_non_production!

    backfill_products_price_nulls!
    cast_products_price_to_decimal_10_2!
    enforce_products_column_constraints!
  end

  def down
    change_column_null :products, :seller_id, true
    change_column_null :products, :name, true
    change_column_null :products, :description, true

    change_column_null :products, :price, true
    change_column_default :products, :price, nil
    return if connection.adapter_name.downcase.include?("sqlite")

    execute "ALTER TABLE products ALTER COLUMN price TYPE decimal USING (price::decimal)"
  end

  private

  def fail_if_invalid_products_in_production!
    return unless Rails.env.production?

    invalid_count = select_value(<<~SQL).to_i
      SELECT COUNT(*)
      FROM products
      WHERE seller_id IS NULL
         OR name IS NULL
         OR description IS NULL
    SQL

    return if invalid_count.zero?

    raise ActiveRecord::MigrationError, <<~MSG
      Refusing to harden products constraints in production: found #{invalid_count} invalid row(s).

      Please repair data first, then re-run the migration. Example SQL:
        - Fill seller_id/name/description: UPDATE products SET seller_id = ... WHERE seller_id IS NULL;
        - Or delete truly invalid rows (careful with foreign keys): DELETE FROM products WHERE ...;
    MSG
  end

  def delete_invalid_products_in_non_production!
    return if Rails.env.production?

    invalid_ids_sql = <<~SQL
      SELECT id
      FROM products
      WHERE seller_id IS NULL
         OR name IS NULL
         OR description IS NULL
    SQL

    execute <<~SQL
      DELETE FROM messages
      WHERE conversation_id IN (
        SELECT id FROM conversations WHERE product_id IN (#{invalid_ids_sql})
      )
    SQL

    execute <<~SQL
      DELETE FROM conversations
      WHERE product_id IN (#{invalid_ids_sql})
    SQL

    execute <<~SQL
      DELETE FROM payments
      WHERE transaction_id IN (
        SELECT id FROM transactions WHERE product_id IN (#{invalid_ids_sql})
      )
    SQL

    execute <<~SQL
      DELETE FROM transactions
      WHERE product_id IN (#{invalid_ids_sql})
    SQL

    execute <<~SQL
      DELETE FROM products
      WHERE id IN (#{invalid_ids_sql})
    SQL
  end

  def backfill_products_price_nulls!
    execute "UPDATE products SET price = 0 WHERE price IS NULL"
    change_column_default :products, :price, 0
  end

  def cast_products_price_to_decimal_10_2!
    return if connection.adapter_name.downcase.include?("sqlite")

    price_column = connection.columns(:products).find { |c| c.name == "price" }
    return if price_column.nil?

    if %i[string text].include?(price_column.type)
      execute <<~SQL
        UPDATE products
        SET price = '0'
        WHERE price IS NULL
           OR btrim(price) = ''
           OR price !~ '^[+-]?[0-9]+(\\.[0-9]+)?$'
      SQL
    end

    execute <<~SQL
      ALTER TABLE products
      ALTER COLUMN price TYPE decimal(10,2)
      USING (price::decimal(10,2))
    SQL
  end

  def enforce_products_column_constraints!
    change_column_null :products, :price, false, 0
    change_column_null :products, :seller_id, false
    change_column_null :products, :name, false
    change_column_null :products, :description, false
  end
end
