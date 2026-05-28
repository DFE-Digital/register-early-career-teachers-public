RSpec.describe Schools::InductionTutorDetails do
  subject(:service) { described_class.new(user) }

  let(:school) { FactoryBot.create(:school) }
  let(:user) { FactoryBot.create(:school_user, school_urn: school.urn) }

  describe "#update_required?" do
    context "when there is no user" do
      let(:user) { nil }

      it { is_expected.not_to be_update_required }
    end

    context "when the user is not a school user" do
      let(:user) { FactoryBot.create(:dfe_user) }

      it { is_expected.not_to be_update_required }
    end

    context "when the user is a school user impersonated by a DfE user" do
      let(:school_user) { FactoryBot.create(:user) }

      let(:user) do
        FactoryBot.build(:dfe_user_impersonating_school_user, email: school_user.email, school_urn: school.urn)
      end

      it { is_expected.not_to be_update_required }
    end

    context "when there is no current or upcoming contract period" do
      it { is_expected.not_to be_update_required }
    end

    context "when the induction tutor details are not set for the school" do
      let!(:current_contract_period) { FactoryBot.create(:contract_period, :current) }
      let(:school) { FactoryBot.create(:school, :without_induction_tutor) }

      it { is_expected.to be_update_required }
    end

    context "when the induction tutor details have never been confirmed" do
      let!(:current_contract_period) { FactoryBot.create(:contract_period, :current) }
      let(:school) { FactoryBot.create(:school, :with_unconfirmed_induction_tutor) }

      it { is_expected.to be_update_required }
    end

    context "when the induction tutor details were last confirmed before the current contract year" do
      let!(:current_contract_period) { FactoryBot.create(:contract_period, :current) }
      let!(:previous_contract_period) { FactoryBot.create(:contract_period, :previous) }
      let(:school) do
        FactoryBot.create(
          :school,
          :with_induction_tutor,
          induction_tutor_last_nominated_in: previous_contract_period
        )
      end

      it { is_expected.to be_update_required }
    end

    context "when the induction tutor details were last confirmed in the current contract year" do
      let!(:current_contract_period) { FactoryBot.create(:contract_period, :current) }
      let(:school) do
        FactoryBot.create(
          :school,
          :with_induction_tutor,
          induction_tutor_last_nominated_in: current_contract_period
        )
      end

      it { is_expected.not_to be_update_required }
    end

    context "when it is the last day of the current contract period" do
      let!(:current_contract_period) { FactoryBot.create(:contract_period, :current) }
      let(:school) do
        FactoryBot.create(
          :school,
          :with_induction_tutor,
          induction_tutor_last_nominated_in: current_contract_period
        )
      end

      around do |example|
        travel_to(current_contract_period.finished_on) do
          example.run
        end
      end

      it { is_expected.not_to be_update_required }
    end

    context "when the current contract period has finished but the upcoming contract period has not started" do
      let!(:current_contract_period) do
        FactoryBot.create(
          :contract_period,
          :current,
          started_on: 2.months.ago,
          finished_on: Date.yesterday
        )
      end
      let!(:upcoming_contract_period) do
        FactoryBot.create(
          :contract_period,
          :next,
          started_on: Date.tomorrow,
          finished_on: 2.months.from_now
        )
      end

      context "and the induction tutor details were last confirmed in the current contract period year" do
        let(:school) do
          FactoryBot.create(
            :school,
            :with_induction_tutor,
            induction_tutor_last_nominated_in: current_contract_period
          )
        end

        it { is_expected.to be_update_required }
      end

      context "and the induction tutor details were last confirmed in the upcoming contract period year" do
        let(:school) do
          FactoryBot.create(
            :school,
            :with_induction_tutor,
            induction_tutor_last_nominated_in: upcoming_contract_period
          )
        end

        it { is_expected.not_to be_update_required }
      end
    end
  end

  describe "#wizard_path" do
    subject(:wizard_path) { service.wizard_path }

    context "when the school has an unconfirmed induction tutor" do
      let(:school) { FactoryBot.create(:school, :with_unconfirmed_induction_tutor) }

      it { is_expected.to eq("/school/induction-tutor/confirm-existing-induction-tutor/edit") }
    end

    context "when the school does not have an induction tutor nominted" do
      let(:school) { FactoryBot.create(:school, :without_induction_tutor) }

      it { is_expected.to eq("/school/induction-tutor/new-induction-tutor/edit") }
    end
  end
end
