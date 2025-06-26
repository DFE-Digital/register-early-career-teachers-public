describe ParityCheck::Response do
  it { expect(described_class).to have_attributes(table_name: "parity_check_responses") }

  describe "associations" do
    it { is_expected.to belong_to(:request) }
  end

  describe "before_validation" do
    it "clears bodies if the responses are the same" do
      response = FactoryBot.build(:parity_check_response, :equal)
      expect { response.save! }.to change { response.ecf_body }.to(nil).and change { response.rect_body }.to(nil)
    end
  end

  describe "validations" do
    subject { FactoryBot.build(:parity_check_response) }

    it { is_expected.to validate_presence_of(:request) }
    it { is_expected.to validate_inclusion_of(:ecf_status_code).in_range(100..599) }
    it { is_expected.to validate_inclusion_of(:rect_status_code).in_range(100..599) }
    it { is_expected.to validate_numericality_of(:ecf_time_ms).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:rect_time_ms).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:page).is_greater_than(0).only_integer.allow_nil }
    it { is_expected.to validate_uniqueness_of(:page).scoped_to(:request_id) }
  end
end
