describe ECTAtSchoolPeriods::Training do
  describe "#current_training_period" do
    subject { described_class.new(ect_at_school_period).current_training_period }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }

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
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training) }
    end
  end

  describe "#current_delivery_partner" do
    subject { described_class.new(ect_at_school_period).current_delivery_partner }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }

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
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.school_partnership.lead_provider_delivery_partnership.delivery_partner) }
    end
  end

  describe "#current_delivery_partner_name" do
    subject { described_class.new(ect_at_school_period).current_delivery_partner_name }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }

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
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.school_partnership.lead_provider_delivery_partnership.delivery_partner.name) }
    end
  end

  describe "#current_lead_provider" do
    subject { described_class.new(ect_at_school_period).current_lead_provider }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }

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
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.school_partnership.lead_provider_delivery_partnership.active_lead_provider.lead_provider) }
    end
  end

  describe "#current_lead_provider_name" do
    subject { described_class.new(ect_at_school_period).current_lead_provider_name }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }

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
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.school_partnership.lead_provider_delivery_partnership.active_lead_provider.lead_provider.name) }
    end
  end

  describe "#latest_training_period" do
    subject { described_class.new(ect_at_school_period).latest_training_period }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }

    context "when the ect has had no training ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past training periods" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 2.years.ago) }

      it { is_expected.to eq(old_training) }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training) }
    end
  end

  describe "#latest_delivery_partner" do
    subject { described_class.new(ect_at_school_period).latest_delivery_partner }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }

    context "when the ect has had no training ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past training periods" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 2.years.ago) }

      it { is_expected.to eq(old_training.school_partnership.lead_provider_delivery_partnership.delivery_partner) }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.school_partnership.lead_provider_delivery_partnership.delivery_partner) }
    end
  end

  describe "#latest_delivery_partner_name" do
    subject { described_class.new(ect_at_school_period).latest_delivery_partner_name }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }

    context "when the ect has had no training ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past training periods" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 2.years.ago) }

      it { is_expected.to eq(old_training.school_partnership.lead_provider_delivery_partnership.delivery_partner.name) }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.school_partnership.lead_provider_delivery_partnership.delivery_partner.name) }
    end
  end

  describe "#latest_lead_provider" do
    subject { described_class.new(ect_at_school_period).latest_lead_provider }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }

    context "when the ect has had no training ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past training periods" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 2.years.ago) }

      it { is_expected.to eq(old_training.school_partnership.lead_provider_delivery_partnership.active_lead_provider.lead_provider) }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.school_partnership.lead_provider_delivery_partnership.active_lead_provider.lead_provider) }
    end
  end

  describe "#latest_lead_provider_name" do
    subject { described_class.new(ect_at_school_period).latest_lead_provider_name }

    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, started_on: 3.years.ago) }

    context "when the ect has had no training ever" do
      it { is_expected.to be_nil }
    end

    context "when the ect has had past training periods" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 2.years.ago) }

      it { is_expected.to eq(old_training.school_partnership.lead_provider_delivery_partnership.active_lead_provider.lead_provider.name) }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.school_partnership.lead_provider_delivery_partnership.active_lead_provider.lead_provider.name) }
    end
  end

  describe '#latest_eoi_lead_provider_name' do
    subject { described_class.new(ect_at_school_period).latest_eoi_lead_provider_name }

    context 'when the latest training period is an expression of interest' do
      let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'Jimmy Provider') }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, :with_eoi_only_training_period, lead_provider:) }

      it 'returns the lead provider name from the EOI' do
        expect(subject).to eq('Jimmy Provider')
      end
    end

    context 'when there is no training period' do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when the latest training period has a school partnership' do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :with_training_period) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when multiple training periods exist and the latest is EOI only' do
      let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'EOI Provider') }

      let(:ect_at_school_period) do
        FactoryBot.create(:ect_at_school_period, :active).tap do |ect|
          FactoryBot.create(:training_period, :for_ect, ect_at_school_period: ect, started_on: ect.started_on + 1.week, finished_on: ect.started_on + 10.days)

          FactoryBot.create(
            :training_period,
            :for_ect,
            school_partnership: nil,
            expression_of_interest: FactoryBot.create(:active_lead_provider, lead_provider:),
            ect_at_school_period: ect,
            started_on: ect.started_on + 2.weeks,
            finished_on: ect.started_on + 1.month
          )
        end
      end

      it 'returns the lead provider name from the latest EOI only training period' do
        expect(subject).to eq('EOI Provider')
      end
    end

    context 'when multiple training periods exist and the latest is confirmed (not EOI only)' do
      let(:lead_provider) { FactoryBot.create(:lead_provider, name: 'Old EOI Provider') }

      let(:ect_at_school_period) do
        FactoryBot.create(:ect_at_school_period, :active, :with_eoi_only_training_period, lead_provider:)
      end

      let!(:confirmed_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on + 2.months,
          finished_on: ect_at_school_period.started_on + 3.months,
          school_partnership: FactoryBot.create(:school_partnership)
        )
      end

      it 'returns nil because latest training period is confirmed, and not an EOI' do
        expect(subject).to be_nil
      end
    end
  end
end
