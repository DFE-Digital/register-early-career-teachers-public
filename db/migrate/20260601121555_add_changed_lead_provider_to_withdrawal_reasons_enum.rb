class AddChangedLeadProviderToWithdrawalReasonsEnum < ActiveRecord::Migration[8.1]
  def change
    add_enum_value :withdrawal_reasons, "changed_lead_provider"
  end
end
