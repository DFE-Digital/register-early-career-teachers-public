RSpec.describe CheckValidityJob, type: :job do
  let(:checker) { double(CheckValidity) }

  before do
    allow(CheckValidity).to receive(:new).and_return(checker)
    allow(checker).to receive(:call)
  end

  describe ".queue_name" do
    it "is queued on the check_validity queue" do
      expect(described_class.queue_name).to eq("check_validity")
    end
  end

  describe "#perform" do
    it "runs the validity check" do
      described_class.new.perform

      expect(CheckValidity).to have_received(:new)
      expect(checker).to have_received(:call)
    end

    it "refuses to run in production" do
      allow(Rails.env).to receive(:production?).and_return(true)

      expect { described_class.new.perform }
        .to raise_error(CheckValidity::ProductionGuardError, "Do not query live production data")

      expect(checker).not_to have_received(:call)
    end
  end
end
