describe FrameworkAgreement do
  describe "associations" do
    it { is_expected.to belong_to(:contract_period).with_foreign_key(:contract_period_year) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to have_many(:statements).through(:contracts) }
    it { is_expected.to have_many(:lead_provider_delivery_partnerships) }
    it { is_expected.to have_many(:school_partnerships).through(:lead_provider_delivery_partnerships) }
    it { is_expected.to have_many(:delivery_partners).through(:lead_provider_delivery_partnerships) }
    it { is_expected.to have_many(:expressions_of_interest).class_name("TrainingPeriod").inverse_of(:expression_of_interest) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:contracts) }
    it { is_expected.to have_many(:bands).class_name("FrameworkAgreement::Band").order(allocation_order: :asc) }
  end

  describe "validations" do
    subject { FactoryBot.create(:framework_agreement) }

    it { is_expected.to validate_presence_of(:lead_provider_id).with_message("Choose a lead provider") }
    it { is_expected.to validate_presence_of(:contract_period_year).with_message("Choose a contract period") }
    it { is_expected.to validate_uniqueness_of(:contract_period_year).scoped_to(:lead_provider_id).with_message("Contract period and lead provider must be unique") }
  end

  describe "#editable?" do
    subject { FactoryBot.create(:framework_agreement, contract_period:) }

    let(:contract_period) { FactoryBot.create(:contract_period) }

    it { is_expected.to be_editable }

    context "when the contract period is payments frozen" do
      let(:contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen) }

      it { is_expected.not_to be_editable }
    end
  end

  describe "scopes" do
    let!(:rp_1) { FactoryBot.create(:contract_period) }
    let!(:rp_2) { FactoryBot.create(:contract_period) }
    let!(:lp_1) { FactoryBot.create(:lead_provider) }
    let!(:lp_2) { FactoryBot.create(:lead_provider) }
    let!(:framework_agreement_1) { FactoryBot.create(:framework_agreement, contract_period: rp_1, lead_provider: lp_1) }
    let!(:framework_agreement_2) { FactoryBot.create(:framework_agreement, contract_period: rp_1, lead_provider: lp_2) }
    let!(:framework_agreement_3) { FactoryBot.create(:framework_agreement, contract_period: rp_2, lead_provider: lp_1) }
    let!(:framework_agreement_4) { FactoryBot.create(:framework_agreement, contract_period: rp_2, lead_provider: lp_2) }

    describe ".for_contract_period" do
      it "returns provider partnerships only for the specified academic year" do
        expect(described_class.for_contract_period(rp_1.id)).to contain_exactly(framework_agreement_1, framework_agreement_2)
      end
    end

    describe ".for_lead_provider" do
      it "returns provider partnerships only for the specified lead provider" do
        expect(described_class.for_lead_provider(lp_2.id)).to contain_exactly(framework_agreement_2, framework_agreement_4)
      end
    end

    describe ".available_for_delivery_partner" do
      let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
      let(:other_delivery_partner) { FactoryBot.create(:delivery_partner) }
      let(:contract_period) { FactoryBot.create(:contract_period) }
      let!(:available_alp_1) { FactoryBot.create(:framework_agreement, contract_period:) }
      let!(:available_alp_2) { FactoryBot.create(:framework_agreement, contract_period:) }
      let!(:assigned_framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
      let!(:different_year_framework_agreement) { FactoryBot.create(:framework_agreement, :for_year, year: contract_period.year + 1) }

      # Create an existing partnership for one of the framework agreements
      let!(:existing_partnership) do
        FactoryBot.create(:lead_provider_delivery_partnership,
                          delivery_partner:,
                          framework_agreement: assigned_framework_agreement)
      end

      it "returns available lead providers for the delivery partner and contract period" do
        result = described_class.available_for_delivery_partner(delivery_partner, contract_period)
        expect(result).to contain_exactly(available_alp_1, available_alp_2)
      end

      it "excludes already assigned lead providers" do
        result = described_class.available_for_delivery_partner(delivery_partner, contract_period)
        expect(result).not_to include(assigned_framework_agreement)
      end

      it "excludes lead providers from different contract periods" do
        result = described_class.available_for_delivery_partner(delivery_partner, contract_period)
        expect(result).not_to include(different_year_framework_agreement)
      end

      it "includes lead providers assigned to other delivery partners" do
        FactoryBot.create(:lead_provider_delivery_partnership,
                          delivery_partner: other_delivery_partner,
                          framework_agreement: available_alp_1)

        result = described_class.available_for_delivery_partner(delivery_partner, contract_period)
        expect(result).to include(available_alp_1)
      end

      it "orders results by lead provider name" do
        # Update lead provider names to test ordering
        available_alp_1.lead_provider.update!(name: "Zebra Lead Provider")
        available_alp_2.lead_provider.update!(name: "Alpha Lead Provider")

        result = described_class.available_for_delivery_partner(delivery_partner, contract_period)
        expect(result.map { |framework_agreement| framework_agreement.lead_provider.name }).to eq(["Alpha Lead Provider", "Zebra Lead Provider"])
      end

      it "includes the lead provider relationship" do
        result = described_class.available_for_delivery_partner(delivery_partner, contract_period).first
        expect(result.association(:lead_provider)).to be_loaded
      end
    end

    describe ".for_contract_period_year" do
      it "returns provider partnerships only for the specified contract period year" do
        expect(described_class.for_contract_period_year(rp_1.year)).to contain_exactly(framework_agreement_1, framework_agreement_2)
      end
    end

    describe ".without_existing_partnership_for" do
      let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
      let(:contract_period) { FactoryBot.create(:contract_period) }
      let!(:available_framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
      let!(:partnered_framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
      let!(:different_period_framework_agreement) { FactoryBot.create(:framework_agreement) }

      before do
        FactoryBot.create(:lead_provider_delivery_partnership,
                          delivery_partner:,
                          framework_agreement: partnered_framework_agreement)
      end

      it "returns framework agreements without existing partnerships for the delivery partner and contract period" do
        result = described_class.without_existing_partnership_for(delivery_partner, contract_period)
        expect(result).to include(available_framework_agreement)
        expect(result).not_to include(partnered_framework_agreement)
      end

      it "includes framework agreements from different contract periods even if they have partnerships" do
        result = described_class.without_existing_partnership_for(delivery_partner, contract_period)
        expect(result).to include(different_period_framework_agreement)
      end

      it "includes framework agreements that have partnerships with other delivery partners" do
        other_delivery_partner = FactoryBot.create(:delivery_partner)
        other_partnered_framework_agreement = FactoryBot.create(:framework_agreement, contract_period:)
        FactoryBot.create(:lead_provider_delivery_partnership,
                          delivery_partner: other_delivery_partner,
                          framework_agreement: other_partnered_framework_agreement)

        result = described_class.without_existing_partnership_for(delivery_partner, contract_period)
        expect(result).to include(other_partnered_framework_agreement)
      end
    end

    describe ".with_lead_provider_ordered_by_name" do
      let!(:zebra_framework_agreement) { FactoryBot.create(:framework_agreement, lead_provider: FactoryBot.create(:lead_provider, name: "Zebra Provider")) }
      let!(:alpha_framework_agreement) { FactoryBot.create(:framework_agreement, lead_provider: FactoryBot.create(:lead_provider, name: "Alpha Provider")) }
      let!(:beta_framework_agreement) { FactoryBot.create(:framework_agreement, lead_provider: FactoryBot.create(:lead_provider, name: "Beta Provider")) }

      it "returns framework agreements ordered by lead provider name" do
        result = described_class.with_lead_provider_ordered_by_name
        lead_provider_names = result.map { |framework_agreement| framework_agreement.lead_provider.name }
        expect(lead_provider_names).to eq(lead_provider_names.sort)
      end

      it "includes the lead provider association" do
        result = described_class.with_lead_provider_ordered_by_name.first
        expect(result.association(:lead_provider)).to be_loaded
      end
    end
  end

  describe "#bands_can_be_added_and_removed?" do
    subject { framework_agreement.bands_can_be_added_and_removed? }

    let(:contract_period) { FactoryBot.create(:contract_period, :next) }
    let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }

    context "when there are no contracts" do
      context "and the contract period has not started" do
        it { is_expected.to be true }
      end

      context "and the contract period has started" do
        it { travel_to(contract_period.started_on) { is_expected.to be false } }
      end
    end

    context "when there are contracts" do
      before do
        FactoryBot.create(:contract, framework_agreement:)
      end

      context "and the contract period has not started" do
        it { is_expected.to be false }
      end

      context "and the contract period has started" do
        it { travel_to(contract_period.started_on) { is_expected.to be false } }
      end
    end
  end
end
