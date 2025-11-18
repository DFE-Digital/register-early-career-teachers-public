describe ECTAtSchoolPeriods::CurrentTraining do
  describe "#current_or_next_training_period" do
    subject { described_class.new(ect_at_school_period).current_or_next_training_period }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.years.ago) }

    context "when the ect has had no training ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past training periods" do
      before do
        FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 2.years.ago)
      end

      it { is_expected.to be_nil }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :ongoing, :for_ect, ect_at_school_period:, period_start_date: old_training.finished_on) }

      it { is_expected.to eq(ongoing_training) }
    end
  end

  describe "#lead_provider_via_school_partnership_or_eoi" do
    subject { ECTAtSchoolPeriods::CurrentTraining.new(ect_at_school_period).lead_provider_via_school_partnership_or_eoi }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.years.ago) }

    context "when there is a lead provider via school partnership" do
      let(:school_partnership) { FactoryBot.create(:school_partnership) }

      before { FactoryBot.create(:training_period, :ongoing, school_partnership:, ect_at_school_period:) }

      it "returns the lead provider connected via school partnership" do
        expect(subject).to eql(school_partnership.lead_provider)
      end
    end

    context "when there is only a lead provider via expression of interest" do
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider) }

      before { FactoryBot.create(:training_period, :ongoing, :with_no_school_partnership, ect_at_school_period:, expression_of_interest: active_lead_provider) }

      it "returns the lead provider connected via expression of interest" do
        expect(subject).to eql(active_lead_provider.lead_provider)
      end
    end

    context "when there are both lead provider via school partnership and expression of interest" do
      let(:school_partnership) { FactoryBot.create(:school_partnership) }
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period: school_partnership.contract_period) }

      before { FactoryBot.create(:training_period, :ongoing, expression_of_interest: active_lead_provider, school_partnership:, ect_at_school_period:) }

      it "returns the lead provider connected via school partnership" do
        expect(subject).to eql(school_partnership.lead_provider)
        expect(subject).not_to eql(active_lead_provider.lead_provider)
      end
    end
  end

  describe "#delivery_partner" do
    subject { described_class.new(ect_at_school_period).delivery_partner }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.years.ago) }

    context "when the ect has had no training ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past training periods" do
      before do
        FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 2.years.ago)
      end

      it { is_expected.to be_nil }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :ongoing, :for_ect, ect_at_school_period:, period_start_date: old_training.finished_on) }

      it { is_expected.to eq(ongoing_training.school_partnership.lead_provider_delivery_partnership.delivery_partner) }
    end
  end

  describe "#delivery_partner_name" do
    subject { described_class.new(ect_at_school_period).delivery_partner_name }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.years.ago) }

    context "when the ect has had no training ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past training periods" do
      before do
        FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 2.years.ago)
      end

      it { is_expected.to be_nil }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :ongoing, :for_ect, ect_at_school_period:, period_start_date: old_training.finished_on) }

      it { is_expected.to eq(ongoing_training.school_partnership.lead_provider_delivery_partnership.delivery_partner.name) }
    end
  end

  describe "#lead_provider" do
    subject { described_class.new(ect_at_school_period).lead_provider }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.years.ago) }

    context "when the ect has had no training ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past training periods" do
      before do
        FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 2.years.ago)
      end

      it { is_expected.to be_nil }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :ongoing, :for_ect, ect_at_school_period:, period_start_date: old_training.finished_on) }

      it { is_expected.to eq(ongoing_training.school_partnership.lead_provider_delivery_partnership.active_lead_provider.lead_provider) }
    end
  end

  describe "#lead_provider_name" do
    subject { described_class.new(ect_at_school_period).lead_provider_name }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.years.ago) }

    context "when the ect has had no training ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past training periods" do
      before do
        FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 2.years.ago)
      end

      it { is_expected.to be_nil }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :ongoing, :for_ect, period_start_date: old_training.finished_on, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.school_partnership.lead_provider_delivery_partnership.active_lead_provider.lead_provider.name) }
    end
  end

  describe "#expression_of_interest?" do
    subject { described_class.new(ect_at_school_period).expression_of_interest? }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.years.ago) }

    context "when the ect has had no training ever" do
      it { is_expected.to be(false) }
    end

    context "when the ect has a training period which is an expression of interest" do
      let!(:expression_of_interest_training_period) { FactoryBot.create(:training_period, :ongoing, :with_only_expression_of_interest, ect_at_school_period:) }

      it { is_expected.to be(true) }
    end

    context "when the ect has a training period which was an expression of interest but now has a partnership too" do
      let!(:expression_of_interest_training_period) { FactoryBot.create(:training_period, :ongoing, :with_expression_of_interest, ect_at_school_period:) }

      it { is_expected.to be(false) }
    end
  end

  describe "#expression_of_interest_lead_provider_name" do
    subject { described_class.new(ect_at_school_period).expression_of_interest_lead_provider_name }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.years.ago) }

    context "when the ect has had no training ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has a training period which is an expression of interest" do
      let!(:expression_of_interest_training_period) { FactoryBot.create(:training_period, :ongoing, :with_only_expression_of_interest, ect_at_school_period:) }

      it { is_expected.to eql(expression_of_interest_training_period.expression_of_interest.lead_provider.name) }
    end

    context "when the ect has a training period which was an expression of interest but now has a partnership too" do
      let!(:expression_of_interest_training_period) { FactoryBot.create(:training_period, :ongoing, :with_expression_of_interest, ect_at_school_period:) }

      it { is_expected.to eql(expression_of_interest_training_period.expression_of_interest.lead_provider.name) }
    end
  end
end
