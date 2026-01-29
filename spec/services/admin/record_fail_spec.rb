RSpec.describe Admin::RecordFail do
  it "defines expected induction params" do
    expect(described_class.induction_params).to eq({
      "admin_record_fail" => %i[finished_on number_of_terms]
    })
  end

  it "defines expected audit params" do
    expect(described_class.auditable_params).to eq({
      "admin_record_fail" => %i[zendesk_ticket_id note]
    })
  end

  it_behaves_like "it closes an induction" do
    subject(:service) do
      described_class.new(
        teacher:,
        appropriate_body:,
        author:,
        note:,
        zendesk_ticket_id: "#123456"
      )
    end

    let(:author) { FactoryBot.create(:dfe_user, email: "dfe_user@education.gov.uk") }
    let(:note) { "Original outcome recorded in error" }

    it "closes with fail outcome" do
      service_call

      expect(induction_period.reload).to have_attributes(
        outcome: "fail",
        finished_on: 1.day.ago.to_date,
        number_of_terms: 6
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
      expect(Events::Record).to receive(:record_teacher_fails_induction_event!).with(
        appropriate_body:,
        teacher:,
        induction_period:,
        ect_at_school_period:,
        author:,
        body: note,
        zendesk_ticket_id: "123456"
      )

      service_call
    end

    context "when the ect at school period has already finished" do
      let(:finished_on) { 2.days.ago }

      it "assigns the period to the event" do
        expect(Events::Record).to receive(:record_teacher_fails_induction_event!).with(
          appropriate_body:,
          teacher:,
          induction_period:,
          ect_at_school_period:,
          author:,
          body: note,
          zendesk_ticket_id: "123456"
        )

        service_call
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
