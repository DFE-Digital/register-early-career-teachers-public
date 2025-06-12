class RemoveRegistrationPeriodIdFromSchoolPartnerships < ActiveRecord::Migration[8.0]
  def up
    remove_column :school_partnerships, :registration_period_id
  end

  def down
    # rubocop:disable Rails/NotNullColumn
    add_column :school_partnerships, :registration_period_id, :bigint, null: false
    # rubocop:enable Rails/NotNullColumn
  end
end
