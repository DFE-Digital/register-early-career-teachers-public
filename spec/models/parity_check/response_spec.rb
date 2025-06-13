describe ParityCheck::Response do
  it { expect(described_class).to have_attributes(table_name: "parity_check_responses") }

  describe "associations" do
    it { is_expected.to belong_to(:request) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:request) }
    it { is_expected.to validate_inclusion_of(:ecf_status_code).in_range(100..599) }
    it { is_expected.to validate_inclusion_of(:rect_status_code).in_range(100..599) }
    it { is_expected.to validate_numericality_of(:ecf_time_ms).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:rect_time_ms).is_greater_than(0) }

    context "when the response comparison is equal" do
      subject { described_class.new(ecf_status_code: 200, rect_status_code: 200) }

      it { is_expected.not_to validate_presence_of(:ecf_body) }
      it { is_expected.not_to validate_presence_of(:rect_body) }
    end

    context "when the response comparison is different" do
      subject { described_class.new(ecf_status_code: 404, rect_status_code: 200) }

      it { is_expected.to validate_presence_of(:ecf_body) }
      it { is_expected.to validate_presence_of(:rect_body) }
    end
  end
end
