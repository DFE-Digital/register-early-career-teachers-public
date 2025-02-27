describe Schools::TeacherEmail do
  let(:email) { "test@example.com" }
  let(:trn) { "123456" }
  subject { described_class.new(email:, trn:) }

  describe "#is_currently_used?" do
    before do
      allow(subject).to receive(:email_in_use_by_ongoing_ect?).and_return(ect_in_use)
      allow(subject).to receive(:email_in_use_by_ongoing_mentor?).and_return(mentor_in_use)
    end

    context "when the email is in use by an ongoing ECT" do
      let(:ect_in_use) { true }
      let(:mentor_in_use) { false }

      it "returns true" do
        expect(subject.is_currently_used?).to be true
      end
    end

    context "when the email is in use by an ongoing Mentor" do
      let(:ect_in_use) { false }
      let(:mentor_in_use) { true }

      it "returns true" do
        expect(subject.is_currently_used?).to be true
      end
    end

    context "when the email is not in use" do
      let(:ect_in_use) { false }
      let(:mentor_in_use) { false }

      it "returns false" do
        expect(subject.is_currently_used?).to be false
      end
    end
  end
end
