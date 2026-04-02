RSpec.describe Schools::RegisterECTWizard::RegistrationStore::Queries do
  subject(:queries) { described_class.new(registration_store:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:trn) { teacher.trn }
  let(:previous_ect_period) { instance_double(ECTAtSchoolPeriod, id: 123) }

  let(:registration_store) do
    Struct.new(:trn, :appropriate_body_id, :lead_provider_id, :start_date, :ect_at_school_period_id)
      .new(
        trn,
        appropriate_body_id,
        lead_provider_id,
        start_date,
        ect_at_school_period_id
      )
  end

  let(:appropriate_body_id) { nil }
  let(:lead_provider_id) { nil }
  let(:start_date) { nil }
  let(:ect_at_school_period_id) { nil }

  def setup_previous_training_history(previous_ect_period:, previous_training_period:, trn:)
    ect_period_search = instance_double(ECTAtSchoolPeriods::Search)
    training_period_search = instance_double(TrainingPeriods::Search)

    allow(ECTAtSchoolPeriods::Search).to receive(:new)
      .with(order: :started_on)
      .and_return(ect_period_search)

    allow(ect_period_search).to receive(:ect_periods)
      .with(trn:)
      .and_return([previous_ect_period])

    allow(TrainingPeriods::Search).to receive(:new)
      .with(order: :started_on)
      .and_return(training_period_search)

    allow(training_period_search).to receive(:training_periods)
      .with(ect_id: previous_ect_period.id)
      .and_return([previous_training_period])
  end

  def stub_previous_training(previous_training_period, previous_ect_period: self.previous_ect_period)
    setup_previous_training_history(
      previous_ect_period:,
      previous_training_period:,
      trn: registration_store.trn
    )
  end

  def create_contract_period(year:, payments_frozen: false)
    traits = []
    traits << :with_payments_frozen if payments_frozen

    FactoryBot.create(
      :contract_period,
      *traits,
      year:,
      started_on: Date.new(year, 9, 1),
      finished_on: Date.new(year + 1, 8, 31)
    )
  end

  def create_school_partnership(year:, school:, lead_provider:)
    FactoryBot.create(
      :school_partnership,
      :for_year,
      year:,
      school:,
      lead_provider:
    )
  end

  def create_active_lead_provider(contract_period:, lead_provider:)
    FactoryBot.create(
      :active_lead_provider,
      contract_period:,
      lead_provider:
    )
  end

  def build_previous_training_period_double(provider_led:, contract_period:, lead_provider: nil)
    instance_double(
      TrainingPeriod,
      provider_led_training_programme?: provider_led,
      contract_period:,
      expression_of_interest_contract_period: nil,
      lead_provider:
    )
  end

  describe "#ect_at_school_period" do
    context "when the stored ect_at_school_period_id is present" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period) }
      let(:ect_at_school_period_id) { ect_at_school_period.id }

      it "returns the matching ECT at school period" do
        expect(queries.ect_at_school_period).to eq(ect_at_school_period)
      end
    end

    context "when the stored ect_at_school_period_id is blank" do
      it "returns nil" do
        expect(queries.ect_at_school_period).to be_nil
      end
    end
  end

  describe "#active_record_at_school" do
    let(:school) { FactoryBot.create(:school) }
    let!(:ongoing_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:) }

    it "returns the ongoing period for the given urn" do
      expect(queries.active_record_at_school(school.urn)).to eq(ongoing_period)
    end
  end

  describe "#contract_start_date" do
    context "when the start_date is present" do
      let(:contract_period) { create_contract_period(year: 2024) }
      let(:start_date) { (contract_period.started_on + 1.day).to_s }

      it "returns the contract period containing the date" do
        expect(queries.contract_start_date).to eq(contract_period)
      end
    end

    context "when the start_date is blank" do
      it "returns nil" do
        expect(queries.contract_start_date).to be_nil
      end
    end
  end

  describe "#registration_contract_period" do
    context "when the start_date is blank" do
      it "returns nil" do
        expect(queries.registration_contract_period).to be_nil
      end
    end

    context "when the start_date is present" do
      let!(:contract_period) { create_contract_period(year: 2025) }
      let(:start_date) { contract_period.finished_on.to_s }

      it "returns the normal registration contract period" do
        expect(queries.registration_contract_period).to eq(contract_period)
      end
    end

    context "when the previous training period is provider-led in closed 2021" do
      let!(:contract_period_2021) { create_contract_period(year: 2021, payments_frozen: true) }
      let!(:contract_period_2024) { create_contract_period(year: 2024, payments_frozen: true) }
      let!(:contract_period_2025) { create_contract_period(year: 2025) }

      let(:start_date) { contract_period_2025.started_on.to_s }

      let(:previous_training_period) do
        build_previous_training_period_double(
          provider_led: true,
          contract_period: contract_period_2021
        )
      end

      before { stub_previous_training(previous_training_period, previous_ect_period:) }

      it "returns the 2024 contract period" do
        expect(queries.registration_contract_period).to eq(contract_period_2024)
      end
    end

    context "when the previous training period is provider-led in a non-frozen contract period" do
      let!(:contract_period_2021) { create_contract_period(year: 2021) }
      let!(:contract_period_2025) { create_contract_period(year: 2025) }

      let(:start_date) { contract_period_2025.started_on.to_s }

      let(:previous_training_period) do
        build_previous_training_period_double(
          provider_led: true,
          contract_period: contract_period_2021
        )
      end

      before { stub_previous_training(previous_training_period, previous_ect_period:) }

      it "returns the normal registration contract period" do
        expect(queries.registration_contract_period).to eq(contract_period_2025)
      end
    end

    context "when the previous training period is school-led in a frozen contract period" do
      let!(:contract_period_2021) { create_contract_period(year: 2021, payments_frozen: true) }
      let!(:contract_period_2025) { create_contract_period(year: 2025) }

      let(:start_date) { contract_period_2025.started_on.to_s }

      let(:previous_training_period) do
        build_previous_training_period_double(
          provider_led: false,
          contract_period: contract_period_2021
        )
      end

      before { stub_previous_training(previous_training_period, previous_ect_period:) }

      it "returns the normal registration contract period" do
        expect(queries.registration_contract_period).to eq(contract_period_2025)
      end
    end

    context "when there is no previous training period" do
      let!(:contract_period_2025) { create_contract_period(year: 2025) }
      let(:start_date) { contract_period_2025.started_on.to_s }

      before do
        allow(ECTAtSchoolPeriods::Search).to receive(:new)
          .with(order: :started_on)
          .and_return(instance_double(ECTAtSchoolPeriods::Search, ect_periods: []))
      end

      it "returns the normal registration contract period" do
        expect(queries.registration_contract_period).to eq(contract_period_2025)
      end
    end
  end

  describe "#lead_providers_within_contract_period" do
    context "when there is no contract period" do
      it "returns an empty array without hitting the database" do
        expect(LeadProviders::Active).not_to receive(:in_contract_period)

        expect(queries.lead_providers_within_contract_period).to eq([])
      end
    end

    context "when a contract period is present" do
      let(:contract_period) { create_contract_period(year: 2025) }
      let(:start_date) { (contract_period.started_on + 2.days).to_s }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:another_lead_provider) { FactoryBot.create(:lead_provider) }

      before do
        create_active_lead_provider(contract_period:, lead_provider:)
        create_active_lead_provider(contract_period:, lead_provider: another_lead_provider)
      end

      it "returns the active lead providers for the contract period" do
        ids = queries.lead_providers_within_contract_period.map(&:id)

        expect(ids).to contain_exactly(lead_provider.id, another_lead_provider.id)
      end
    end

    context "when the previous training period is provider-led in payments frozen contract period (2021)" do
      let!(:contract_period_2021) { create_contract_period(year: 2021, payments_frozen: true) }
      let!(:contract_period_2024) { create_contract_period(year: 2024) }
      let!(:contract_period_2025) { create_contract_period(year: 2025) }

      let(:start_date) { contract_period_2025.started_on.to_s }

      let!(:lead_provider_2024) { FactoryBot.create(:lead_provider, name: "LP 2024") }
      let!(:lead_provider_2025) { FactoryBot.create(:lead_provider, name: "LP 2025") }

      let(:previous_training_period) do
        build_previous_training_period_double(
          provider_led: true,
          contract_period: contract_period_2021
        )
      end

      before do
        create_active_lead_provider(contract_period: contract_period_2024, lead_provider: lead_provider_2024)
        create_active_lead_provider(contract_period: contract_period_2025, lead_provider: lead_provider_2025)
        stub_previous_training(previous_training_period, previous_ect_period:)
      end

      it "returns lead providers for the 2024 contract period" do
        names = queries.lead_providers_within_contract_period.map(&:name)

        expect(names).to include("LP 2024")
        expect(names).not_to include("LP 2025")
      end
    end

    context "when the previous training period is provider-led in payments frozen contract period (2022)" do
      let!(:contract_period_2022) { create_contract_period(year: 2022, payments_frozen: true) }
      let!(:contract_period_2024) { create_contract_period(year: 2024) }
      let!(:contract_period_2025) { create_contract_period(year: 2025) }

      let(:start_date) { contract_period_2025.started_on.to_s }

      let!(:lead_provider_2024) { FactoryBot.create(:lead_provider, name: "LP 2024") }
      let!(:lead_provider_2025) { FactoryBot.create(:lead_provider, name: "LP 2025") }

      let(:previous_training_period) do
        build_previous_training_period_double(
          provider_led: true,
          contract_period: contract_period_2022
        )
      end

      before do
        create_active_lead_provider(contract_period: contract_period_2024, lead_provider: lead_provider_2024)
        create_active_lead_provider(contract_period: contract_period_2025, lead_provider: lead_provider_2025)
        stub_previous_training(previous_training_period, previous_ect_period:)
      end

      it "returns lead providers for the 2024 contract period" do
        expect(queries.lead_providers_within_contract_period.map(&:name)).to contain_exactly("LP 2024")
      end
    end

    context "when the previous training period is provider-led in a non-frozen contract period" do
      let!(:contract_period_2021) { create_contract_period(year: 2021) }
      let!(:contract_period_2025) { create_contract_period(year: 2025) }

      let(:start_date) { contract_period_2025.started_on.to_s }
      let!(:lead_provider_2025) { FactoryBot.create(:lead_provider, name: "LP 2025") }

      let(:previous_training_period) do
        build_previous_training_period_double(
          provider_led: true,
          contract_period: contract_period_2021
        )
      end

      before do
        create_active_lead_provider(contract_period: contract_period_2025, lead_provider: lead_provider_2025)
        stub_previous_training(previous_training_period, previous_ect_period:)
      end

      it "returns lead providers for the normal contract period" do
        expect(queries.lead_providers_within_contract_period.map(&:name)).to contain_exactly("LP 2025")
      end
    end

    context "when the previous training period is school-led in a frozen contract period" do
      let!(:contract_period_2021) { create_contract_period(year: 2021, payments_frozen: true) }
      let!(:contract_period_2025) { create_contract_period(year: 2025) }

      let(:start_date) { contract_period_2025.started_on.to_s }
      let!(:lead_provider_2025) { FactoryBot.create(:lead_provider, name: "LP 2025") }

      let(:previous_training_period) do
        build_previous_training_period_double(
          provider_led: false,
          contract_period: contract_period_2021
        )
      end

      before do
        create_active_lead_provider(contract_period: contract_period_2025, lead_provider: lead_provider_2025)
        stub_previous_training(previous_training_period, previous_ect_period:)
      end

      it "returns lead providers for the normal contract period" do
        expect(queries.lead_providers_within_contract_period.map(&:name)).to contain_exactly("LP 2025")
      end
    end
  end

  describe "#lead_provider_partnerships_for_contract_period" do
    let(:contract_period) { create_contract_period(year: 2026) }
    let(:start_date) { (contract_period.started_on + 1.day).to_s }
    let(:school) { FactoryBot.create(:school) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:school_partnership) { create_school_partnership(year: contract_period.year, school:, lead_provider:) }

    let(:ect_at_school_period) do
      FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        school:
      )
    end

    let!(:training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        ect_at_school_period:,
        school_partnership:
      )
    end

    it "returns partnerships scoped by previous lead provider, contract period and school" do
      expect(queries.lead_provider_partnerships_for_contract_period(school:)).to include(school_partnership)
    end

    it "returns an empty scope when prerequisites are missing" do
      expect(queries.lead_provider_partnerships_for_contract_period(school: nil)).to be_empty
    end

    context "when the previous training period is provider-led in payments frozen contract period (2021)" do
      let!(:contract_period_2021) { create_contract_period(year: 2021, payments_frozen: true) }

      let(:start_date) { Date.new(2025, 9, 1).to_s }
      let(:school) { FactoryBot.create(:school) }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:other_lead_provider) { FactoryBot.create(:lead_provider) }

      let(:previous_training_period) do
        build_previous_training_period_double(
          provider_led: true,
          contract_period: contract_period_2021,
          lead_provider:
        )
      end

      let!(:school_partnership_2024) { create_school_partnership(year: 2024, school:, lead_provider:) }
      let!(:school_partnership_2025) { create_school_partnership(year: 2025, school:, lead_provider:) }
      let!(:other_school_partnership_2024) { create_school_partnership(year: 2024, school:, lead_provider: other_lead_provider) }

      before do
        registration_store.lead_provider_id = lead_provider.id
        stub_previous_training(previous_training_period, previous_ect_period:)
      end

      it "returns partnerships for the reassigned 2024 contract period" do
        expect(queries.lead_provider_partnerships_for_contract_period(school:))
          .to contain_exactly(school_partnership_2024)
      end
    end

    context "when the previous training period is provider-led in payments frozen contract period (2022)" do
      let!(:contract_period_2022) { create_contract_period(year: 2022, payments_frozen: true) }

      let(:start_date) { Date.new(2025, 9, 1).to_s }
      let(:school) { FactoryBot.create(:school) }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:other_lead_provider) { FactoryBot.create(:lead_provider) }

      let(:previous_training_period) do
        build_previous_training_period_double(
          provider_led: true,
          contract_period: contract_period_2022,
          lead_provider:
        )
      end

      let!(:school_partnership_2024) { create_school_partnership(year: 2024, school:, lead_provider:) }
      let!(:school_partnership_2025) { create_school_partnership(year: 2025, school:, lead_provider:) }
      let!(:other_school_partnership_2024) { create_school_partnership(year: 2024, school:, lead_provider: other_lead_provider) }

      before do
        registration_store.lead_provider_id = lead_provider.id
        stub_previous_training(previous_training_period, previous_ect_period:)
      end

      it "returns partnerships for the reassigned 2024 contract period" do
        expect(queries.lead_provider_partnerships_for_contract_period(school:))
          .to contain_exactly(school_partnership_2024)
      end
    end

    context "when the previous training period is provider-led in a non-frozen contract period" do
      let!(:contract_period_2021) { create_contract_period(year: 2021) }

      let(:start_date) { Date.new(2025, 9, 1).to_s }
      let(:school) { FactoryBot.create(:school) }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:other_lead_provider) { FactoryBot.create(:lead_provider) }

      let(:previous_training_period) do
        build_previous_training_period_double(
          provider_led: true,
          contract_period: contract_period_2021,
          lead_provider:
        )
      end

      let!(:school_partnership_2024) { create_school_partnership(year: 2024, school:, lead_provider:) }
      let!(:school_partnership_2025) { create_school_partnership(year: 2025, school:, lead_provider:) }
      let!(:other_school_partnership_2025) { create_school_partnership(year: 2025, school:, lead_provider: other_lead_provider) }

      before do
        registration_store.lead_provider_id = lead_provider.id
        stub_previous_training(previous_training_period, previous_ect_period:)
      end

      it "returns partnerships for the normal contract period" do
        expect(queries.lead_provider_partnerships_for_contract_period(school:))
          .to contain_exactly(school_partnership_2025)
      end
    end

    context "when the previous training period is school-led in a frozen contract period" do
      let!(:contract_period_2021) { create_contract_period(year: 2021, payments_frozen: true) }

      let(:start_date) { Date.new(2025, 9, 1).to_s }
      let(:school) { FactoryBot.create(:school) }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:other_lead_provider) { FactoryBot.create(:lead_provider) }

      let(:previous_training_period) do
        build_previous_training_period_double(
          provider_led: false,
          contract_period: contract_period_2021,
          lead_provider:
        )
      end

      let!(:school_partnership_2024) { create_school_partnership(year: 2024, school:, lead_provider:) }
      let!(:school_partnership_2025) { create_school_partnership(year: 2025, school:, lead_provider:) }
      let!(:other_school_partnership_2025) { create_school_partnership(year: 2025, school:, lead_provider: other_lead_provider) }

      before do
        registration_store.lead_provider_id = lead_provider.id
        stub_previous_training(previous_training_period, previous_ect_period:)
      end

      it "returns partnerships for the normal contract period" do
        expect(queries.lead_provider_partnerships_for_contract_period(school:))
          .to contain_exactly(school_partnership_2025)
      end
    end
  end

  describe "#confirmed_delivery_partner_for_contract_period" do
    let(:contract_period) { FactoryBot.create(:contract_period, year: 2026) }
    let(:start_date) { (contract_period.started_on + 1.day) }
    let(:school) { FactoryBot.create(:school) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:school_partnership) do
      FactoryBot.create(:school_partnership,
                        :for_year,
                        year: contract_period.year,
                        school:,
                        lead_provider:)
    end
    let(:ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period,
                        teacher:,
                        school:)
    end
    let!(:training_period) do
      FactoryBot.create(:training_period,
                        :for_ect,
                        ect_at_school_period:,
                        school_partnership:)
    end

    it "returns the delivery partner from the confirmed partnership" do
      expected = school_partnership.delivery_partner
      expect(queries.confirmed_delivery_partner_for_contract_period(school:)).to eq(expected)
    end

    it "returns nil when there is no confirmed partnership for the school" do
      other_school = FactoryBot.create(:school)
      expect(queries.confirmed_delivery_partner_for_contract_period(school: other_school)).to be_nil
    end
  end

  describe "previous registration queries" do
    let!(:previous_ect_period) do
      FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        started_on: 2.years.ago,
        finished_on: 1.year.ago
      )
    end

    let!(:training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        ect_at_school_period: previous_ect_period,
        started_on: previous_ect_period.started_on,
        finished_on: previous_ect_period.finished_on
      )
    end

    let(:previous_delivery_partner) { training_period.school_partnership.lead_provider_delivery_partnership.delivery_partner }
    let(:previous_lead_provider) { training_period.school_partnership.lead_provider_delivery_partnership.lead_provider }
    let(:previous_school) { previous_ect_period.school }
    let(:previous_appropriate_body) { FactoryBot.create(:appropriate_body_period) }

    before do
      FactoryBot.create(
        :induction_period,
        teacher:,
        appropriate_body_period: previous_appropriate_body,
        started_on: previous_ect_period.started_on,
        finished_on: previous_ect_period.finished_on
      )
    end

    it "returns the previous ect at school period" do
      expect(queries.previous_ect_at_school_period).to eq(previous_ect_period)
    end

    it "returns the previous training period" do
      expect(queries.previous_training_period).to eq(training_period)
    end

    it "returns the previous appropriate body" do
      expect(queries.previous_appropriate_body).to eq(previous_appropriate_body)
    end

    it "returns the previous delivery partner" do
      expect(queries.previous_delivery_partner).to eq(previous_delivery_partner)
    end

    it "returns the previous lead provider" do
      expect(queries.previous_lead_provider).to eq(previous_lead_provider)
    end

    it "returns the previous school" do
      expect(queries.previous_school).to eq(previous_school)
    end
  end

  context "when the current ect_at_school_period_id is present" do
    let!(:historical_ect_period) do
      FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        started_on: Date.new(2021, 9, 1),
        finished_on: Date.new(2022, 7, 31)
      )
    end

    let!(:historical_training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        ect_at_school_period: historical_ect_period,
        started_on: historical_ect_period.started_on,
        finished_on: historical_ect_period.finished_on
      )
    end

    let!(:current_ect_period) do
      FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        started_on: Date.new(2025, 9, 1),
        finished_on: nil
      )
    end

    let!(:current_training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        ect_at_school_period: current_ect_period,
        started_on: current_ect_period.started_on,
        finished_on: nil
      )
    end

    let(:ect_at_school_period_id) { current_ect_period.id }

    it "returns the historical ect period rather than the current ect period" do
      expect(queries.previous_ect_at_school_period).to eq(historical_ect_period)
      expect(queries.previous_ect_at_school_period).not_to eq(current_ect_period)
    end

    it "returns the historical training period" do
      expect(queries.previous_training_period).to eq(historical_training_period)
    end
  end

  context "when the current ect_at_school_period_id is present and the historical training period is provider-led in closed 2021" do
    let!(:contract_period_2021) { create_contract_period(year: 2021, payments_frozen: true) }
    let!(:contract_period_2024) { create_contract_period(year: 2024, payments_frozen: true) }
    let!(:contract_period_2025) { create_contract_period(year: 2025) }

    let(:start_date) { contract_period_2025.started_on.to_s }
    let!(:gias_school) { FactoryBot.create(:gias_school, urn: 9_001_001) }
    let!(:historical_school) do
      School.create!(
        urn: gias_school.urn,
        induction_tutor_name: "Test Tutor",
        induction_tutor_email: "test@example.com"
      )
    end
    let!(:historical_ect_period) do
      FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        school: historical_school,
        started_on: Date.new(2021, 9, 1),
        finished_on: Date.new(2022, 7, 31)
      )
    end

    let!(:lead_provider) { FactoryBot.create(:lead_provider) }
    let!(:school_partnership_2021) { create_school_partnership(year: 2021, school: historical_school, lead_provider:) }

    let!(:historical_training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        :provider_led,
        ect_at_school_period: historical_ect_period,
        started_on: historical_ect_period.started_on,
        finished_on: historical_ect_period.finished_on,
        school_partnership: school_partnership_2021
      )
    end

    let!(:current_ect_period) do
      FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        school: historical_school,
        started_on: Date.new(2025, 9, 1),
        finished_on: nil
      )
    end

    let!(:current_training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        :provider_led,
        ect_at_school_period: current_ect_period,
        started_on: current_ect_period.started_on,
        finished_on: nil
      )
    end

    let(:ect_at_school_period_id) { current_ect_period.id }

    it "resolves the registration contract period using the historical ect period" do
      expect(queries.previous_ect_at_school_period).to eq(historical_ect_period)
      expect(queries.previous_training_period).to eq(historical_training_period)
      expect(queries.registration_contract_period).to eq(contract_period_2024)
    end
  end
end
