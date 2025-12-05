RSpec.describe GIAS::SchoolRow do
  let(:school_row) { described_class.new(data) }
  let(:data) { {} }

  describe "#eligible?" do
    subject { school_row.eligible? }

    let(:data) do
      {
        "EstablishmentStatus (name)" => status,
        "Section41Approved (name)" => section_41_approval,
        "TypeOfEstablishment (name)" => type_name,
      }
    end

    let(:section_41_approval) { nil }
    let(:status) { "Unknown" } # implementation assumes a string value
    let(:type_name) { nil }

    shared_examples "eligible if open" do
      context "and the school is open" do
        let(:status) { "open" }

        it { is_expected.to be_truthy }
      end

      context "and the school is proposed to close" do
        let(:status) { "proposed_to_close" }

        it { is_expected.to be_truthy }
      end

      context "and the school is not open" do
        it { is_expected.to be_falsey }
      end
    end

    GIAS::Types::ELIGIBLE_TYPES.each do |type|
      context "when the school type is #{type}" do
        let(:type_name) { type }

        include_examples "eligible if open"
      end
    end

    GIAS::Types::NOT_ELIGIBLE_TYPES.each do |type|
      context "when the school type is #{type}" do
        let(:type_name) { type }

        it { is_expected.to be_falsey }
      end
    end

    GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.each do |type|
      context "when the school type is #{type} with Section 41 approval" do
        let(:type_name) { type }
        let(:section_41_approval) { "Approved" }

        include_examples "eligible if open"
      end
    end
  end
end
