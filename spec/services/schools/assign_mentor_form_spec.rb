describe Schools::AssignMentorForm, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:ect).with_message("ECT missing or not registered at this school") }
    it { is_expected.to validate_presence_of(:mentor_id).with_message("Radios cannot be left blank") }

    describe "mentor at school" do
      context "when the mentor is not registered at all" do
        subject { described_class.new(mentor_id: 7) }

        before do
          subject.valid?
        end

        it "adds a base error" do
          expect(subject.errors.messages[:mentor_id]).to include("This mentor is not registered at this school")
        end
      end

      context "when the mentor is not registered at the ect's school" do
        let(:ect) { FactoryBot.create(:ect_at_school_period, :active) }
        let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active) }

        subject { described_class.new(ect:, mentor_id: mentor.id) }

        before do
          subject.valid?
        end

        it "adds a base error" do
          expect(subject.errors.messages[:mentor_id]).to include("This mentor is not registered at this school")
        end
      end
    end

    describe "mentorship authorised" do
      context "when the school has no eligible mentors for the ect" do
        let(:ect) { FactoryBot.create(:ect_at_school_period, :active) }
        let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, school: ect.school, teacher: ect.teacher) }

        subject { described_class.new(ect:, mentor_id: mentor.id) }

        before do
          subject.valid?
        end

        it "adds a base error" do
          expect(subject.errors.messages[:mentor_id]).to include("This teacher cannot be mentoring this ECT")
        end
      end
    end
  end

  describe "#save" do
    context "when the mentor is eligible to mentor the ect at the same school" do
      let(:ect) { FactoryBot.create(:ect_at_school_period, :active) }
      let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, school: ect.school) }

      subject { described_class.new(ect:, mentor_id: mentor.id) }

      it 'adds a new mentorship for the ect and the mentor starting today' do
        expect(ect.current_mentor).to be_nil

        subject.save

        expect(ect.current_mentor).to eq(mentor)
        expect(ect.current_mentorship.started_on).to eq(Date.current)
      end
    end
  end
end
