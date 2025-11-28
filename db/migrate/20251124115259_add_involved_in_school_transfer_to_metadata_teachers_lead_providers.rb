class AddInvolvedInSchoolTransferToMetadataTeachersLeadProviders < ActiveRecord::Migration[8.0]
  def change
    add_column :metadata_teachers_lead_providers, :involved_in_school_transfer, :boolean, null: true
  end
end
