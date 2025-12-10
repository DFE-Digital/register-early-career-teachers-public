RSpec.describe DeclarationDateWithinMilestoneValidator, type: :model do
  subject { model_class.new(declaration_date:) }

  let(:model_class) do
    Class.new do
      include ActiveModel::Model

      attr_accessor :declaration_date

      validates :declaration_date, declaration_date_within_milestone: true

      def milestone
        Milestone.first
      end
    end
  end

  let(:declaration_date) { Date.new(2022, 1, 30) }
  let(:start_date) { Date.new(2022, 1, 29) }
  let(:milestone_date) { Date.new(2022, 1, 31) }

  let!(:milestone) { FactoryBot.create(:milestone, start_date:, milestone_date:) }

  context "when before the milestone start" do
    let(:declaration_date) { Date.new(2022, 1, 28) }

    it "has a meaningful error" do
      expect(subject).to be_invalid
      expect(subject.errors.messages_for(:declaration_date)).to eq(["Declaration date must be on or after the milestone start date for the same declaration type."])
    end
  end

  context "when at the milestone start" do
    let(:declaration_date) { start_date }

    it { is_expected.to be_valid }
  end

  context "when in the middle of milestone" do
    let(:declaration_date) { start_date + 1 }

    it { is_expected.to be_valid }
  end

  context "when at the milestone end" do
    let(:declaration_date) { milestone_date }

    it { is_expected.to be_valid }
  end

  context "when after the milestone start" do
    let(:declaration_date) { milestone_date + 1 }

    it "has a meaningful error" do
      expect(subject).to be_invalid
      expect(subject.errors.messages_for(:declaration_date)).to eq(["Declaration date must be on or before the milestone date for the same declaration type."])
    end
  end
end
