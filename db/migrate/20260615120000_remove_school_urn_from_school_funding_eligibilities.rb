class RemoveSchoolURNFromSchoolFundingEligibilities < ActiveRecord::Migration[8.0]
  def up
    remove_foreign_key :school_funding_eligibilities, :schools,
                       column: :school_urn,
                       primary_key: :urn

    remove_column :school_funding_eligibilities, :school_urn
  end

  def down
    add_column :school_funding_eligibilities, :school_urn, :bigint
    add_index :school_funding_eligibilities, :school_urn

    execute(<<~SQL)
      UPDATE school_funding_eligibilities
      SET school_urn = gias_school_urn
      WHERE school_urn IS NULL
    SQL

    add_foreign_key :school_funding_eligibilities, :schools,
                    column: :school_urn,
                    primary_key: :urn
  end
end
