class ConvertErrorMessagesToAnArrayForPendingInductionSubmissions < ActiveRecord::Migration[8.0]
  def change
    change_table :pending_induction_submissions, bulk: true do |t|
      t.remove :error_message, type: :string
      t.string :error_messages, array: true, default: []
    end
  end
end
