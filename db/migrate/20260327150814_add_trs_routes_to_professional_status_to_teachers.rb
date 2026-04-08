class AddTRSRoutesToProfessionalStatusToTeachers < ActiveRecord::Migration[8.0]
  def change
    add_column :teachers, :trs_routes_to_professional_status_summaries, :string, array: true, default: []
  end
end
