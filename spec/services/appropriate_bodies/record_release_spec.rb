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
      service_call

      expect(Event.where(event_type: "induction_period_closed").sole).to have_attributes(
        appropriate_body_period_id: appropriate_body_period.id,
        teacher_id: teacher.id,
        induction_period_id: induction_period.id
      )
    end
  end
end
