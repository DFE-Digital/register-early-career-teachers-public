class AddTRSRoutesToProfessionalStatusSummariesToPendingInductionSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :pending_induction_submissions, :trs_routes_to_professional_status_summaries, :string, array: true, default: []
  end
end
