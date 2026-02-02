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

  describe "#open_or_recently_closed?" do
    subject { school_row.open_or_recently_closed? }

    let(:data) do
      {
        "EstablishmentStatus (name)" => status,
        "CloseDate" => close_date,
      }
    end

    let(:status) { "Open" }
    let(:close_date) { nil }

    context "when the school is open" do
      it { is_expected.to be_truthy }
    end

    context "when the school is closed and the closure was prior to ECF service" do
      let(:status) { "Closed" }
      let(:close_date) { "01-03-2018" }

      it { is_expected.to be_falsey }
    end

    context "when the school is closed and the closure was during to ECF service" do
      let(:status) { "Closed" }
      let(:close_date) { "01-09-2021" }

      it { is_expected.to be_truthy }
    end
  end

  describe "#eligible_to_import?" do
    subject { school_row.eligible_to_import? }

    let(:data) do
      {
        "EstablishmentStatus (name)" => status,
        "Section41Approved (name)" => section_41_approval,
        "TypeOfEstablishment (name)" => type_name,
        "CloseDate" => close_date,
      }
    end

    let(:section_41_approval) { nil }
    let(:status) { "Unknown" } # implementation assumes a string value
    let(:type_name) { nil }
    let(:close_date) { nil }

    shared_examples "eligible to import" do
      context "and the school is open" do
        let(:status) { "open" }

        it { is_expected.to be_truthy }
      end

      context "and the school is proposed to close" do
        let(:status) { "proposed_to_close" }

        it { is_expected.to be_truthy }
      end

      context "and the school is not open and closed before ECF1 service" do
        let(:close_date) { "22-06-2004" }

        it { is_expected.to be_falsey }
      end

      context "and the school is not open and closed during ECF1 service" do
        let(:close_date) { "31-12-2022" }

        it { is_expected.to be_truthy }
      end
    end

    GIAS::Types::ELIGIBLE_TYPES.each do |type|
      context "when the school type is #{type}" do
        let(:type_name) { type }

        include_examples "eligible to import"
      end
    end

    GIAS::Types::INDEPENDENT_SCHOOLS_TYPES.each do |type|
      context "when the school type is #{type} with Section 41 approval" do
        let(:type_name) { type }
        let(:section_41_approval) { "Approved" }

        include_examples "eligible to import"
      end

      context "when the school type is #{type} without Section 41 approval" do
        let(:type_name) { type }
        let(:section_41_approval) { "Not approved" }

        include_examples "eligible to import"
      end
    end
  end
end
