RSpec.describe Schools::AccessBlocker do
  subject(:blocker) { described_class.new(school_urn:) }

  describe "#blocked?" do
    context "when the school record is missing but the gias school exists" do
      let(:gias_school) { FactoryBot.create(:gias_school, :open, :state_school_type) }
      let(:school_urn) { gias_school.urn }

      it "blocks access" do
        expect(blocker).to be_blocked
      end
    end

    context "when the gias school is closed" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :state_school_type) }
      let(:school_urn) { gias_school.urn }

      before { gias_school.update!(status: :closed) }

      it "blocks access" do
        expect(blocker).to be_blocked
      end
    end

    context "when the school is independent, not section 41 approved, and has no ongoing training" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :independent_school_type, :not_section_41) }
      let(:school_urn) { gias_school.urn }

      it "blocks access" do
        expect(blocker).to be_blocked
      end
    end

    context "when the school is independent, not section 41 approved, and has ongoing training" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :independent_school_type, :not_section_41) }
      let(:school) { gias_school.school }
      let(:school_urn) { school.urn }

      before do
        FactoryBot.create(:training_period, :ongoing, ect_at_school_period: FactoryBot.create(:ect_at_school_period, school:))
      end

      it "does not block access" do
        expect(blocker).not_to be_blocked
      end
    end
  end
end
