class MakePaymentsTransactionIdNullable < ActiveRecord::Migration[7.2]
  def change
    change_column_null :payments, :transaction_id, true
  end
end
