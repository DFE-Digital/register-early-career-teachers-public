RSpec.describe InductionPeriods::PartialTransferInductionPeriods, :aggregate_failures do
  include_context "it transfers an induction"

  describe "transfer part of induction periods and create new events" do
    it "curtails induction period at cut off date" do
      expect(InductionPeriod.count).to be 5

      expect(Event.order(:happened_at).map(&:heading)).to eq([
        "skip_pre_cut_off_induction: Current AB",
        "partial_completed_induction: Current AB",
        "partial_in_progress_induction: Current AB",
        "full_completed_induction: Current AB",
        "full_in_progress_induction: Current AB",
      ])

      service.call

      expect(InductionPeriod.count).to be 7

      # transfers inductions
      expect(InductionPeriod.order(:created_at).map(&:appropriate_body_period)).to eq([
        current_appropriate_body,
        current_appropriate_body,
        current_appropriate_body,
        current_appropriate_body,
        current_appropriate_body,
        new_appropriate_body,
        new_appropriate_body,
      ])

      # changes AB name in heading and injects new events
      expect(Event.order(:happened_at).map(&:heading)).to match([
        /First name \d+ Last name \d+ was released by Current AB/,
        /First name \d+ Last name \d+ was released by Current AB/,
        /First name \d+ Last name \d+ was claimed by New AB/,
        /First name \d+ Last name \d+ was claimed by New AB/,
        "skip_pre_cut_off_induction: Current AB",
        "partial_completed_induction: New AB",
        "partial_in_progress_induction: New AB",
        "full_completed_induction: Current AB",
        "full_in_progress_induction: Current AB",
      ])

      # provides context in body
      expect(Event.order(:happened_at).map(&:body)).to eq([
        "Automated correction from Current AB to New AB on #{Date.current}",
        "Automated correction from Current AB to New AB on #{Date.current}",
        "Automated correction from Current AB to New AB on #{Date.current}",
        "Automated correction from Current AB to New AB on #{Date.current}",
        nil,
        "Automated correction from Current AB to New AB on #{Date.current}",
        "Automated correction from Current AB to New AB on #{Date.current}",
        nil,
        nil,
      ])
    end
  end

  describe "rollback: true" do
    it "persists no changes" do
      expect(Event.all[2].heading).to eq("partial_in_progress_induction: Current AB")

      service.call(rollback: true)

      expect(Event.all[2].reload.heading).to eq("partial_in_progress_induction: Current AB")
    end
  end
end
