class RenameChosenFieldsOnSchools < ActiveRecord::Migration[8.0]
  def change
    rename_column :schools, :chosen_appropriate_body_id, :last_chosen_appropriate_body_id
    rename_column :schools, :chosen_lead_provider_id, :last_chosen_lead_provider_id
    rename_column :schools, :chosen_programme_type, :last_chosen_programme_type
  end
end
