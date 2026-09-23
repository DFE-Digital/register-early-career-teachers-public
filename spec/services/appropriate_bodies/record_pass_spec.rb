RSpec.describe AppropriateBodies::RecordPass do
  it "defines expected induction params" do
    expect(described_class.induction_params).to eq({
      "appropriate_bodies_record_pass" => %i[finished_on number_of_terms]
    })
  end

  it_behaves_like "it closes an induction period and finishes any related periods" do
    it "closes with pass outcome" do
      service_call

      expect(induction_period.reload).to have_attributes(
        outcome: "pass",
        finished_on: 1.day.ago.to_date,
        number_of_terms: 6
      )
    end

    it "updates and refreshes TRS" do
      expect { service_call }.to have_enqueued_job(PassECTInductionJob).with(
        trn: teacher.trn,
        start_date: induction_period.started_on,
        completed_date: 1.day.ago.to_date
      )
    end

    it "records an induction passed event" do
      expected_periods = {
        teacher_id: teacher.id,
        appropriate_body_period_id: appropriate_body_period.id,
        induction_period_id: induction_period.id,
        ect_at_school_period_id: ect_at_school_period&.id,
        mentorship_period_id: mentorship_period&.id,
        training_period_id: training_period&.id
      }

      service_call

      expect(Event.where(event_type: "teacher_passes_induction").sole).to have_attributes(**expected_periods)
    end

    context "when the ect at school period has already finished" do
      let(:finished_on) { 2.days.ago }

      it "assigns the period to the event" do
        expected_periods = {
          teacher_id: teacher.id,
          appropriate_body_period_id: appropriate_body_period.id,
          induction_period_id: induction_period.id,
          ect_at_school_period_id: ect_at_school_period&.id,
          mentorship_period_id: mentorship_period&.id,
          training_period_id: training_period&.id
        }

        service_call

        expect(Event.where(event_type: "teacher_passes_induction").sole).to have_attributes(**expected_periods)
      end
    end

    context "when ongoing induction period only has the legacy programme type" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :unfinished, :legacy_programme_type,
                          appropriate_body_period:,
                          teacher:)
      end

      it "populates the new programme type and outcome" do
        service_call

        expect(induction_period.reload).to have_attributes(
          outcome: "pass",
          training_programme: "provider_led"
        )
      end
    end
  end
end
