describe Migration::ParticipantDeclaration, type: :model do
  let(:cpd_lead_provider) { FactoryBot.create(:migration_cpd_lead_provider) }
  let(:lead_provider) { cpd_lead_provider.lead_provider }
  let(:cohort) { FactoryBot.create(:migration_cohort) }

  describe "associations" do
    it { is_expected.to belong_to(:participant_profile) }
    it { is_expected.to belong_to(:cpd_lead_provider) }
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to have_many(:statement_line_items) }
  end

  describe "#billable?" do
    subject { FactoryBot.build(:migration_participant_declaration, state:).billable? }

    %w[eligible payable paid].each do |checking_state|
      context "when the declaration state is #{checking_state}" do
        let(:state) { checking_state }

        it { is_expected.to be_truthy }
      end
    end

    %w[ineligible voided submmited awaiting_clawback clawed_back].each do |checking_state|
      context "when the declaration state is #{checking_state}" do
        let(:state) { checking_state }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe "#refundable?" do
    subject { FactoryBot.build(:migration_participant_declaration, state:).refundable? }

    %w[awaiting_clawback clawed_back].each do |checking_state|
      context "when the declaration state is #{checking_state}" do
        let(:state) { checking_state }

        it { is_expected.to be_truthy }
      end
    end

    %w[eligible payable paid ineligible voided submmited].each do |checking_state|
      context "when the declaration state is #{checking_state}" do
        let(:state) { checking_state }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe "#clawback_statement" do
    subject { participant_declaration.clawback_statement }

    let(:participant_declaration) { FactoryBot.build(:migration_participant_declaration) }

    %w[awaiting_clawback clawed_back].each do |checking_state|
      context "when there is a statement line item with state #{checking_state}" do
        let!(:statement_line_item) do
          FactoryBot.create(:migration_statement_line_item, participant_declaration:, state: checking_state)
        end

        it { is_expected.to eq(statement_line_item.statement) }
      end
    end

    %w[eligible payable paid ineligible voided submmited].each do |checking_state|
      context "when there is a statement line item with state #{checking_state} instead" do
        let!(:statement_line_item) do
          FactoryBot.create(:migration_statement_line_item, participant_declaration:, state: checking_state)
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe "#payment_statement" do
    subject { participant_declaration.payment_statement }

    let(:participant_declaration) { FactoryBot.build(:migration_participant_declaration) }

    %w[eligible payable paid].each do |checking_state|
      context "when there is a statement line item with state #{checking_state}" do
        let!(:statement_line_item) do
          FactoryBot.create(:migration_statement_line_item, participant_declaration:, state: checking_state)
        end

        it { is_expected.to eq(statement_line_item.statement) }
      end
    end

    %w[ineligible voided submmited awaiting_clawback clawed_back].each do |checking_state|
      context "when there is a statement line item with state #{checking_state} instead" do
        let!(:statement_line_item) do
          FactoryBot.create(:migration_statement_line_item, participant_declaration:, state: checking_state)
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe "#clawback_status" do
    subject { participant_declaration.clawback_status }

    let(:participant_declaration) { FactoryBot.build(:migration_participant_declaration) }

    %w[awaiting_clawback clawed_back].each do |checking_state|
      context "when there is a statement line item with state #{checking_state}" do
        let!(:statement_line_item) do
          FactoryBot.create(:migration_statement_line_item, participant_declaration:, state: checking_state)
        end

        it { is_expected.to eq(statement_line_item.state) }
      end
    end

    %w[eligible payable paid ineligible voided submmited].each do |checking_state|
      context "when there is a statement line item with state #{checking_state} instead" do
        let!(:statement_line_item) do
          FactoryBot.create(:migration_statement_line_item, participant_declaration:, state: checking_state)
        end

        it { is_expected.to eq("no_clawback") }
      end
    end
  end

  describe "#payment_status" do
    subject { participant_declaration.payment_status }

    let(:participant_declaration) { FactoryBot.build(:migration_participant_declaration) }

    %w[eligible payable paid].each do |checking_state|
      context "when there is a statement line item with state #{checking_state}" do
        let!(:statement_line_item) do
          FactoryBot.create(:migration_statement_line_item, participant_declaration:, state: checking_state)
        end

        it { is_expected.to eq(statement_line_item.state) }
      end
    end

    %w[ineligible voided submmited awaiting_clawback clawed_back].each do |checking_state|
      context "when there is a statement line item with state #{checking_state} instead" do
        let!(:statement_line_item) do
          FactoryBot.create(:migration_statement_line_item, participant_declaration:, state: checking_state)
        end

        it { is_expected.to eq("no_payment") }
      end
    end
  end
end
