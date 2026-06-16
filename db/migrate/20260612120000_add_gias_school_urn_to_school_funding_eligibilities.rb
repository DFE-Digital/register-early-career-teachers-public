class AddGIASSchoolURNToSchoolFundingEligibilities < ActiveRecord::Migration[8.0]
  def up
    add_column :school_funding_eligibilities, :gias_school_urn, :bigint
    add_index :school_funding_eligibilities, :gias_school_urn

    execute(<<~SQL)
      UPDATE school_funding_eligibilities
      SET gias_school_urn = school_urn
      WHERE gias_school_urn IS NULL
    SQL

    change_column_null :school_funding_eligibilities, :gias_school_urn, false

    add_foreign_key :school_funding_eligibilities, :gias_schools,
                    column: :gias_school_urn,
                    primary_key: :urn

    change_column_null :school_funding_eligibilities, :school_urn, true
  end

  def down
    change_column_null :school_funding_eligibilities, :school_urn, false

    remove_foreign_key :school_funding_eligibilities, :gias_schools,
                       column: :gias_school_urn,
                       primary_key: :urn

    remove_column :school_funding_eligibilities, :gias_school_urn
  end
end
