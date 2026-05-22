describe Schedule do
  describe "relationships" do
    it { is_expected.to belong_to(:contract_period).inverse_of(:schedules).with_foreign_key(:contract_period_year) }
    it { is_expected.to have_many(:milestones) }
    it { is_expected.to have_many(:training_periods) }
  end

  describe "validation" do
    it { is_expected.to validate_presence_of(:contract_period_year).with_message("Enter a contract period year") }

    it "only allows valid identifiers" do
      types = %w[extended reduced replacement standard]
      months = %w[april january september]
      valid_identifiers = types.product(months).map { |combination| ["ecf", *combination].join("-") }
      message = "Choose an identifier from the list"

      expect(subject).to validate_inclusion_of(:identifier).in_array(valid_identifiers).with_message(message)
    end

    it "ensures uniqueness of contract years and identifiers" do
      original = FactoryBot.create(:schedule)
      duplicate = original.dup

      expect(duplicate).not_to be_valid
      expect(duplicate.errors.messages.fetch(:identifier)).to include("Can be used once per contract period")
    end
  end

  describe "scopes" do
    describe ".excluding_replacement_schedules" do
      subject { Schedule.excluding_replacement_schedules }

      let!(:replacement_schedule) { FactoryBot.create(:schedule, identifier: "ecf-replacement-april") }
      let!(:standard_schedule) { FactoryBot.create(:schedule, identifier: "ecf-standard-april") }

      it "returns only standard schedules" do
        expect(subject).to contain_exactly(standard_schedule)
      end
    end

    describe ".excluding_reduced_schedules" do
      subject { Schedule.excluding_reduced_schedules }

      let!(:reduced_schedule) { FactoryBot.create(:schedule, identifier: "ecf-reduced-april") }
      let!(:standard_schedule) { FactoryBot.create(:schedule, identifier: "ecf-standard-april") }

      it "returns only standard schedules" do
        expect(subject).to contain_exactly(standard_schedule)
      end
    end
  end

  describe "#replacement_schedule?" do
    subject { Schedule.new(identifier:) }

    context "with replacement schedules" do
      let(:identifier) { "ecf-replacement-april" }

      it { is_expected.to be_replacement_schedule }
    end

    context "with non-replacement schedules" do
      let(:identifier) { "ecf-standard-april" }

      it { is_expected.not_to be_replacement_schedule }
    end
  end

  describe "#reduced_schedule?" do
    subject { Schedule.new(identifier:) }

    context "with reduced schedules" do
      let(:identifier) { "ecf-reduced-april" }

      it { is_expected.to be_reduced_schedule }
    end

    context "with non-reduced schedules" do
      let(:identifier) { "ecf-standard-april" }

      it { is_expected.not_to be_reduced_schedule }
    end
  end

  describe "#fully_milestoned?" do
    subject(:schedule) { FactoryBot.create(:schedule) }

    let(:possible_milestones) { Milestone.declaration_types.values }

    context "when all possible milestones have been allocated to the schedule" do
      before do
        possible_milestones.each do |declaration_type|
          FactoryBot.create(:milestone, schedule:, declaration_type:)
        end
      end

      it { is_expected.to be_fully_milestoned }
    end

    context "when only some milestones have been allocated to the schedule" do
      before do
        possible_milestones.take(2).each do |declaration_type|
          FactoryBot.create(:milestone, schedule:, declaration_type:)
        end
      end

      it { is_expected.not_to be_fully_milestoned }
    end
  end

  # TODO: extract Schedule#name/,#description to a decorator?
  describe "decorations" do
    let(:schedule) { FactoryBot.build(:schedule, identifier: "ecf-standard-april", contract_period:) }
    let(:contract_period) { FactoryBot.build(:contract_period, year: 2023) }

    describe "#name" do
      subject { schedule.name }

      it { is_expected.to eq("Standard April") }
    end

    # TODO: use #name in the #description
    describe "#description" do
      subject { schedule.description }

      it { is_expected.to eq("ecf-standard-april for 2023") }
    end
  end

  describe "#available_milestones" do
    subject(:schedule) { FactoryBot.create(:schedule) }

    context "without associated milestones" do
      it "lists all possible milestones" do
        expect(schedule.available_milestones).to eq(%w[
          started
          retained-1
          retained-2
          retained-3
          retained-4
          completed
          extended-1
          extended-2
          extended-3
        ])
      end
    end

    context "with associated milestones" do
      let(:associated_milestones) do
        %w[completed retained-2 retained-1 started]
      end

      before do
        associated_milestones.each do |declaration_type|
          FactoryBot.create(:milestone, schedule:, declaration_type:)
        end
      end

      it "lists any remaining milestones" do
        expect(schedule.available_milestones).to eq(%w[
          retained-3 retained-4 extended-1 extended-2 extended-3
        ])
      end
    end
  end

  describe "#sorted_milestones" do
    subject(:schedule) { FactoryBot.create(:schedule) }

    let(:associated_milestones) do
      %w[completed retained-2 retained-1 started]
    end

    before do
      associated_milestones.each do |declaration_type|
        FactoryBot.create(:milestone, schedule:, declaration_type:)
      end
    end

    it "orders milestones by declaration_type as defined in the enum" do
      expect(schedule.sorted_milestones.map(&:declaration_type)).to eq(%w[
        started retained-1 retained-2 completed
      ])
    end
  end
end
