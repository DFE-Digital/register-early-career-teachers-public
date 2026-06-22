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

  let(:store) do
    FactoryBot.build(
      :session_repository,
      appropriate_body_id: appropriate_body_period.id.to_s
    )
  end
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :national_ab, school:) }
  let(:params) { { appropriate_body_id: appropriate_body_period.id } }
  let(:appropriate_body_period) { ect_at_school_period.school_reported_appropriate_body }

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

  describe "validations" do
    context "when the appropriate body has not changed" do
      let(:params) { { appropriate_body_id: appropriate_body_period.id } }

      it "is invalid" do
        expect(current_step).to be_invalid
        expect(current_step.errors.messages_for(:appropriate_body_id)).to contain_exactly(
          "You must select a different appropriate body"
        )
      end
    end

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
      let(:params) { { appropriate_body_id: 1 } }

      it "stores the appropriate_body_id" do
        expect { current_step.save! }.to change(store, :appropriate_body_id)
          .to("1")
      end
    end
  end
end
