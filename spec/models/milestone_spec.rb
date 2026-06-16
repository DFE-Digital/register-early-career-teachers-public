describe Milestone do
  let(:declaration_types) { %w[started retained-1 retained-2 retained-3 retained-4 completed extended-1 extended-2 extended-3] }

  describe "relationships" do
    it { is_expected.to belong_to(:schedule) }
  end

  describe "validations" do
    subject { FactoryBot.build(:milestone) }

    it { is_expected.to validate_presence_of(:schedule_id).with_message("Choose a schedule") }
    it { is_expected.to validate_presence_of(:start_date).with_message("Enter a start date") }
    it { is_expected.to validate_inclusion_of(:declaration_type).in_array(declaration_types).with_message("Choose a valid declaration type") }
    it { is_expected.to validate_comparison_of(:milestone_date).is_greater_than(:start_date).with_message("Milestone date must be after the start date").allow_nil }

    describe "declaration uniqueness" do
      subject(:milestone) { original.dup }

      let(:original) { FactoryBot.create(:milestone) }

      it "ensures declaration_type is used once per schedule" do
        expect(milestone).not_to be_valid
        expect(milestone.errors.messages.fetch(:declaration_type)).to include("Can be used once per schedule")
      end
    end

    describe "start date" do
      subject(:milestone) { FactoryBot.build(:milestone, schedule:, start_date:) }

      let(:contract_period) { FactoryBot.create(:contract_period, :next) }
      let(:schedule) { FactoryBot.create(:schedule, contract_period:) }

      context "when start date is before June 1st of the contract period year" do
        let(:start_date) { contract_period.started_on.prev_day }

        it "is invalid" do
          expect(milestone).not_to be_valid
          expect(milestone.errors.messages.fetch(:start_date)).to include("The start date must be on or after the 1 June #{contract_period.year}")
        end
      end

      context "when start date is on June 1st of the contract period year" do
        let(:start_date) { contract_period.started_on }

        it { is_expected.to be_valid }
      end

      context "when start date is after June 1st of the contract period year" do
        let(:start_date) { contract_period.started_on.next_day }

        it { is_expected.to be_valid }
      end
    end

    describe "milestone date" do
      subject(:milestone) do
        FactoryBot.build(:milestone,
                         start_date: Date.tomorrow,
                         milestone_date: Time.zone.today)
      end

      it "ensures milestone date is later than the start date" do
        expect(milestone).not_to be_valid
        expect(milestone.errors.messages.fetch(:milestone_date)).to include("Milestone date must be after the start date")
      end
    end
  end

  describe "ordering" do
    let(:declaration_types_in_the_wrong_order) { %w[extended-1 retained-2 retained-3 completed started extended-3 retained-1 retained-4 extended-2] }

    before do
      declaration_types_in_the_wrong_order.each do |declaration_type|
        FactoryBot.create(:milestone, declaration_type:)
      end
    end

    it "orders by the declaration_type" do
      expect(Milestone.in_declaration_order.map(&:declaration_type)).to eql(declaration_types)
    end
  end
end
