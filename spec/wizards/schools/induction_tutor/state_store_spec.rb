RSpec.describe Schools::InductionTutor::StateStore do
  subject(:state_store) { described_class.new(school:) }

  let(:school) { FactoryBot.create(:school, :with_unconfirmed_induction_tutor) }

  describe "#details_confirmed?" do
    it { is_expected.not_to be_details_confirmed }

    it "is true when the details have been confirmed as correct" do
      state_store.write(are_these_details_correct: true)

      expect(state_store).to be_details_confirmed
    end

    it "is false when the details have been changed" do
      state_store.write(are_these_details_correct: false)

      expect(state_store).not_to be_details_confirmed
    end
  end

  describe "#closest_contract_period" do
    let!(:upcoming_contract_period) do
      FactoryBot.create(:contract_period, :next, started_on: 2.months.from_now, finished_on: 6.months.from_now)
    end

    context "when the current contract period is ongoing today" do
      let!(:current_contract_period) do
        FactoryBot.create(:contract_period, :current, started_on: 1.month.ago, finished_on: 1.month.from_now)
      end

      it "is the current contract period" do
        expect(state_store.closest_contract_period).to eq(current_contract_period)
      end
    end

    context "when the current contract period has finished" do
      before { FactoryBot.create(:contract_period, :current, started_on: 1.month.ago, finished_on: 1.day.ago) }

      it "is the upcoming contract period" do
        expect(state_store.closest_contract_period).to eq(upcoming_contract_period)
      end
    end
  end
end
