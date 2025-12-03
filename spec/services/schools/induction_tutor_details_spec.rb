RSpec.describe Schools::InductionTutorDetails do
  subject(:service) do
    described_class.new(user)
  end

  let(:school) { FactoryBot.create(:school) }
  let(:user) { FactoryBot.create(:school_user, school_urn: school.urn) }

  describe "#update_required?" do
    context "when there is no user" do
      let(:user) { nil }
      it "returns false" do
        expect(service).not_to be_update_required
      end
    end
    
    context "when the user is not a school user" do
      let(:user) { FactoryBot.create(:dfe_user) }

      it "returns false" do
        expect(service).not_to be_update_required
      end
    end

    context "when the user is a school user impersonated by a DfE user" do
      let(:school_user) { FactoryBot.create(:user) }

      let(:user) do
        FactoryBot.build(:dfe_user_impersonating_school_user, email: school_user.email, school_urn: school.urn)
      end

      it "returns false" do
        expect(service).not_to be_update_required
      end
    end

    xcontext "when the user has multiple roles" do
      let(:user) { FactoryBot.create(:school_user, :with_multiple_roles) }

      it "returns false" do
        expect(service).not_to be_update_required
      end
    end

    xcontext "when the user is not linked to a school" do
      let(:user) { FactoryBot.create(:school_user) }

      it "returns false" do
        expect(service).not_to be_update_required
      end
    end

    context "when the induction tutor details have never been confirmed" do
      it "returns true" do
        expect(service).to be_update_required
      end
    end

    context "when the induction tutor details were last confirmed before the current contract year" do
      before do
        FactoryBot.create(:contract_period, :current)
        previous_contract_period = FactoryBot.create(:contract_period, :previous)

        school.update!(induction_tutor_last_nominated_in_year: previous_contract_period,
                       induction_tutor_name: "Alastair Sim",
                       induction_tutor_email: "alastair.sim@st-trinians.org.uk")
      end

      it "returns true" do
        expect(service).to be_update_required
      end
    end

    context "when the induction tutor details were last confirmed in the current contract year" do
      before do
        current_contract_period = FactoryBot.create(:contract_period, :current)
        school.update!(induction_tutor_last_nominated_in_year: current_contract_period,
                       induction_tutor_name: "Alastair Sim",
                       induction_tutor_email: "alastair.sim@st-trinians.org.uk")
      end

      it "returns false" do
        expect(service).not_to be_update_required
      end
    end
  end
end
