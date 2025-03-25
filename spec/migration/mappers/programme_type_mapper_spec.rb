describe Mappers::ProgrammeTypeMapper do
  subject { described_class.new(input).mapped_value }

  describe "#mapped_value" do
    context "when input is 'core_induction_programme'" do
      let(:input) { "core_induction_programme" }

      it { is_expected.to eq("school_led") }
    end

    context "when input is 'design_our_own'" do
      let(:input) { "design_our_own" }

      it { is_expected.to eq("school_led") }
    end

    context "when input is 'school_funded_fip'" do
      let(:input) { "school_funded_fip" }

      it { is_expected.to eq("provider_led") }
    end

    context "when input is 'full_induction_programme'" do
      let(:input) { "full_induction_programme" }

      it { is_expected.to eq("provider_led") }
    end

    context "when input is not in the mapping" do
      let(:input) { "unknown_key" }

      it { is_expected.to be_nil }
    end
  end
end
