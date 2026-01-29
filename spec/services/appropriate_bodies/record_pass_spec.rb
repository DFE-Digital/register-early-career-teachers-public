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

    it "only records an induction passed event" do
      allow(Events::Record).to receive(:record_teacher_passes_induction_event!).and_call_original
      allow(Events::Record).to receive(:record_teacher_left_school_as_ect!).and_call_original
      allow(Events::Record).to receive(:record_teacher_finishes_training_period_event!).and_call_original
      allow(Events::Record).to receive(:record_teacher_finishes_mentoring_event!).and_call_original
      allow(Events::Record).to receive(:record_teacher_finishes_being_mentored_event!).and_call_original

      service_call

      expect(Events::Record).to have_received(:record_teacher_passes_induction_event!).with(
        appropriate_body:,
        teacher:,
        induction_period:,
        author:
      )

      expect(Events::Record).not_to have_received(:record_teacher_left_school_as_ect!)
      expect(Events::Record).not_to have_received(:record_teacher_finishes_training_period_event!)
      expect(Events::Record).not_to have_received(:record_teacher_finishes_mentoring_event!)
      expect(Events::Record).not_to have_received(:record_teacher_finishes_being_mentored_event!)
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

    context "with an ongoing ECT period" do
      let(:school) { ect_at_school_period.school }
      let(:mentor_teacher) { FactoryBot.create(:teacher) }
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: mentor_teacher, school:) }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, :with_training_period, teacher:) }
      let!(:mentorship_period) { FactoryBot.create(:mentorship_period, :ongoing, mentor: mentor_at_school_period, mentee: ect_at_school_period) }
      let(:ect_service) { ECTAtSchoolPeriods::Finish }

      before do
        allow(ect_service).to receive(:new).and_call_original
      end

      it "calls ECT finish service which finishes ongoing ECT and mentorship periods" do
        service_call

        expect(ect_service).to have_received(:new).with(ect_at_school_period:, finished_on: 1.day.ago.to_date, author:, record_event: false).once
        expect(ect_at_school_period.reload.finished_on).to eql(1.day.ago.to_date)
        expect(mentorship_period.reload.finished_on).to eql(1.day.ago.to_date)
      end
    end
  end
end
