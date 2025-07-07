RSpec.describe InductionPeriods::DeleteInductionPeriod do
  subject(:service) do
    described_class.new(
      author:,
      induction_period:
    )
  end

  include_context 'fake trs api client'
  include ActiveJob::TestHelper

  let(:appropriate_body) { create(:appropriate_body) }
  let(:teacher) { create(:teacher) }
  let(:user) { create(:user) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:trs_client) { instance_double(TRS::APIClient) }

  before do
    allow(TRS::APIClient).to receive(:new).and_return(trs_client)
  end

  context "when it is the only induction period" do
    let!(:induction_period) { create(:induction_period, :active, teacher:, appropriate_body:) }

    before do
      allow(trs_client).to receive(:reset_teacher_induction)
      allow(trs_client).to receive(:begin_induction!)
      allow(Events::Record).to receive(:record_induction_period_deleted_event!)
      allow(Events::Record).to receive(:record_teacher_induction_status_reset_event!)
      allow(Events::Record).to receive(:record_teacher_trs_induction_start_date_updated_event!)
    end

    it "destroys the induction period" do
      expect { service.delete_induction_period! }.to change(InductionPeriod, :count).by(-1)
    end

    it "resets the TRS status" do
      service.delete_induction_period!

      expect(trs_client).to have_received(:reset_teacher_induction).with(trn: teacher.trn)
    end

    it "does not update the TRS start date" do
      service.delete_induction_period!

      expect(trs_client).not_to have_received(:begin_induction!)
    end

    it "records a delete event with the correct parameters" do
      service.delete_induction_period!

      expect(Events::Record).to have_received(:record_induction_period_deleted_event!).with(
        author:,
        modifications: hash_including("id" => [induction_period.id, nil]),
        teacher:,
        appropriate_body:,
        happened_at: instance_of(ActiveSupport::TimeWithZone)
      )
    end

    it "does not record a TRS induction start date updated event" do
      service.delete_induction_period!
      expect(Events::Record).not_to have_received(:record_teacher_trs_induction_start_date_updated_event!)
    end

    context "when the induction period has an outcome" do
      before { induction_period.update!(outcome: "pass") }

      it "raises ActiveRecord::RecordInvalid and does not delete or fire events" do
        expect {
          expect { service.delete_induction_period! }.to raise_error(ActiveRecord::RecordInvalid)
        }.not_to change(InductionPeriod, :count)
        expect(Events::Record).not_to have_received(:record_induction_period_deleted_event!)
        expect(Events::Record).not_to have_received(:record_teacher_trs_induction_start_date_updated_event!)
        expect(trs_client).not_to have_received(:reset_teacher_induction)
        expect(trs_client).not_to have_received(:begin_induction!)
      end
    end
  end

  context "when there are other induction periods" do
    let!(:earliest_period) { create(:induction_period, :active, teacher:, appropriate_body:, started_on: Date.new(2020, 1, 1), finished_on: Date.new(2020, 12, 31), number_of_terms: 3) }
    let!(:later_period) { create(:induction_period, :active, teacher:, appropriate_body:, started_on: Date.new(2021, 1, 1), finished_on: Date.new(2021, 12, 31), number_of_terms: 3) }

    before do
      allow(trs_client).to receive(:reset_teacher_induction)
      allow(trs_client).to receive(:begin_induction!)
      allow(Events::Record).to receive(:record_induction_period_deleted_event!)
      allow(Events::Record).to receive(:record_teacher_induction_status_reset_event!)
      allow(Events::Record).to receive(:record_teacher_trs_induction_start_date_updated_event!)
    end

    context "when deleting the earliest period" do
      subject(:service) do
        described_class.new(
          author:,
          induction_period: earliest_period
        )
      end

      it "destroys the induction period" do
        expect { service.delete_induction_period! }.to change(InductionPeriod, :count).by(-1)
      end

      it "updates the TRS start date to the next earliest period" do
        service.delete_induction_period!

        expect(trs_client).to have_received(:begin_induction!).with(
          trn: teacher.trn,
          start_date: later_period.started_on
        )
      end

      it "does not reset the TRS status" do
        service.delete_induction_period!

        expect(trs_client).not_to have_received(:reset_teacher_induction)
      end

      it "records a TRS induction start date updated event with the correct parameters" do
        service.delete_induction_period!

        expect(Events::Record).to have_received(:record_teacher_trs_induction_start_date_updated_event!).with(
          author:,
          teacher:,
          appropriate_body:,
          induction_period: later_period
        )
      end

      it "records a delete event with the correct parameters" do
        service.delete_induction_period!
        expect(Events::Record).to have_received(:record_induction_period_deleted_event!).with(
          author:,
          modifications: hash_including("id" => [earliest_period.id, nil]),
          teacher:,
          appropriate_body:,
          happened_at: instance_of(ActiveSupport::TimeWithZone)
        )
      end
    end

    context "when deleting a later period" do
      subject(:service) do
        described_class.new(
          author:,
          induction_period: later_period
        )
      end

      it "destroys the induction period" do
        expect { service.delete_induction_period! }.to change(InductionPeriod, :count).by(-1)
      end

      it "does not update the TRS start date" do
        service.delete_induction_period!
        expect(trs_client).not_to have_received(:begin_induction!)
      end

      it "does not reset the TRS status" do
        service.delete_induction_period!
        expect(trs_client).not_to have_received(:reset_teacher_induction)
      end

      it "does not record a TRS induction start date updated event" do
        service.delete_induction_period!
        expect(Events::Record).not_to have_received(:record_teacher_trs_induction_start_date_updated_event!)
      end

      it "records a delete event with the correct parameters" do
        service.delete_induction_period!
        expect(Events::Record).to have_received(:record_induction_period_deleted_event!).with(
          author:,
          modifications: hash_including("id" => [later_period.id, nil]),
          teacher:,
          appropriate_body:,
          happened_at: instance_of(ActiveSupport::TimeWithZone)
        )
      end
    end
  end
end
