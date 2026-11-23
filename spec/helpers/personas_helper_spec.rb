RSpec.describe PersonasHelper, type: :helper do
  def persona(type:, appropriate_body_name: nil, school_name: nil, school_type: nil, role: nil)
    Sessions::PersonaLoader::PersonaData.new(
      name: "Example",
      email: "example@education.gov.uk",
      type:,
      appropriate_body_name:,
      school_name:,
      school_type:,
      role:
    )
  end

  describe "#persona_organisation" do
    subject(:organisation) { helper.persona_organisation(user_persona) }

    context "with a teaching school hub appropriate body persona" do
      let(:user_persona) do
        persona(type: "Appropriate body user",
                appropriate_body_name: "Example Hub",
                school_name: "Example School")
      end

      it { is_expected.to eq("Example Hub (Example School)") }
    end

    context "with a national appropriate body persona" do
      let(:user_persona) do
        persona(type: "Appropriate body user",
                appropriate_body_name: "Example National Body")
      end

      it { is_expected.to eq("Example National Body") }
    end

    context "with a school user persona" do
      let(:user_persona) do
        persona(type: "School user",
                school_name: "Example School",
                school_type: "State school")
      end

      it { is_expected.to eq("Example School (State school)") }
    end

    context "with a DfE staff persona" do
      let(:user_persona) do
        persona(type: "DfE staff", role: "finance")
      end

      it { is_expected.to eq("Department for Education staff member (Finance)") }
    end

    context "with an unrecognised persona" do
      let(:user_persona) { persona(type: "Mystery user") }

      it { expect { organisation }.to raise_error(PersonasHelper::UnrecognisedPersonaType) }
    end
  end

  describe "#persona_role" do
    subject(:role) { helper.persona_role(user_persona) }

    context "when the persona is a DfE staff member" do
      let(:user_persona) { persona(type: "DfE staff", role: "admin") }

      it { is_expected.to eq("Admin") }
    end

    context "when the persona is not a DfE staff member" do
      let(:user_persona) { persona(type: "School user", school_name: "Example School") }

      it { is_expected.to be_nil }
    end
  end
end
