class RemoveSchoolURNFromSchoolFundingEligibilities < ActiveRecord::Migration[8.0]
  def up
    remove_foreign_key :school_funding_eligibilities, :schools,
                       column: :school_urn,
                       primary_key: :urn

    remove_column :school_funding_eligibilities, :school_urn
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
