describe Builders::Teacher do
  let(:trn) { "1234567" }
  let(:full_name) { "Chester Thompson" }

  subject(:processor) { described_class.new(trn:, full_name:) }

  describe '#build' do
    it "creates a new Teacher record" do
      expect {
        subject.build
      }.to change { Teacher.count }.by(1)
    end

    it "returns the created teacher record" do
      expect(subject.build).to be_a Teacher
    end

    it "sets the TRN correctly" do
      teacher = subject.build
      expect(teacher.trn).to eq trn
    end

    it "sets the first name" do
      teacher = subject.build
      expect(teacher.first_name).to eq "Chester"
    end

    it "sets the last name" do
      teacher = subject.build
      expect(teacher.last_name).to eq "Thompson"
    end

    context "when a legacy_id is supplied" do
      let(:legacy_id) { SecureRandom.uuid }

      it "stores the legacy_id" do
        teacher = described_class.new(trn:, full_name:, legacy_id:).build
        expect(teacher.legacy_id).to eq legacy_id
      end
    end

    context "when a teacher with the same TRN already exists" do
      before do
        FactoryBot.create(:teacher, trn:)
      end

      it "creates a migration failure record" do
        allow_any_instance_of(::FailureManager).to receive(:record_failure)

        subject.build
      end

      it "returns nil" do
        expect(subject.build).to be_nil
      end
    end
  end
end
