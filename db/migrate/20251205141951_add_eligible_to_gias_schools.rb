class AddEligibleToGIASSchools < ActiveRecord::Migration[8.0]
  def up
    add_column :gias_schools, :eligible, :boolean, default: false, null: false
    execute "UPDATE gias_schools SET eligible = (funding_eligibility = 'eligible_for_fip')"
    remove_column :gias_schools, :funding_eligibility
    drop_enum :funding_eligibility_status
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
