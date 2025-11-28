class AddMentorFundingEnabledToContractPeriods < ActiveRecord::Migration[8.0]
  def change
    add_column :contract_periods, :mentor_funding_enabled, :boolean, null: false, default: false
  end
end
