RSpec.describe RIAB::FullTransferInductionPeriods, :aggregate_failures do
  include_context "it transfers an induction"

  describe "full transfer of induction periods and events" do
    it "transfers full inductions only" do
      expect(InductionPeriod.count).to be 5

      expect(InductionPeriod.all.map(&:appropriate_body).uniq).to eq([
        current_appropriate_body
      ])

      expect(Event.order(:happened_at).map(&:heading)).to eq([
        "skip_pre_cut_off_induction: Current AB",
        "partial_completed_induction: Current AB",
        "partial_in_progress_induction: Current AB",
        "full_completed_induction: Current AB",
        "full_in_progress_induction: Current AB",
      ])

      service.call

      # transfers inductions
      expect(InductionPeriod.all.map(&:appropriate_body)).to eq([
        current_appropriate_body,
        current_appropriate_body,
        current_appropriate_body,
        new_appropriate_body,
        new_appropriate_body,
      ])

      # changes AB name in heading
      expect(Event.order(:happened_at).map(&:heading)).to eq([
        "skip_pre_cut_off_induction: Current AB",
        "partial_completed_induction: Current AB",
        "partial_in_progress_induction: Current AB",
        "full_completed_induction: New AB",
        "full_in_progress_induction: New AB",
      ])
    end
  end

  describe "rollback: true" do
    it "persists no changes" do
      expect(Event.last.heading).to eq("full_in_progress_induction: Current AB")

      service.call(rollback: true)

      expect(Event.last.reload.heading).to eq("full_in_progress_induction: Current AB")
    end
  end
end
