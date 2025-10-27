RSpec.describe InductionPeriods::DeleteInductionPeriod do
  include ActiveJob::TestHelper

  subject(:service) do
    described_class.new(author:, induction_period:, note:, zendesk_ticket_id:)
  end

  include_context 'test trs api client'

  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:note) { "Induction period created in error" }
  let(:zendesk_ticket_id) { '#123456' }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:user) { FactoryBot.create(:user) }
  let(:trs_client) { instance_double(TRS::APIClient) }

  let!(:induction_period) do
    FactoryBot.create(:induction_period, :ongoing, teacher:, appropriate_body:)
  end

  before do
    allow(TRS::APIClient).to receive(:new).and_return(trs_client)
    allow(trs_client).to receive(:reset_teacher_induction!)
    allow(trs_client).to receive(:begin_induction!)
  end

  context "when it is the only induction period" do
    it "destroys the induction period" do
      expect { service.delete_induction_period! }
        .to change(InductionPeriod, :count).by(-1)
    end

    it "resets the TRS status" do
      expect(trs_client)
        .to receive(:reset_teacher_induction!)
        .with(trn: teacher.trn)

      service.delete_induction_period!
    end

    it "does not update the TRS start date" do
      expect(trs_client).not_to receive(:begin_induction!)

      service.delete_induction_period!
    end

    it "records a delete event with the correct parameters" do
      expect(Events::Record)
        .to receive(:record_induction_period_deleted_event!)
        .with(
          author:,
          body: note,
          zendesk_ticket_id: '123456',
          modifications: hash_including("id" => [induction_period.id, nil]),
          teacher:,
          appropriate_body:,
          happened_at: instance_of(ActiveSupport::TimeWithZone)
        )

      service.delete_induction_period!
    end

    it "does not record a TRS induction start date updated event" do
      expect(Events::Record)
        .not_to receive(:record_teacher_trs_induction_start_date_updated_event!)

      service.delete_induction_period!
    end

    context "when the induction period has an outcome" do
      before { induction_period.update!(outcome: "pass") }

      it "raises ActiveRecord::RecordInvalid and does not delete or fire events" do
        expect { service.delete_induction_period! }
          .to raise_error(ActiveRecord::RecordInvalid)
          .and(not_change(InductionPeriod, :count))

        expect(Events::Record)
          .not_to receive(:record_induction_period_deleted_event!)
        expect(Events::Record)
          .not_to receive(:record_teacher_trs_induction_start_date_updated_event!)
        expect(trs_client).not_to receive(:reset_teacher_induction!)
        expect(trs_client).not_to receive(:begin_induction!)
      end
    end
  end

  context "when there are other induction periods" do
    let!(:earliest_period) do
      FactoryBot.create(
        :induction_period,
        :ongoing,
        teacher:,
        appropriate_body:,
        started_on: Date.new(2020, 1, 1),
        finished_on: Date.new(2020, 12, 31),
        number_of_terms: 3
      )
    end

    let!(:later_period) do
      FactoryBot.create(
        :induction_period,
        :ongoing,
        teacher:,
        appropriate_body:,
        started_on: Date.new(2021, 1, 1),
        finished_on: Date.new(2021, 12, 31),
        number_of_terms: 3
      )
    end

    context "when deleting the earliest period" do
      let(:induction_period) { earliest_period }

      it "destroys the induction period" do
        expect { service.delete_induction_period! }
          .to change(InductionPeriod, :count).by(-1)
      end

      it "updates the TRS start date to the next earliest period" do
        expect(trs_client)
          .to receive(:begin_induction!)
          .with(
            trn: teacher.trn,
            start_date: later_period.started_on
          )

        service.delete_induction_period!
      end

      it "does not reset the TRS status" do
        expect(trs_client).not_to receive(:reset_teacher_induction!)

        service.delete_induction_period!
      end

      it "records a TRS induction start date updated event with the correct parameters" do
        expect(Events::Record)
          .to receive(:record_teacher_trs_induction_start_date_updated_event!)
          .with(
            author:,
            teacher:,
            appropriate_body:,
            induction_period: later_period
          )

        service.delete_induction_period!
      end

      it "records a delete event with the correct parameters" do
        expect(Events::Record)
          .to receive(:record_induction_period_deleted_event!)
          .with(
            author:,
            body: note,
            zendesk_ticket_id: '123456',
            modifications: hash_including("id" => [earliest_period.id, nil]),
            teacher:,
            appropriate_body:,
            happened_at: instance_of(ActiveSupport::TimeWithZone)
          )

        service.delete_induction_period!
      end
    end

    context "when deleting a later period" do
      let(:induction_period) { later_period }

      it "destroys the induction period" do
        expect { service.delete_induction_period! }
          .to change(InductionPeriod, :count).by(-1)
      end

      it "does not update the TRS start date" do
        expect(trs_client).not_to receive(:begin_induction!)
        service.delete_induction_period!
      end

      it "does not reset the TRS status" do
        expect(trs_client).not_to receive(:reset_teacher_induction!)
        service.delete_induction_period!
      end

      it "does not record a TRS induction start date updated event" do
        expect(Events::Record).not_to receive(:record_teacher_trs_induction_start_date_updated_event!)
        service.delete_induction_period!
      end

      it "records a delete event with the correct parameters" do
        expect(Events::Record)
          .to receive(:record_induction_period_deleted_event!)
          .with(
            author:,
            body: note,
            zendesk_ticket_id: '123456',
            modifications: hash_including("id" => [later_period.id, nil]),
            teacher:,
            appropriate_body:,
            happened_at: instance_of(ActiveSupport::TimeWithZone)
          )

        service.delete_induction_period!
      end
    end

    context "when the note and Zendesk ticket ID are blank" do
      let(:note) { "" }
      let(:zendesk_ticket_id) { "" }

      it "raises an error" do
        expect { service.delete_induction_period! }
          .to raise_error(ActiveModel::ValidationError)
          .with_message("Validation failed: Add a note or enter the Zendesk ticket number")
      end
    end

    context "when the Zendesk ticket ID is invalid" do
      let(:zendesk_ticket_id) { "invalid_url" }

      it "raises an error" do
        expect { service.delete_induction_period! }
          .to raise_error(ActiveModel::ValidationError)
          .with_message("Validation failed: Zendesk ticket Ticket number must be 6 digits")
      end
    end
  end
end
