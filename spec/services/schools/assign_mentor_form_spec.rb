RSpec.describe Schools::AssignMentorForm, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:ect).with_message("ECT missing or not registered at this school") }
    it { is_expected.to validate_presence_of(:mentor_id).with_message("Select a mentor from the list provided or choose to register a new mentor") }

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
        subject { described_class.new(ect:, mentor_id: mentor.id) }

        let(:ect) { FactoryBot.create(:ect_at_school_period, :active) }
        let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active) }

        before do
          subject.valid?
        end

        it "adds a base error" do
          expect(subject.errors.messages[:mentor_id]).to include("This mentor is not registered at this school")
        end
      end
    end

    describe "mentorship authorised" do
      context "when the mentor is not eligible for the ect" do
        subject { described_class.new(ect:, mentor_id: mentor.id) }

        let(:ect) { FactoryBot.create(:ect_at_school_period, :active) }
        let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, school: ect.school, teacher: ect.teacher) }

        before do
          subject.valid?
        end

        it "adds a base error" do
          expect(subject.errors.messages[:mentor_id]).to include("It needs to be a different mentor for this ECT")
        end
      end
    end
  end

  describe "#save" do
    context "when the mentor is eligible to mentor the ect at the same school" do
      subject { described_class.new(ect:, mentor_id: mentor.id) }

      let(:ect) { FactoryBot.create(:ect_at_school_period, :active) }
      let(:author) { FactoryBot.create(:school_user, school_urn: ect.school.urn) }
      let(:mentor) { FactoryBot.create(:mentor_at_school_period, :active, school: ect.school) }

      it 'adds a new mentorship for the ect and the mentor starting today' do
        expect(ECTAtSchoolPeriods::Mentorship.new(ect).current_mentor).to be_nil

        expect(subject.save(author:)).to be_truthy

        expect(ECTAtSchoolPeriods::Mentorship.new(ect).current_mentor).to eq(mentor)
        expect(ECTAtSchoolPeriods::Mentorship.new(ect).current_mentorship_period.started_on).to eq(Date.current)
      end
    end
  end
end
