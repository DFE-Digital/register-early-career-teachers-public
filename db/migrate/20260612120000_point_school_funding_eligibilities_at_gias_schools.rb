class PointSchoolFundingEligibilitiesAtGiasSchools < ActiveRecord::Migration[8.0]
  def up
    remove_foreign_key :school_funding_eligibilities, :schools,
                       column: :school_urn,
                       primary_key: :urn

    add_foreign_key :school_funding_eligibilities, :gias_schools,
                    column: :school_urn,
                    primary_key: :urn
  end

  def down
    remove_foreign_key :school_funding_eligibilities, :gias_schools,
                       column: :school_urn,
                       primary_key: :urn

    add_foreign_key :school_funding_eligibilities, :schools,
                    column: :school_urn,
                    primary_key: :urn
  end
end
