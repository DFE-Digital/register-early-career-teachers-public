RSpec.describe Schools::AccessBlocker do
  subject(:blocker) { described_class.new(school_urn:) }

  let(:school_urn) { gias_school.urn }

  describe "#blocked?" do
    context "when the school record is missing but the gias school exists" do
      let(:gias_school) { FactoryBot.create(:gias_school, :open, :state_school_type) }

      it "blocks access" do
        expect(blocker).to be_blocked
      end
    end

    context "when the gias school is closed" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :state_school_type, status: :closed) }

      it "blocks access" do
        expect(blocker).to be_blocked
      end
    end

    context "when the gias school is proposed to open" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :state_school_type, status: :proposed_to_open) }

      it "blocks access" do
        expect(blocker).to be_blocked
      end
    end

    context "when the school is independent, not section 41 approved, and has no ongoing training" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :independent_school_type, :not_section_41, status: :open) }

      it "blocks access" do
        expect(blocker).to be_blocked
      end
    end

    context "when the school is independent, not section 41 approved, and has ongoing training" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :independent_school_type, :not_section_41, status: :open) }
      let(:school) { gias_school.school }

      before do
        FactoryBot.create(:training_period, :unfinished, ect_at_school_period: FactoryBot.create(:ect_at_school_period, :unfinished, school:))
      end

      it "does not block access" do
        expect(blocker).not_to be_blocked
      end
    end

    context "when the school is independent, section 41 approved, and has no training periods yet" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :independent_school_type, :section_41, status: :open) }

      it "does not block access" do
        expect(blocker).not_to be_blocked
      end
    end
  end

  describe "#independent_school_without_funding?" do
    context "when the school is independent, not section 41 approved, and has no ongoing training" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :independent_school_type, :not_section_41, status: :open) }

      it { is_expected.to be_independent_school_without_funding }
    end

    context "when the independent school without funding is closed" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :independent_school_type, :not_section_41, status: :closed) }

      it { is_expected.not_to be_independent_school_without_funding }
    end

    context "when the school record is missing" do
      let(:gias_school) { FactoryBot.create(:gias_school, :open, :independent_school_type, :not_section_41) }

      it { is_expected.not_to be_independent_school_without_funding }
    end

    context "when the school is closed" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, :state_school_type, status: :closed) }

      it { is_expected.not_to be_independent_school_without_funding }
    end
  end
end
