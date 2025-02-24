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

    it "sets the TRS first name" do
      teacher = subject.build
      expect(teacher.trs_first_name).to eq "Chester"
    end

    it "sets the TRS last name" do
      teacher = subject.build
      expect(teacher.trs_last_name).to eq "Thompson"
    end

    context "when an ECF User ID is supplied" do
      let(:ecf_user_id) { SecureRandom.uuid }

      it "stores the id" do
        teacher = described_class.new(trn:, full_name:, ecf_user_id:).build
        expect(teacher.ecf_user_id).to eq ecf_user_id
      end
    end

    context "when a teacher with the same TRN already exists" do
      let!(:existing_record) { FactoryBot.create(:teacher, trn:, trs_first_name: "Tucker", trs_last_name: "Jenkins") }

      it "returns the matched teacher record" do
        expect(subject.build.id).to eq existing_record.id
      end

      it "does not raise an error" do
        expect {
          subject.build
        }.not_to raise_error
      end

      context "when the name does not match the trs name" do
        it "sets the corrected_name" do
          subject.build

          expect(existing_record.reload.corrected_name).to eq full_name
        end
      end

      context "when the corrected_name is already set" do
        let!(:existing_record) do
          FactoryBot.create(:teacher, trn:, trs_first_name: "Tucker", trs_last_name: "Jenkins", corrected_name: "Bert Ward")
        end

        it "does not change the corrected_name" do
          expect {
            subject.build
          }.not_to(change { existing_record.corrected_name })
        end
      end
    end
  end
end
