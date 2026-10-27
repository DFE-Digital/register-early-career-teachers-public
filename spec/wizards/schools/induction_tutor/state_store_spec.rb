RSpec.describe Schools::InductionTutor::StateStore do
  subject(:state_store) { described_class.new(school:) }

  let(:school) { FactoryBot.create(:school, :with_unconfirmed_induction_tutor) }

  describe "#prefill_from_school" do
    it "stores the school's induction tutor details" do
      state_store.prefill_from_school

      expect(state_store.read).to include(
        induction_tutor_name: school.induction_tutor_name,
        induction_tutor_email: school.induction_tutor_email
      )
    end

    context "when the user has already entered details" do
      before { state_store.write(induction_tutor_name: "New Name", induction_tutor_email: "new.name@example.com") }

      it "keeps the entered details" do
        state_store.prefill_from_school

        expect(state_store.read).to include(induction_tutor_name: "New Name", induction_tutor_email: "new.name@example.com")
      end
    end

    context "when the school has no induction tutor" do
      let(:school) { FactoryBot.create(:school, :without_induction_tutor) }

      it "stores blank details" do
        state_store.prefill_from_school

        expect(state_store.read).to include(induction_tutor_name: nil, induction_tutor_email: nil)
      end
    end
  end

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
