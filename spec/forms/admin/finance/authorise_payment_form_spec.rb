RSpec.describe Admin::Finance::AuthorisePaymentForm, type: :model do
  subject { described_class.new(confirmed:) }

  shared_examples "invalid when unconfirmed" do
    it { is_expected.not_to be_valid }
    it { is_expected.to have_error(:confirmed, "You must have completed all assurance checks") }
  end

  context "when confirmed" do
    let(:confirmed) { "1" }

    it { is_expected.to be_valid }
  end

  context "when not confirmed" do
    let(:confirmed) { "0" }

    include_examples "invalid when unconfirmed"
  end

  context "when confirmed is not set" do
    let(:confirmed) { nil }

    include_examples "invalid when unconfirmed"
  end
end
