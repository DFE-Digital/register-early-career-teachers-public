RSpec.describe AppropriateBodies::RecordPass do
  it "defines expected induction params" do
    expect(described_class.induction_params).to eq({
      "appropriate_bodies_record_pass" => %i[finished_on number_of_terms]
    })
  end

  it_behaves_like "it closes an induction" do
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
      allow(Events::Record).to receive(:record_teacher_passes_induction_event!).and_call_original

      service_call

      expect(Events::Record).to have_received(:record_teacher_passes_induction_event!).with(
        appropriate_body:,
        teacher:,
        induction_period:,
        ect_at_school_period:,
        author:
      )
    end

    context "when ongoing induction period only has the legacy programme type" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing, :legacy_programme_type,
                          appropriate_body:,
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
