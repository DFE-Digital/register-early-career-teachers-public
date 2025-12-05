class RemoveGIASSchoolsFundingEligibility < ActiveRecord::Migration[8.0]
  def change
    remove_column :gias_schools, :funding_eligibility, :enum, enum_type: :funding_eligibility_status
    drop_enum :funding_eligibility_status
  end

  def down
    create_enum :funding_eligibility_status, %w[eligible_for_fip eligible_for_cip ineligible]
    add_column :gias_schools, :funding_eligibility, :enum, enum_type: :funding_eligibility_status, null: false
  end
end
