describe ParityCheck::Request do
  it { expect(described_class).to have_attributes(table_name: "parity_check_requests") }

  describe "associations" do
    it { is_expected.to belong_to(:run) }
    it { is_expected.to belong_to(:lead_provider) }
  end

  describe "validations" do
    include_context "completable validations"

    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:run) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_presence_of(:method) }
    it { is_expected.to validate_inclusion_of(:method).in_array(%w[get post put]) }
  end
end
