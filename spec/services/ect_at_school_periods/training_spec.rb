xdescribe ECTAtSchoolPeriods::Training, pending: "written before the EOI model, needs adjustment" do
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

      it { is_expected.to eq(ongoing_training.delivery_partner) }
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

      it { is_expected.to eq(ongoing_training.delivery_partner.name) }
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

      it { is_expected.to eq(ongoing_training.lead_provider) }
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

      it { is_expected.to eq(ongoing_training.lead_provider.name) }
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

      it { is_expected.to eq(old_training.delivery_partner) }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.delivery_partner) }
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

      it { is_expected.to eq(old_training.delivery_partner.name) }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.delivery_partner.name) }
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

      it { is_expected.to eq(old_training.lead_provider) }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.lead_provider) }
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

      it { is_expected.to eq(old_training.lead_provider.name) }
    end

    context "when the ect has an ongoing training period at the school" do
      let!(:old_training) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let!(:ongoing_training) { FactoryBot.create(:training_period, :active, :for_ect, ect_at_school_period:) }

      it { is_expected.to eq(ongoing_training.lead_provider.name) }
    end
  end
end
