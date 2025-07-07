describe ParityCheck::Response do
  it { expect(described_class).to have_attributes(table_name: "parity_check_responses") }

  describe "associations" do
    it { is_expected.to belong_to(:request) }
  end

  describe "delegate methods" do
    it { is_expected.to delegate_method(:run).to(:request) }
  end

  describe "before_validation" do
    it "clears bodies if the response bodies match" do
      response = build(:parity_check_response, :different, ecf_body: "same", rect_body: "same")
      expect { response.save! }.to change { response.ecf_body }.to(nil).and change { response.rect_body }.to(nil)
    end
  end

  describe "before_save" do
    it "formats bodies as pretty JSON if they are valid JSON" do
      ecf_body = { ecf_key: "ecf_value" }
      rect_body = { rect_key: "rect_value" }
      response = build(:parity_check_response, ecf_body: ecf_body.to_json, rect_body: rect_body.to_json)

      response.save!

      expect(response.ecf_body).to eq(JSON.pretty_generate(ecf_body))
      expect(response.rect_body).to eq(JSON.pretty_generate(rect_body))
    end

    it "does not format bodies if they are not valid JSON" do
      response = build(:parity_check_response, ecf_body: "not json", rect_body: "also not json")

      response.save!

      expect(response.ecf_body).to eq("not json")
      expect(response.rect_body).to eq("also not json")
    end
  end

  describe "validations" do
    subject { build(:parity_check_response) }

    it { is_expected.to validate_presence_of(:request) }
    it { is_expected.to validate_inclusion_of(:ecf_status_code).in_range(100..599) }
    it { is_expected.to validate_inclusion_of(:rect_status_code).in_range(100..599) }
    it { is_expected.to validate_numericality_of(:ecf_time_ms).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:rect_time_ms).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:page).is_greater_than(0).only_integer.allow_nil }
    it { is_expected.to validate_uniqueness_of(:page).scoped_to(:request_id) }
  end

  describe "scopes" do
    let(:request) { create(:parity_check_request) }
    let!(:matching_response) { create(:parity_check_response, :matching, request:) }
    let!(:matching_status_codes_response) { create(:parity_check_response, :matching, ecf_body: "different", request:) }
    let!(:matching_bodies_response) { create(:parity_check_response, :matching, ecf_status_code: 404, request:) }
    let!(:different_response) { create(:parity_check_response, :different, request:) }

    describe ".different" do
      subject { described_class.different }

      it { is_expected.to contain_exactly(different_response, matching_status_codes_response, matching_bodies_response) }
    end

    describe ".matching" do
      subject { described_class.matching }

      it { is_expected.to contain_exactly(matching_response) }
    end

    describe ".status_codes_matching" do
      subject { described_class.status_codes_matching }

      it { is_expected.to contain_exactly(matching_response, matching_status_codes_response) }
    end

    describe ".status_codes_different" do
      subject { described_class.status_codes_different }

      it { is_expected.to contain_exactly(different_response, matching_bodies_response) }
    end

    describe ".bodies_different" do
      subject { described_class.bodies_different }

      it { is_expected.to contain_exactly(different_response, matching_status_codes_response) }
    end

    describe ".bodies_matching" do
      subject { described_class.bodies_matching }

      it { is_expected.to contain_exactly(matching_response, matching_bodies_response) }
    end
  end

  describe "#rect_performance_gain_ratio" do
    subject { response.rect_performance_gain_ratio }

    let(:response) { build(:parity_check_response, ecf_time_ms:, rect_time_ms:) }

    context "when there are no response times" do
      let(:rect_time_ms) { nil }
      let(:ecf_time_ms) { nil }

      it { is_expected.to be_nil }
    end

    context "when the response times are equal" do
      let(:rect_time_ms) { 100 }
      let(:ecf_time_ms) { rect_time_ms }

      it { is_expected.to eq(1.0) }
    end

    context "when the RECT response times are faster" do
      let(:rect_time_ms) { 87 }
      let(:ecf_time_ms) { 253 }

      it { is_expected.to eq(2.9) }
    end

    context "when the ECF response times are faster" do
      let(:rect_time_ms) { 253 }
      let(:ecf_time_ms) { 87 }

      it { is_expected.to eq(-2.9) }
    end
  end

  describe "#match_rate" do
    subject { response.match_rate }

    context "when the response is matching" do
      let(:response) { build(:parity_check_response, :matching) }

      it { is_expected.to eq(100) }
    end

    context "when the response is different" do
      let(:response) { build(:parity_check_response, :different) }

      it { is_expected.to eq(0) }
    end
  end

  describe "#description" do
    subject { response.description }

    context "when the response has a page" do
      let(:response) { build(:parity_check_response, page: 1) }

      it { is_expected.to eq("Response for page 1") }
    end

    context "when the response does not have a page" do
      let(:response) { build(:parity_check_response, page: nil) }

      it { is_expected.to eq("Response") }
    end
  end

  describe ".matching?" do
    subject { response }

    context "when the response is matching" do
      let(:response) { build(:parity_check_response, :matching) }

      it { is_expected.to be_matching }
    end

    context "when the response is different" do
      let(:response) { build(:parity_check_response, :different) }

      it { is_expected.not_to be_matching }
    end
  end

  describe ".different?" do
    subject { response }

    context "when the response is different" do
      let(:response) { build(:parity_check_response, :different) }

      it { is_expected.to be_different }
    end

    context "when the response is matching" do
      let(:response) { build(:parity_check_response, :matching) }

      it { is_expected.not_to be_different }
    end
  end

  describe "#bodies_matching?" do
    subject { response }

    context "when the ECF and RECT bodies are the same" do
      let(:response) { build(:parity_check_response, ecf_body: "body", rect_body: "body") }

      it { is_expected.to be_bodies_matching }
    end

    context "when the ECF and RECT bodies are different" do
      let(:response) { build(:parity_check_response, ecf_body: "ecf body", rect_body: "rect body") }

      it { is_expected.not_to be_bodies_matching }
    end
  end

  describe "#bodies_different?" do
    subject { response }

    context "when the ECF and RECT bodies are the same" do
      let(:response) { build(:parity_check_response, ecf_body: "body", rect_body: "body") }

      it { is_expected.not_to be_bodies_different }
    end

    context "when the ECF and RECT bodies are different" do
      let(:response) { build(:parity_check_response, ecf_body: "ecf body", rect_body: "rect body") }

      it { is_expected.to be_bodies_different }
    end
  end

  describe "#body_diff" do
    subject(:diff) { response.body_diff }

    let(:response) { create(:parity_check_response, :different) }

    it { is_expected.to be_a(Diffy::Diff) }

    it {
      expect(diff.to_s(:text)).to eq(
        <<~DIFF
          -ECF response body
          \\ No newline at end of file
          +RECT response body
          \\ No newline at end of file
        DIFF
      )
    }
  end
end
