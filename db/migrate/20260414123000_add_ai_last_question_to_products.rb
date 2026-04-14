class AddAiLastQuestionToProducts < ActiveRecord::Migration[7.2]
  def change
    return if column_exists?(:products, :ai_last_question)

    add_column :products, :ai_last_question, :text
  end
end
