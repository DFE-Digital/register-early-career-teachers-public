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

  describe "#migrated_evidende_held" do
    subject { participant_declaration.migrated_evidence_held }

    let(:participant_declaration) { FactoryBot.build(:migration_participant_declaration, evidence_held:) }

    {
      "75-percent-engagement-met" => "75-percent-engagement-met",
      "75-percent-engagement-met-reduced-induction" => "75-percent-engagement-met-reduced-induction",
      "materials-engaged-with-offline" => "materials-engaged-with-offline",
      "one-term-induction" => "one-term-induction",
      "other" => "other",
      "self-study-material completed" => "self-study-material-completed",
      "self-study-material-completed" => "self-study-material-completed",
      "training_event_attendance" => "training-event-attended",
      "training-event-attended" => "training-event-attended",
      "" => nil
    }.each do |ecf_value, rect_value|
      context "when the value is '#{ecf_value}'" do
        let(:evidence_held) { ecf_value }

        it { is_expected.to eq(rect_value) }
      end

      context "any other value" do
        let(:evidence_held) { "other_value" }

        it { is_expected.to eq(evidence_held) }
      end
    end
  end

  describe "#migrated_pupil_premium_uplift" do
    subject { participant_declaration.migrated_pupil_premium_uplift }

    let(:start_year) { 2022 }
    let(:cohort) { FactoryBot.create(:migration_cohort, start_year:) }
    let(:participant_declaration) { FactoryBot.build(:migration_participant_declaration, declaration_type:, cohort:) }

    %w[started].each do |checked_declaration_type|
      context "when the declaration is '#{checked_declaration_type}'" do
        let(:declaration_type) { checked_declaration_type }

        context "when the cohort is earlier than 2025/2026" do
          let(:start_year) { 2024 }

          it { is_expected.to eq(participant_declaration.pupil_premium_uplift) }
        end

        context "when the cohort is not earlier than 2025/2026" do
          let(:start_year) { 2025 }

          it { is_expected.to be_falsey }
        end
      end
    end

    %w[retained-1 retained-2 retained-3 retained-4 completed extended-1 extended-2 extended-3].each do |checked_declaration_type|
      context "when the declaration is '#{checked_declaration_type}'" do
        let(:declaration_type) { checked_declaration_type }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe "#migrated_sparsity_uplift" do
    subject { participant_declaration.migrated_sparsity_uplift }

    let(:start_year) { 2022 }
    let(:cohort) { FactoryBot.create(:migration_cohort, start_year:) }
    let(:participant_declaration) { FactoryBot.build(:migration_participant_declaration, declaration_type:, cohort:) }

    %w[started].each do |checked_declaration_type|
      context "when the declaration is '#{checked_declaration_type}'" do
        let(:declaration_type) { checked_declaration_type }

        context "when the cohort is earlier than 2025/2026" do
          let(:start_year) { 2024 }

          it { is_expected.to eq(participant_declaration.sparsity_uplift) }
        end

        context "when the cohort is not earlier than 2025/2026" do
          let(:start_year) { 2025 }

          it { is_expected.to be_falsey }
        end
      end
    end

    %w[retained-1 retained-2 retained-3 retained-4 completed extended-1 extended-2 extended-3].each do |checked_declaration_type|
      context "when the declaration is '#{checked_declaration_type}'" do
        let(:declaration_type) { checked_declaration_type }

        it { is_expected.to be_falsey }
      end
    end
  end
end
