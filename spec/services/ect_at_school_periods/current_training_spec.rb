describe ECTAtSchoolPeriods::CurrentTraining do
  describe "#training_period" do
    subject { described_class.new(ect_at_school_period).current_training_period }

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
      let!(:ongoing_training) { FactoryBot.create(:training_period, :ongoing, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training) }
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
      let!(:ongoing_training) { FactoryBot.create(:training_period, :ongoing, :for_ect, ect_at_school_period:) }

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
      let!(:ongoing_training) { FactoryBot.create(:training_period, :ongoing, :for_ect, ect_at_school_period:) }

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
      let!(:ongoing_training) { FactoryBot.create(:training_period, :ongoing, :for_ect, ect_at_school_period:) }

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
      let!(:ongoing_training) { FactoryBot.create(:training_period, :ongoing, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.school_partnership.lead_provider_delivery_partnership.active_lead_provider.lead_provider.name) }
    end
  end

  describe '#expression_of_interest?' do
    subject { described_class.new(ect_at_school_period).expression_of_interest? }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.years.ago) }

    context 'when the ect has had no training ever' do
      it { is_expected.to be(false) }
    end

    context 'when the ect has a training period which is an expression of interest' do
      let!(:expression_of_interest_training_period) { FactoryBot.create(:training_period, :ongoing, :with_only_expression_of_interest, ect_at_school_period:) }

      it { is_expected.to be(true) }
    end

    context 'when the ect has a training period which was an expression of interest but now has a partnership too' do
      let!(:expression_of_interest_training_period) { FactoryBot.create(:training_period, :ongoing, :with_expression_of_interest, ect_at_school_period:) }

      it { is_expected.to be(false) }
    end
  end

  describe '#expression_of_interest_lead_provider_name' do
    subject { described_class.new(ect_at_school_period).expression_of_interest_lead_provider_name }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, started_on: 3.years.ago) }

    context 'when the ect has had no training ever' do
      it { is_expected.to be_nil }
    end

    context 'when the ect has a training period which is an expression of interest' do
      let!(:expression_of_interest_training_period) { FactoryBot.create(:training_period, :ongoing, :with_only_expression_of_interest, ect_at_school_period:) }

      it { is_expected.to eql(expression_of_interest_training_period.expression_of_interest.lead_provider.name) }
    end

    context 'when the ect has a training period which was an expression of interest but now has a partnership too' do
      let!(:expression_of_interest_training_period) { FactoryBot.create(:training_period, :ongoing, :with_expression_of_interest, ect_at_school_period:) }

      it { is_expected.to eql(expression_of_interest_training_period.expression_of_interest.lead_provider.name) }
    end
  end
end
