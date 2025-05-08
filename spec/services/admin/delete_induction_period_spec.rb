RSpec.describe Admin::DeleteInductionPeriod do
  subject(:service) do
    described_class.new(
      author:,
      induction_period:
    )
  end

  include_context 'fake trs api client'
  include ActiveJob::TestHelper

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:author) { FactoryBot.create(:user) }
  let(:trs_client) { instance_double(TRS::APIClient) }

  before do
    allow(TRS::APIClient).to receive(:new).and_return(trs_client)
    allow(trs_client).to receive(:reset_teacher_induction)
    allow(trs_client).to receive(:begin_induction!)
    allow(Events::Record).to receive(:record_induction_period_deleted_event!)
    allow(Events::Record).to receive(:record_induction_period_updated_event!)
  end

  context "when it is the only induction period" do
    let!(:induction_period) { FactoryBot.create(:induction_period, teacher:, appropriate_body:) }

    it "destroys the induction period" do
      expect { service.delete_induction_period! }.to change(InductionPeriod, :count).by(-1)
    end

    it "resets the TRS status" do
      expect(trs_client).to receive(:reset_teacher_induction).with(trn: teacher.trn)
      service.delete_induction_period!
    end

    it "records a delete event with the correct parameters" do
      expected_modifications = induction_period.attributes.transform_values { |v| [v, nil] }

      expect(Events::Record).to receive(:record_induction_period_deleted_event!).with(
        author:,
        modifications: expected_modifications,
        teacher:,
        appropriate_body:,
        happened_at: kind_of(Time)
      )
      service.delete_induction_period!
    end

    it "does not record an update event" do
      expect(Events::Record).not_to receive(:record_induction_period_updated_event!)
      service.delete_induction_period!
    end
  end

  context "when there are other induction periods" do
    let!(:earlier_period) do
      FactoryBot.create(:induction_period,
        teacher:,
        appropriate_body:,
        started_on: 2.years.ago,
        finished_on: 1.year.ago
      )
    end
    let!(:induction_period) do
      FactoryBot.create(:induction_period,
        teacher:,
        appropriate_body:,
        started_on: 1.year.ago + 1.day,
        finished_on: Date.current
      )
    end

    it "destroys the induction period" do
      expect { service.delete_induction_period! }.to change(InductionPeriod, :count).by(-1)
    end

    it "updates the TRS start date to the earliest remaining period" do
      expect(trs_client).to receive(:begin_induction!).with(
        trn: teacher.trn,
        start_date: earlier_period.started_on
      )
      service.delete_induction_period!
    end

    it "records an update event with the correct parameters" do
      expected_modifications = induction_period.attributes.transform_values { |v| [v, nil] }

      expect(Events::Record).to receive(:record_induction_period_updated_event!).with(
        author:,
        modifications: expected_modifications,
        teacher:,
        appropriate_body:,
        induction_period:,
        happened_at: kind_of(Time)
      )
      service.delete_induction_period!
    end

    it "does not record a delete event" do
      expect(Events::Record).not_to receive(:record_induction_period_deleted_event!)
      service.delete_induction_period!
    end

    it "does not reset the TRS status" do
      expect(trs_client).not_to receive(:reset_teacher_induction)
      service.delete_induction_period!
    end
  end
end
