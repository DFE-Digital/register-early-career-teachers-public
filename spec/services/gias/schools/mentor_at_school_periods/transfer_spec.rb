RSpec.describe GIAS::Schools::MentorAtSchoolPeriods::Transfer do
  let(:author) { Events::SystemAuthor.new }
  let(:predecessor_gias_school) { FactoryBot.create(:gias_school, :with_school) }
  let(:gias_school) { FactoryBot.create(:gias_school, :with_school) }
  let(:predecessor_school) { predecessor_gias_school.school }
  let(:target_school) { gias_school.school }

  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period,  school: predecessor_school) }

  describe ".prepare" do
    subject(:prepare) { described_class.prepare(period: mentor_at_school_period, target_school:) }

    it "updates the mentor_at_school_period's school to the target school" do
      prepare
      expect(mentor_at_school_period.school).to eq(target_school)
    end

    context "when the mentor_at_school_period has associated training periods" do

      context "when there are no school partnerships which need moving" do
      end

      context "when there are school partnerships which need moving" do
      end
    end

    context "when the mentor_at_school_period has associated mentorship periods" do
      context "when there are no school partnerships which need moving" do
      end

      context "when there are school partnerships which need moving" do
      end
    end

    context "when the mentor_at_school_period has associated events" do
      context "when there are no school partnerships which need moving" do
      end

      context "when there are school partnerships which need moving" do
      end
    end

      
  end

  describe ".move!" do
    subject(:move!) { described_class.move!(period: mentor_at_school_period, target_school:) }

    it "updates the mentor_at_school_period's school to the target school" do
      move!
      
      expect(mentor_at_school_period.reload.school).to eq(target_school)
    end

    context "when the mentor_at_school_period has associated training periods" do

      context "when there are no school partnerships which need moving" do
      end

      context "when there are school partnerships which need moving" do
      end
    end

    context "when the mentor_at_school_period has associated mentorship periods" do
      context "when there are no school partnerships which need moving" do
      end

      context "when there are school partnerships which need moving" do
      end
    end

    context "when the mentor_at_school_period has associated events" do
      context "when there are no school partnerships which need moving" do
      end

      context "when there are school partnerships which need moving" do
      end
    end
  end
   
end
