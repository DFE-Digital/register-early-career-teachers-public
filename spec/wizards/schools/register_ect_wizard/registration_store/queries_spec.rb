RSpec.describe Schools::RegisterECTWizard::RegistrationStore::Queries do
  subject(:queries) { described_class.new(registration_store:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:trn) { teacher.trn }

  let(:registration_store) do
    Struct.new(:trn, :appropriate_body_id, :lead_provider_id, :start_date, :ect_at_school_period_id, :normalized_start_date)
      .new(
        trn,
        appropriate_body_id,
        lead_provider_id,
        start_date,
        ect_at_school_period_id,
        start_date&.to_date
      )
  end

  let(:appropriate_body_id) { nil }
  let(:lead_provider_id) { nil }
  let(:start_date) { nil }
  let(:ect_at_school_period_id) { nil }

  def create_previous_school_led_training(started_on:, finished_on:)
    ect_period = FactoryBot.create(:ect_at_school_period, teacher:, started_on:, finished_on:)

    FactoryBot.create(:training_period, :school_led, ect_at_school_period: ect_period, started_on:, finished_on:)
  end

  def create_previous_provider_led_training(
    contract_period,
    framework_agreement: FactoryBot.create(:framework_agreement, contract_period:)
  )
    ect_period = FactoryBot.create(
      :ect_at_school_period,
      teacher:,
      started_on: contract_period.started_on,
      finished_on: contract_period.finished_on
    )

    FactoryBot.create(
      :training_period,
      :with_framework_agreement,
      ect_at_school_period: ect_period,
      framework_agreement:,
      started_on: ect_period.started_on,
      finished_on: ect_period.finished_on
    )
  end

  def create_contract_period(year:, payments_frozen: false)
    traits = []
    traits << :with_payments_frozen if payments_frozen

    FactoryBot.create(
      :contract_period,
      *traits,
      year:
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

  def create_framework_agreement(contract_period:, lead_provider:)
    FactoryBot.create(
      :framework_agreement,
      contract_period:,
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
    let!(:ongoing_period) { FactoryBot.create(:ect_at_school_period, :unfinished, teacher:, school:) }

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

  describe "#previous_provider_led_training_period" do
    context "when provider-led training starts after the reported school start date" do
      let!(:previous_contract_period) do
        create_contract_period(year: 2024)
      end

      let!(:registration_contract_period) do
        create_contract_period(year: 2026)
      end

      let(:start_date) { Date.new(2026, 9, 10).to_s }

      let!(:later_ect_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          started_on: Date.new(2026, 9, 11),
          finished_on: nil
        )
      end

      let!(:later_training_period) do
        FactoryBot.create(
          :training_period,
          :with_framework_agreement,
          ect_at_school_period: later_ect_period,
          framework_agreement: FactoryBot.create(
            :framework_agreement,
            contract_period: previous_contract_period
          ),
          started_on: later_ect_period.started_on,
          finished_on: nil
        )
      end

      it "excludes that period and uses the contract year for the reported school start date" do
        expect(queries.previous_provider_led_training_period).to be_nil
        expect(queries.registration_contract_period)
          .to eq(registration_contract_period)
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
      let!(:contract_period) { create_contract_period(year: Date.current.year) }
      let(:start_date) { contract_period.finished_on.to_s }

      it "returns the normal registration contract period" do
        expect(queries.registration_contract_period).to eq(contract_period)
      end
    end

    context "when the previous training period is provider-led in closed 2021" do
      let!(:contract_period_2021) { create_contract_period(year: 2021, payments_frozen: true) }
      let!(:contract_period_2024) { create_contract_period(year: 2024, payments_frozen: true) }
      let!(:contract_period) { create_contract_period(year: Date.current.year) }

      let(:start_date) { contract_period.started_on.to_s }

      before { create_previous_provider_led_training(contract_period_2021) }

      it "returns the 2024 contract period" do
        expect(queries.registration_contract_period).to eq(contract_period_2024)
      end
    end

    context "when the previous training period is provider-led in a non-frozen contract period" do
      let!(:contract_period_2023) { create_contract_period(year: 2023) }
      let!(:contract_period) { create_contract_period(year: Date.current.year) }

      let(:start_date) { contract_period.started_on.to_s }

      before { create_previous_provider_led_training(contract_period_2023) }

      it "returns the previous training period's contract period" do
        expect(queries.registration_contract_period).to eq(contract_period_2023)
      end
    end

    context "when the previous training period is school-led in a frozen contract period" do
      let!(:contract_period_2021) { create_contract_period(year: 2021, payments_frozen: true) }
      let!(:contract_period) { create_contract_period(year: Date.current.year) }

      let(:start_date) { contract_period.started_on.to_s }

      before do
        create_previous_school_led_training(
          started_on: contract_period_2021.started_on,
          finished_on: contract_period_2021.finished_on
        )
      end

      it "returns the normal registration contract period" do
        expect(queries.registration_contract_period).to eq(contract_period)
      end
    end

    context "when there is no previous training period" do
      let!(:contract_period) { create_contract_period(year: Date.current.year) }
      let(:start_date) { contract_period.started_on.to_s }

      before do
        allow(ECTAtSchoolPeriods::Search).to receive(:new)
          .with(order: :started_on)
          .and_return(instance_double(ECTAtSchoolPeriods::Search, ect_periods: []))
      end

      it "returns the normal registration contract period" do
        expect(queries.registration_contract_period).to eq(contract_period)
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
      let(:contract_period) { create_contract_period(year: Date.current.year) }
      let(:start_date) { (contract_period.started_on + 2.days).to_s }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:another_lead_provider) { FactoryBot.create(:lead_provider) }

      before do
        create_framework_agreement(contract_period:, lead_provider:)
        create_framework_agreement(contract_period:, lead_provider: another_lead_provider)
      end

      it "returns the framework agreements for the contract period" do
        ids = queries.lead_providers_within_contract_period.map(&:id)

        expect(ids).to contain_exactly(lead_provider.id, another_lead_provider.id)
      end
    end

    context "when the previous training period is provider-led in payments frozen contract period (2021)" do
      let!(:contract_period_2021) { create_contract_period(year: 2021, payments_frozen: true) }
      let!(:contract_period_2024) { create_contract_period(year: 2024) }
      let!(:contract_period) { create_contract_period(year: Date.current.year) }

      let(:start_date) { contract_period.started_on.to_s }

      let!(:lead_provider_2024) { FactoryBot.create(:lead_provider, name: "LP 2024") }
      let!(:lead_provider) { FactoryBot.create(:lead_provider, name: "LP #{Date.current.year}") }

      before do
        create_framework_agreement(contract_period: contract_period_2024, lead_provider: lead_provider_2024)
        create_framework_agreement(contract_period:, lead_provider:)
        create_previous_provider_led_training(contract_period_2021)
      end

      it "returns lead providers for the 2024 contract period" do
        names = queries.lead_providers_within_contract_period.map(&:name)

        expect(names).to contain_exactly("LP 2024")
        expect(names).not_to include("LP #{Date.current.year}")
      end
    end

    context "when the previous training period is provider-led in payments frozen contract period (2022)" do
      let!(:contract_period_2022) { create_contract_period(year: 2022, payments_frozen: true) }
      let!(:contract_period_2024) { create_contract_period(year: 2024) }
      let!(:contract_period) { create_contract_period(year: Date.current.year) }

      let(:start_date) { contract_period.started_on.to_s }

      let!(:lead_provider_2024) { FactoryBot.create(:lead_provider, name: "LP 2024") }
      let!(:lead_provider) { FactoryBot.create(:lead_provider, name: "LP #{Date.current.year}") }

      before do
        create_framework_agreement(contract_period: contract_period_2024, lead_provider: lead_provider_2024)
        create_framework_agreement(contract_period:, lead_provider:)
        create_previous_provider_led_training(contract_period_2022)
      end

      it "returns lead providers for the 2024 contract period" do
        expect(queries.lead_providers_within_contract_period.map(&:name)).to contain_exactly("LP 2024")
      end
    end

    context "when the previous training period is provider-led in a non-frozen contract period" do
      let!(:contract_period_2021) { create_contract_period(year: 2021) }
      let!(:contract_period) { create_contract_period(year: Date.current.year) }

      let(:start_date) { contract_period.started_on.to_s }
      let!(:lead_provider_2021) { FactoryBot.create(:lead_provider, name: "LP 2021") }
      let!(:lead_provider) { FactoryBot.create(:lead_provider, name: "LP #{Date.current.year}") }

      before do
        agreement = create_framework_agreement(contract_period: contract_period_2021, lead_provider: lead_provider_2021)
        create_framework_agreement(contract_period:, lead_provider:)
        create_previous_provider_led_training(contract_period_2021, framework_agreement: agreement)
      end

      it "returns lead providers for the previous contract period" do
        expect(queries.lead_providers_within_contract_period.map(&:name)).to contain_exactly("LP 2021")
      end
    end

    context "when the previous training period is school-led in a frozen contract period" do
      let!(:contract_period_2021) { create_contract_period(year: 2021, payments_frozen: true) }
      let!(:contract_period) { create_contract_period(year: Date.current.year) }

      let(:start_date) { contract_period.started_on.to_s }
      let!(:lead_provider) { FactoryBot.create(:lead_provider, name: "LP #{Date.current.year}") }

      before do
        create_framework_agreement(contract_period:, lead_provider:)
        create_previous_school_led_training(
          started_on: contract_period_2021.started_on,
          finished_on: contract_period_2021.finished_on
        )
      end

      it "returns lead providers for the normal contract period" do
        expect(queries.lead_providers_within_contract_period.map(&:name)).to contain_exactly("LP #{Date.current.year}")
      end
    end
  end

  describe "#lead_provider_partnerships_for_contract_period" do
    let(:contract_period) { create_contract_period(year: Date.current.year.next) }
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

      let(:ect_at_school_period_id) { ect_at_school_period.id }

      let!(:school_partnership_2024) { create_school_partnership(year: 2024, school:, lead_provider:) }
      let!(:school_partnership) { create_school_partnership(year: Date.current.year, school:, lead_provider:) }
      let!(:other_school_partnership_2024) { create_school_partnership(year: 2024, school:, lead_provider: other_lead_provider) }

      before do
        registration_store.lead_provider_id = lead_provider.id
        agreement = create_framework_agreement(contract_period: contract_period_2021, lead_provider:)
        create_previous_provider_led_training(contract_period_2021, framework_agreement: agreement)
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

      let(:ect_at_school_period_id) { ect_at_school_period.id }

      let!(:school_partnership_2024) { create_school_partnership(year: 2024, school:, lead_provider:) }
      let!(:school_partnership) { create_school_partnership(year: Date.current.year, school:, lead_provider:) }
      let!(:other_school_partnership_2024) { create_school_partnership(year: 2024, school:, lead_provider: other_lead_provider) }

      before do
        registration_store.lead_provider_id = lead_provider.id
        agreement = create_framework_agreement(contract_period: contract_period_2022, lead_provider:)
        create_previous_provider_led_training(contract_period_2022, framework_agreement: agreement)
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

      let(:ect_at_school_period_id) { ect_at_school_period.id }

      let!(:school_partnership_2021) { create_school_partnership(year: 2021, school:, lead_provider:) }
      let!(:school_partnership) { create_school_partnership(year: Date.current.year, school:, lead_provider:) }
      let!(:other_school_partnership) { create_school_partnership(year: Date.current.year.next, school:, lead_provider: other_lead_provider) }

      before do
        registration_store.lead_provider_id = lead_provider.id
        agreement = school_partnership_2021.framework_agreement
        create_previous_provider_led_training(contract_period_2021, framework_agreement: agreement)
      end

      it "returns partnerships for the normal contract period" do
        expect(queries.lead_provider_partnerships_for_contract_period(school:))
          .to contain_exactly(school_partnership_2021)
      end
    end

    context "when the ECT only has school-led training from an earlier frozen year" do
      let!(:contract_period_2021) do
        create_contract_period(year: 2021, payments_frozen: true)
      end

      let(:contract_period) { create_contract_period(year: 2026) }
      let(:start_date) { Date.new(2026, 9, 1).to_s }
      let(:lead_provider_id) { lead_provider.id }

      # Replace the parent fixture with school-led history.
      let!(:training_period) do
        create_previous_school_led_training(
          started_on: contract_period_2021.started_on,
          finished_on: contract_period_2021.finished_on
        )
      end

      let!(:school_partnership) do
        create_school_partnership(
          year: contract_period.year,
          school:,
          lead_provider:
        )
      end

      before do
        create_school_partnership(year: 2024, school:, lead_provider:)

        create_school_partnership(
          year: contract_period.year,
          school:,
          lead_provider: FactoryBot.create(:lead_provider)
        )
      end

      it "returns the selected provider's partnership in the registration year" do
        expect(queries.previous_provider_led_training_period).to be_nil
        expect(queries.registration_contract_period).to eq(contract_period)

        expect(queries.lead_provider_partnerships_for_contract_period(school:))
          .to contain_exactly(school_partnership)
      end
    end
  end

  describe "#lead_provider_partnerships_for_contract_period with a selected provider" do
    let!(:registration_contract_period) { create_contract_period(year: 2026) }
    let(:start_date) { Date.new(2026, 9, 1).to_s }
    let(:school) { FactoryBot.create(:school) }
    let(:selected_provider) { FactoryBot.create(:lead_provider) }
    let(:lead_provider_id) { selected_provider.id }

    context "when the ECT has no previous training" do
      let!(:matching_partnership) do
        create_school_partnership(
          year: registration_contract_period.year,
          school:,
          lead_provider: selected_provider
        )
      end

      before do
        create_school_partnership(
          year: registration_contract_period.year,
          school:,
          lead_provider: FactoryBot.create(:lead_provider)
        )

        create_school_partnership(
          year: registration_contract_period.year,
          school: FactoryBot.create(:school),
          lead_provider: selected_provider
        )
      end

      it "returns the selected provider's partnership at the school in the registration year" do
        expect(queries.previous_provider_led_training_period).to be_nil
        expect(queries.registration_contract_period)
          .to eq(registration_contract_period)

        expect(queries.lead_provider_partnerships_for_contract_period(school:))
          .to contain_exactly(matching_partnership)
      end
    end

    context "when the ECT selects a different provider from their previous training" do
      let!(:previous_contract_period) { create_contract_period(year: 2024) }
      let(:previous_provider) { FactoryBot.create(:lead_provider) }

      let!(:matching_partnership) do
        create_school_partnership(
          year: previous_contract_period.year,
          school:,
          lead_provider: selected_provider
        )
      end

      before do
        previous_agreement = create_framework_agreement(
          contract_period: previous_contract_period,
          lead_provider: previous_provider
        )

        create_previous_provider_led_training(
          previous_contract_period,
          framework_agreement: previous_agreement
        )

        create_school_partnership(
          year: previous_contract_period.year,
          school:,
          lead_provider: previous_provider
        )

        create_school_partnership(
          year: registration_contract_period.year,
          school:,
          lead_provider: selected_provider
        )

        create_school_partnership(
          year: previous_contract_period.year,
          school: FactoryBot.create(:school),
          lead_provider: selected_provider
        )
      end

      it "returns the selected provider's partnership in the preserved contract year" do
        expect(queries.registration_contract_period)
          .to eq(previous_contract_period)

        expect(queries.lead_provider_partnerships_for_contract_period(school:))
          .to contain_exactly(matching_partnership)
      end
    end
  end

  describe "#confirmed_delivery_partner_for_contract_period" do
    let(:contract_period) { FactoryBot.create(:contract_period, year: Date.current.year.next) }
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
    let!(:contract_period) { create_contract_period(year: Date.current.year) }

    let(:start_date) { contract_period.started_on.to_s }
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
