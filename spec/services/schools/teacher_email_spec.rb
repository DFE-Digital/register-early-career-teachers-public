describe Schools::TeacherEmail do
  let(:finished_ect_at_school_period) { FactoryBot.create(:ect_at_school_period) }
  let(:ongoing_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active) }

  let(:finished_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period) }
  let(:ongoing_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :active) }

  let(:trn) { '123456' }
  subject { described_class.new(email:, trn:) }

  describe "#is_currently_used?" do
    context "when the email is in use by an ongoing ECT" do
      let(:email) { ongoing_ect_at_school_period.email }

      it "returns true" do
        expect(subject.is_currently_used?).to be true
      end
    end

    context "when the email is in use by an ongoing Mentor" do
      let(:email) { ongoing_mentor_at_school_period.email }

      it "returns true" do
        expect(subject.is_currently_used?).to be true
      end
    end

    context "when the email is in use by the same teacher" do
      let(:trn) { ongoing_ect_at_school_period.teacher.trn }
      let(:email) { ongoing_ect_at_school_period.email }

      it "returns false" do
        expect(subject.is_currently_used?).to be false
      end
    end

    context "when the email has been used by the same teacher in the past" do
      let(:teacher) { ongoing_ect_at_school_period.teacher }
      let(:trn) { teacher.trn }
      let(:email) { FactoryBot.create(:ect_at_school_period, :finished, teacher:).email }

      it "returns false" do
        expect(subject.is_currently_used?).to be false
      end
    end

    context "when the email was used by an ECT in the past" do
      let(:email) { finished_ect_at_school_period.email }

      it "returns false" do
        expect(subject.is_currently_used?).to be false
      end
    end

    context "when the email was used by a Mentor in the past" do
      let(:email) { finished_mentor_at_school_period.email }

      it "returns false" do
        expect(subject.is_currently_used?).to be false
      end
    end

    context "when the email has never been used before" do
      let(:email) { 'never_been_used@example.com' }

      it "returns false" do
        expect(subject.is_currently_used?).to be false
      end
    end
  end
end
