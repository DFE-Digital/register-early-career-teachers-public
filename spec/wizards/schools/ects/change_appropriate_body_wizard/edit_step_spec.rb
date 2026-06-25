describe Schools::ECTs::ChangeAppropriateBodyWizard::EditStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeAppropriateBodyWizard::Wizard.new(
      current_step: :edit,
      step_params: ActionController::Parameters.new(edit: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end

  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, school_reported_appropriate_body:) }
  let(:params) { { appropriate_body_id: appropriate_body_period.id.to_s } }
  let(:school_reported_appropriate_body) { FactoryBot.create(:appropriate_body_period) }
  let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }

  describe ".permitted_params" do
    it "returns the permitted parameters" do
      expect(described_class.permitted_params).to contain_exactly(:appropriate_body_id)
    end
  end

  describe "#previous_step" do
    it "raises an error" do
      expect { current_step.previous_step }.to raise_error(NotImplementedError)
    end
  end

  describe "#next_step" do
    it "returns the next step" do
      expect(current_step.next_step).to eq(:check_answers)
    end
  end

  describe "#appropriate_bodies_except_current" do
    let!(:other_appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }
    let!(:inactive_appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :inactive) }

    it "does not include inactive appropriate bodies" do
      expect(current_step.appropriate_bodies_except_current).not_to include(inactive_appropriate_body_period)
    end

    it "does not include the current appropriate body" do
      expect(current_step.appropriate_bodies_except_current).not_to include(ect_at_school_period.school_reported_appropriate_body)
    end

    it "returns active appropriate bodies which can be selected" do
      expect(current_step.appropriate_bodies_except_current).to contain_exactly(other_appropriate_body_period, appropriate_body_period)
    end

    context "when the current appropriate body is nil" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:, school_reported_appropriate_body: nil) }

      it "does not include inactive appropriate bodies" do
        expect(current_step.appropriate_bodies_except_current).not_to include(inactive_appropriate_body_period)
      end

      it "returns active appropriate bodies which can be selected" do
        expect(current_step.appropriate_bodies_except_current).to contain_exactly(other_appropriate_body_period, appropriate_body_period)
      end
    end
  end

  describe "validations" do
    context "when the appropriate body is blank" do
      let(:params) { { appropriate_body_id: "" } }

      it "is invalid" do
        expect(current_step).to be_invalid
        expect(current_step.errors.messages_for(:appropriate_body_id)).to contain_exactly(
          "Select the appropriate body which will be supporting the ECT's induction"
        )
      end
    end

    context "when the appropriate body is valid" do
      let(:params) { { appropriate_body_id: new_appropriate_body_period.id } }
      let(:new_appropriate_body_period) { FactoryBot.create(:appropriate_body_period) }

      it "is valid" do
        expect(current_step).to be_valid
      end
    end
  end

  describe "save!" do
    context "when appropriate body is invalid" do
      let(:params) { { appropriate_body_id: "" } }

      it "does not store the appropriate_body_id" do
        expect { current_step.save! }.not_to(change(store, :appropriate_body_id))
      end
    end

    context "when appropriate body is valid" do
      let(:params) { { appropriate_body_id: appropriate_body_period.id } }

      it "stores the appropriate_body_id" do
        expect { current_step.save! }.to change(store, :appropriate_body_id)
          .to(appropriate_body_period.id.to_s)
      end
    end
  end
end
