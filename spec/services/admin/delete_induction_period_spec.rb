RSpec.describe Admin::DeleteInductionPeriod do
  subject(:service) { described_class.new(author:, induction_period:) }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:author) { FactoryBot.create(:user) }
  let!(:induction_period) do
    FactoryBot.create(:induction_period, teacher:, appropriate_body:, started_on: Date.new(2020, 1, 1), finished_on: Date.new(2020, 12, 31), number_of_terms: 2)
  end
  let(:trs_api_client) { instance_double(TRS::APIClient) }

  before do
    allow(Events::Record).to receive(:record_induction_period_deleted_event!).and_return(true)
    allow(TRS::APIClient).to receive(:new).and_return(trs_api_client)
    allow(trs_api_client).to receive(:reset_teacher_induction)
  end

  describe "#delete_induction_period!" do
    it "destroys the induction period" do
      expect { service.delete_induction_period! }.to change(InductionPeriod, :count).by(-1)
    end

    it "records an event with the correct parameters" do
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

    context "when it is the only induction period" do
      it "resets TRS status" do
        expect(trs_api_client).to receive(:reset_teacher_induction).with(trn: teacher.trn)
        service.delete_induction_period!
      end
    end

    context "when there are other induction periods" do
      let!(:other_period) do
        FactoryBot.create(:induction_period, teacher:, appropriate_body:, started_on: Date.new(2021, 1, 1), finished_on: Date.new(2021, 12, 31), number_of_terms: 2)
      end

      it "does not reset TRS status" do
        expect(trs_api_client).not_to receive(:reset_teacher_induction)
        service.delete_induction_period!
      end
    end

    it "returns true" do
      expect(service.delete_induction_period!).to be(true)
    end
  end
end
