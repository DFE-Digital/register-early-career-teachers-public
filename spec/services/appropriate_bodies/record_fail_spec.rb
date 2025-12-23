RSpec.describe AppropriateBodies::RecordFail do
  it "defines expected induction params" do
    expect(described_class.induction_params).to eq({
      "appropriate_bodies_record_fail" => %i[finished_on number_of_terms fail_confirmation_sent_on]
    })
  end

  it_behaves_like "it closes an induction" do
    let(:service_call) do
      service.call(
        finished_on: 1.day.ago.to_date,
        number_of_terms: 6,
        fail_confirmation_sent_on: Date.current
      )
    end

    it "closes with fail outcome" do
      service_call

      expect(induction_period.reload).to have_attributes(
        outcome: "fail",
        finished_on: 1.day.ago.to_date,
        number_of_terms: 6,
        fail_confirmation_sent_on: Date.current
      )
    end

    it "updates and refreshes TRS" do
      expect { service_call }.to have_enqueued_job(FailECTInductionJob).with(
        trn: teacher.trn,
        start_date: induction_period.started_on,
        completed_date: 1.day.ago.to_date
      )
    end

    it "records an induction failed event" do
      allow(Events::Record).to receive(:record_teacher_fails_induction_event!).and_call_original

      service_call

      expect(Events::Record).to have_received(:record_teacher_fails_induction_event!).with(
        appropriate_body:,
        teacher:,
        induction_period:,
        author:,
        body: "Confirmation sent on #{Date.current.to_fs(:govuk)}"
      )
    end

    context "when a confirmation date is not provided" do
      let(:service_call) do
        service.call(
          finished_on: 1.day.ago.to_date,
          number_of_terms: 6,
          fail_confirmation_sent_on: nil
        )
      end

      it do
        expect { service_call }.to raise_error(ActiveModel::ValidationError,
                                               "Validation failed: Fail confirmation sent on Enter the date you sent them written confirmation of their failed induction")
      end
    end

    context "when a confirmation date is in the future" do
      let(:service_call) do
        service.call(
          finished_on: 1.day.ago.to_date,
          number_of_terms: 6,
          fail_confirmation_sent_on: 1.day.from_now.to_date
        )
      end

      it do
        expect { service_call }.to raise_error(ActiveRecord::RecordInvalid,
                                               "Validation failed: Fail confirmation sent on Failure confirmation date cannot be in the future")
      end
    end

    context "when a confirmation date is before the start date" do
      let(:service_call) do
        service.call(
          finished_on: 1.day.ago.to_date,
          number_of_terms: 6,
          fail_confirmation_sent_on: 1.week.before(induction_period.started_on)
        )
      end

      it do
        expect { service_call }.to raise_error(ActiveRecord::RecordInvalid,
                                               "Validation failed: Fail confirmation sent on Failure confirmation date cannot be before start date")
      end
    end

    context "when ongoing induction period only has a mappable legacy programme type" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing, :legacy_programme_type,
                          appropriate_body:,
                          teacher:)
      end

      it "maps the new programme type" do
        service_call

        expect(induction_period.reload).to have_attributes(
          outcome: "fail",
          induction_programme: "fip",
          training_programme: "provider_led"
        )
      end
    end

    context "when ongoing induction period only has an unmappable legacy programme type" do
      let!(:induction_period) do
        FactoryBot.create(:induction_period, :ongoing, :pre_2021, :legacy_programme_type,
                          appropriate_body:,
                          teacher:)
      end

      it "leaves the new programme type blank" do
        service_call

        expect(induction_period.reload).to have_attributes(
          outcome: "fail",
          induction_programme: "pre_september_2021",
          training_programme: nil
        )
      end
    end
  end
end
