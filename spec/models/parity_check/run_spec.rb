describe ParityCheck::Run do
  it { expect(described_class).to have_attributes(table_name: "parity_check_runs") }

  describe "associations" do
    it { is_expected.to have_many(:requests) }
  end

  describe "validations" do
    include_context "completable validations"

    it { is_expected.to validate_presence_of(:started_at) }
  end
end
