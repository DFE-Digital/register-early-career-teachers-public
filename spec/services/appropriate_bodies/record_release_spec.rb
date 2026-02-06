RSpec.describe AppropriateBodies::RecordRelease do
  it "defines expected induction params" do
    expect(described_class.induction_params).to eq({
      "appropriate_bodies_record_release" => %i[finished_on number_of_terms]
    })
  end

  it_behaves_like "it closes an induction" do
    it "closes without an outcome" do
      service_call

      expect(induction_period.reload).to have_attributes(
        outcome: nil,
        finished_on: 1.day.ago.to_date,
        number_of_terms: 6
      )
    end

    it "records an induction closed event" do
      allow(Events::Record).to receive(:record_induction_period_closed_event!).and_call_original

      service_call

      expect(Events::Record).to have_received(:record_induction_period_closed_event!).with(
        appropriate_body_period:,
        teacher:,
        induction_period:,
        author:
      )
    end
  end
end
