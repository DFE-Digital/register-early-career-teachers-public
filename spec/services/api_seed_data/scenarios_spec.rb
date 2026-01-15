RSpec.describe APISeedData::Scenarios do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  let(:contract_period_2024) { FactoryBot.create(:contract_period, year: 2024) }
  let(:contract_period_2025) { FactoryBot.create(:contract_period, year: 2025) }

  let(:lead_provider_count) { LeadProvider.count }
  let(:active_lead_provider_count) { ActiveLeadProvider.count }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }

    # Create lead providers with active lead providers for both contract periods
    FactoryBot.create_list(:lead_provider, 2).each do |lead_provider|
      FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: contract_period_2024)
      FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: contract_period_2025)
    end

    # Create delivery partners
    FactoryBot.create_list(:delivery_partner, 5)
  end

  describe "#plant" do
    it "does not create data when already present" do
      expect { instance.plant }.to change(School, :count)
      expect { instance.plant }.not_to change(School, :count)
    end

    it "logs the creation of scenarios" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)
      expect(logger).to have_received(:info).with(/Planting api teachers seed scenarios/).once
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any schools" do
        expect { instance.plant }.not_to change(School, :count)
      end
    end
  end

  describe "schools_with_participants_with_lead_provider_as_expression_of_interest" do
    before { instance.plant_only(:schools_with_participants_with_lead_provider_as_expression_of_interest, count: 2) }

    let(:schools_with_ect_eoi) do
      School
        .joins(ect_at_school_periods: :training_periods)
        .where(training_periods: { school_partnership_id: nil })
        .where.not(training_periods: { expression_of_interest_id: nil })
    end

    let(:schools_with_mentor_eoi) do
      School
        .joins(mentor_at_school_periods: :training_periods)
        .where(training_periods: { school_partnership_id: nil })
        .where.not(training_periods: { expression_of_interest_id: nil })
    end

    let(:schools_with_eoi) do
      School.where(id: schools_with_ect_eoi.select(:id))
            .or(School.where(id: schools_with_mentor_eoi.select(:id)))
            .distinct
    end

    it "creates schools with participants linked via expression of interest" do
      expect(schools_with_eoi.count).to eq(2 * active_lead_provider_count)
    end
  end

  describe "schools_with_participants_that_rolled_over_from_2024_to_2025_with_lead_provider" do
    before { instance.plant_only(:schools_with_participants_that_rolled_over_from_2024_to_2025_with_lead_provider, count: 2) }

    it "creates schools with participants that rolled over from 2024 to 2025" do
      LeadProvider.find_each do |lead_provider|
        teachers_with_2024 = Teacher
          .joins(ect_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
          .where(schedules: { contract_period_year: 2024 })
          .where(active_lead_providers: { lead_provider_id: lead_provider.id })
          .select(:id)

        teachers_with_2025 = Teacher
          .joins(ect_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
          .where(schedules: { contract_period_year: 2025 })
          .where(active_lead_providers: { lead_provider_id: lead_provider.id })
          .select(:id)

        schools_with_rolled_over_participants = School
          .joins(ect_at_school_periods: :teacher)
          .where(teachers: { id: teachers_with_2024 })
          .where(teachers: { id: teachers_with_2025 })
          .distinct

        expect(schools_with_rolled_over_participants.count).to eq(2)
      end
    end
  end

  describe "schools_with_participants_with_lead_provider_where_all_transferred_to_another_lead_provider" do
    before { instance.plant_only(:schools_with_participants_with_lead_provider_where_all_transferred_to_another_lead_provider, count: 2) }

    let(:ect_periods_with_school_partnership) do
      ECTAtSchoolPeriod.joins(:training_periods).where.not(training_periods: { school_partnership_id: nil })
    end

    it "creates schools with ECTs that have training with multiple lead providers" do
      expect(ect_periods_with_school_partnership.count).to eq(2 * lead_provider_count)
    end
  end

  describe "schools_without_participants_and_with_partnership" do
    before { instance.plant_only(:schools_without_participants_and_with_partnership, count: 2) }

    let(:schools_with_partnership_no_participants) do
      School
        .left_joins(:ect_at_school_periods, :mentor_at_school_periods)
        .joins(:school_partnerships)
        .where(ect_at_school_periods: { id: nil }, mentor_at_school_periods: { id: nil })
        .distinct
    end

    it "creates schools with partnerships but no participants" do
      expect(schools_with_partnership_no_participants.count).to eq(2 * active_lead_provider_count)
    end
  end

  describe "schools_without_participants_and_without_partnership" do
    before { instance.plant_only(:schools_without_participants_and_without_partnership, count: 2) }

    let(:schools_without_participants_or_partnership) do
      School
        .left_joins(:ect_at_school_periods, :mentor_at_school_periods, :school_partnerships)
        .where(ect_at_school_periods: { id: nil }, mentor_at_school_periods: { id: nil }, school_partnerships: { id: nil })
        .distinct
    end

    it "creates schools with no participants and no partnerships" do
      expect(schools_without_participants_or_partnership.count).to eq(2)
    end
  end

  describe "schools_with_participants_with_lead_provider_with_eoi_and_partnership_in_2024" do
    before { instance.plant_only(:schools_with_participants_with_lead_provider_with_eoi_and_partnership_in_2024, count: 2) }

    let(:schools_with_eoi_and_partnership_2024) do
      School
        .joins(ect_at_school_periods: { training_periods: :schedule })
        .where(schedules: { contract_period_year: 2024 })
        .where.not(training_periods: { expression_of_interest_id: nil, school_partnership_id: nil })
        .distinct
    end

    it "creates schools with EOI and partnership in 2024" do
      expect(schools_with_eoi_and_partnership_2024.count).to eq(2 * lead_provider_count)
    end
  end

  describe "schools_with_school_led_participants_only" do
    before { instance.plant_only(:schools_with_school_led_participants_only, count: 2) }

    let(:schools_with_school_led) do
      School
        .joins(ect_at_school_periods: :training_periods)
        .where(training_periods: { training_programme: "school_led" })
        .distinct
    end

    it "creates schools with school-led participants only" do
      expect(schools_with_school_led.count).to eq(2)
    end
  end

  describe "schools_with_provider_led_participants" do
    before { instance.plant_only(:schools_with_provider_led_participants, count: 2) }

    let(:schools_with_ect_provider_led) do
      School
        .joins(ect_at_school_periods: :training_periods)
        .where(training_periods: { training_programme: "provider_led" })
    end

    let(:schools_with_mentor_provider_led) do
      School
        .joins(mentor_at_school_periods: :training_periods)
        .where(training_periods: { training_programme: "provider_led" })
    end

    let(:schools_with_provider_led) do
      School.where(id: schools_with_ect_provider_led.select(:id))
            .or(School.where(id: schools_with_mentor_provider_led.select(:id)))
            .distinct
    end

    it "creates schools with provider-led participants" do
      expect(schools_with_provider_led.count).to eq(2)
    end
  end

  describe "schools_with_participants_trained_2025_and_finished_with_lead_provider_where_all_transferred_to_another_lead_provider" do
    before { instance.plant_only(:schools_with_participants_trained_2025_and_finished_with_lead_provider_where_all_transferred_to_another_lead_provider, count: 2) }

    let(:schools_with_finished_2025_training) do
      School
        .joins(ect_at_school_periods: { training_periods: :schedule })
        .where(schedules: { contract_period_year: 2025 })
        .where.not(training_periods: { finished_on: nil })
        .distinct
    end

    it "creates schools with finished 2025 training transferred to another lead provider" do
      expect(schools_with_finished_2025_training.count).to eq(2 * lead_provider_count)
    end
  end

  describe "schools_with_ects_and_mentors_training_with_lead_provider" do
    before { instance.plant_only(:schools_with_ects_and_mentors_training_with_lead_provider, count: 2) }

    let(:schools_with_both_ect_and_mentor) do
      School
        .joins(:ect_at_school_periods, :mentor_at_school_periods)
        .distinct
    end

    it "creates schools with both ECT and mentor training" do
      expect(schools_with_both_ect_and_mentor.count).to eq(2 * lead_provider_count)
    end
  end

  describe "schools_with_multiple_partnerships_with_lead_provider" do
    before { instance.plant_only(:schools_with_multiple_partnerships_with_lead_provider, count: 2) }

    let(:schools_with_multiple_partnerships) do
      School
        .joins(:school_partnerships)
        .group(:id)
        .having("COUNT(school_partnerships.id) > 1")
    end

    it "creates schools with multiple partnerships" do
      expect(schools_with_multiple_partnerships.count.size).to eq(2 * active_lead_provider_count)
    end
  end

  describe "schools_with_multiple_partnerships_with_lead_provider_and_with_another_lead_provider" do
    before { instance.plant_only(:schools_with_multiple_partnerships_with_lead_provider_and_with_another_lead_provider, count: 2) }

    let(:schools_with_multiple_lp_partnerships) do
      School
        .joins(school_partnerships: { lead_provider_delivery_partnership: :active_lead_provider })
        .group("schools.id")
        .having("COUNT(DISTINCT active_lead_providers.lead_provider_id) > 1")
    end

    it "creates schools with partnerships from multiple lead providers" do
      expect(schools_with_multiple_lp_partnerships.count.size).to eq(2 * active_lead_provider_count)
    end
  end
end
