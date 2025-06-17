describe ParityCheck::Request do
  it { expect(described_class).to have_attributes(table_name: "parity_check_requests") }

  describe "associations" do
    it { is_expected.to belong_to(:run) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:endpoint) }
    it { is_expected.to have_many(:responses) }
  end

  describe "validations" do
    include_context "completable validations"

    it { is_expected.not_to validate_presence_of(:started_at) }
    it { is_expected.to validate_presence_of(:lead_provider) }
    it { is_expected.to validate_presence_of(:endpoint) }
    it { is_expected.to validate_presence_of(:run) }
  end
end
