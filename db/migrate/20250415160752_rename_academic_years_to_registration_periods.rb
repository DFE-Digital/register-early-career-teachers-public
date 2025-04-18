class RenameAcademicYearsToRegistrationPeriods < ActiveRecord::Migration[8.0]
  def change
    rename_table :academic_years, :registration_periods
    rename_column :provider_partnerships, :academic_year_id, :registration_period_id
  end
end
