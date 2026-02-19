RSpec.describe APISeedData::ParticipantScenarios do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  let(:contract_period_2024) { FactoryBot.create(:contract_period, year: 2024) }
  let(:contract_period_2025) { FactoryBot.create(:contract_period, year: 2025) }

  before do
    stub_const("#{described_class}::NUMBER_OF_RECORDS_PER_SCENARIO", 1)

    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }

    ignored_logger = instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil)
    allow(Logger).to receive(:new).with($stdout) { ignored_logger }

    # Create support data
    FactoryBot.create_list(:lead_provider, 2).each do |lead_provider|
      FactoryBot.create_list(:lead_provider_delivery_partnership, 5, :for_year, lead_provider:, year: contract_period_2024.year)
      FactoryBot.create_list(:lead_provider_delivery_partnership, 5, :for_year, lead_provider:, year: contract_period_2025.year)
    end
    FactoryBot.create_list(:appropriate_body, 5)
    APISeedData::Contracts.new.plant
    APISeedData::Statements.new.plant
    APISeedData::Schools.new.plant
    APISeedData::SchoolPartnerships.new.plant
    APISeedData::SchedulesAndMilestones.new.plant

    allow(Logger).to receive(:new).with($stdout) { logger }
  end

  describe "#plant" do
    it "does not create data when already present" do
      expect { instance.plant }.to change(Teacher, :count)
      expect { instance.plant }.not_to change(Teacher, :count)
    end

    it "logs the creation of scenarios" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)
      expect(logger).to have_received(:info).with(/Planting api participant seed scenarios/).once
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any schools" do
        expect { instance.plant }.not_to change(School, :count)
      end
    end
  end

  describe "#participants_in_each_contract_period" do
    before { instance.plant_only(:participants_in_each_contract_period, count: 2, contract_period_years: [2024, 2025]) }

    it "creates participants for each contract period and lead provider" do
      LeadProvider.find_each do |lead_provider|
        ContractPeriod.find_each do |contract_period|
          ects_in_period = Teacher
            .joins(ect_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(schedules: { contract_period_year: contract_period.year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct
            .count

          mentors_in_period = Teacher
            .joins(mentor_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(schedules: { contract_period_year: contract_period.year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct
            .count

          # creates 2 participants for each of the 2 contract periods and lead providers
          expect(ects_in_period + mentors_in_period).to eq(2)
        end
      end
    end
  end

  describe "#participants_with_lead_provider_as_expression_of_interest" do
    before do
      instance.plant_only(:participants_with_lead_provider_as_expression_of_interest, count: 3, contract_period_years: [2024, 2025])
    end

    it "creates participants with EOI but no school partnership" do
      LeadProvider.find_each do |lead_provider|
        [2024, 2025].each do |year|
          active_lead_provider_ids = lead_provider.active_lead_providers.where(contract_period: ContractPeriod.find_by(year:)).pluck(:id)

          ects_with_eoi = Teacher
            .joins(ect_at_school_periods: { training_periods: :schedule })
            .where(training_periods: { expression_of_interest_id: active_lead_provider_ids, school_partnership_id: nil })
            .where(schedules: { contract_period_year: year })
            .distinct
            .count

          mentors_with_eoi = Teacher
            .joins(mentor_at_school_periods: { training_periods: :schedule })
            .where(training_periods: { expression_of_interest_id: active_lead_provider_ids, school_partnership_id: nil })
            .where(schedules: { contract_period_year: year })
            .distinct
            .count

          # creates 3 participants for each of the 2 contract periods and lead providers
          expect(ects_with_eoi + mentors_with_eoi).to eq(3)
        end
      end
    end

    it "creates training periods with expression of interest but no school partnership" do
      training_periods = TrainingPeriod.where.not(expression_of_interest_id: nil).where(school_partnership_id: nil)
      expect(training_periods.count).to be > 0
    end
  end

  describe "#ect_participants_with_induction_start_date" do
    before { instance.plant_only(:ect_participants_with_induction_start_date, count: 3, contract_period_years: [2024, 2025]) }

    it "creates ECTs with induction start date" do
      ects_with_induction_start_date = Teacher
        .joins(:induction_periods)
        .distinct
        .count

      # creates 3 ECTs for each of the 2 contract periods and there are 2 lead providers
      expect(ects_with_induction_start_date).to eq(12)
    end
  end

  describe "#ect_participants_without_induction_start_date" do
    before { instance.plant_only(:ect_participants_without_induction_start_date, count: 3, contract_period_years: [2024, 2025]) }

    it "creates ECTs without induction start date" do
      ects_without_start_date = Teacher
        .joins(:ect_at_school_periods)
        .where.missing(:induction_periods)
        .distinct
        .count

      # creates 3 ECTs for each of the 2 contract periods and there are 2 lead providers
      expect(ects_without_start_date).to eq(12)
    end
  end

  describe "#participants_with_declarations" do
    before do
      instance.plant_only(:participants_with_declarations, count: 2, contract_period_years: [2024, 2025])
    end

    it "creates participants with billable declarations for each contract period" do
      billable_statuses = Declaration::BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES

      [2024, 2025].each do |year|
        LeadProvider.find_each do |lead_provider|
          ects_with_billable = Teacher
            .joins(ect_at_school_periods: { training_periods: [:declarations, :schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(declarations: { payment_status: billable_statuses })
            .where(schedules: { contract_period_year: year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct
            .count

          mentors_with_billable = Teacher
            .joins(mentor_at_school_periods: { training_periods: [:declarations, :schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(declarations: { payment_status: billable_statuses })
            .where(schedules: { contract_period_year: year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct
            .count

          # creates 2 participants for each of the 2 contract periods
          expect(ects_with_billable + mentors_with_billable).to eq(4)
        end
      end
    end

    it "creates declarations with various payment statuses" do
      billable_statuses = Declaration::BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES
      declarations = Declaration.where(payment_status: billable_statuses)

      expect(declarations.count).to be > 0
      expect(declarations.pluck(:payment_status).uniq.size).to be > 1
    end

    it "associates payment statements with billable declarations" do
      declarations = Declaration.where(payment_status: %w[eligible payable paid])

      expect(declarations.all? { |d| d.payment_statement.present? }).to be true
    end
  end

  describe "#participants_with_training_status_leaving" do
    before do
      instance.plant_only(:participants_with_training_status_leaving, count: 2, contract_period_years: [2024, 2025])
    end

    it "creates participants with leaving training periods (to be finished in the future) for each contract period and lead provider" do
      [2024, 2025].each do |year|
        LeadProvider.find_each do |lead_provider|
          ects_leaving = Teacher
            .joins(ect_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(training_periods: { finished_on: Time.zone.tomorrow.. })
            .where(schedules: { contract_period_year: year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct

          mentors_leaving = Teacher
            .joins(mentor_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(training_periods: { finished_on: Time.zone.tomorrow.. })
            .where(schedules: { contract_period_year: year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct

          # creates 2 participants for each of the 2 contract periods
          expect(ects_leaving.count + mentors_leaving.count).to eq(4)

          # make sure all created participants have 'leaving' status
          expect((ects_leaving.map(&:ect_training_periods) + mentors_leaving.map(&:mentor_training_periods)).flatten.map { |tp| API::TrainingPeriods::TeacherStatus.new(latest_training_period: tp, teacher: tp.teacher).status }.uniq).to eq(%i[leaving])
        end
      end
    end
  end

  describe "#active_participants_with_participant_status_joining" do
    before do
      instance.plant_only(
        :active_participants_with_participant_status_joining,
        count: 2,
        contract_period_years: [2024, 2025]
      )
    end

    it "creates active participants with joining training periods " \
       "(to be started in the future) for each contract period" do
      [2024, 2025].each do |year|
        LeadProvider.find_each do |lead_provider|
          ects_joining = Teacher
            .joins(ect_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(training_periods: { started_on: Time.zone.tomorrow.. })
            .where(schedules: { contract_period_year: year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct

          mentors_joining = Teacher
            .joins(mentor_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(training_periods: { started_on: Time.zone.tomorrow.. })
            .where(schedules: { contract_period_year: year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct

          # creates 2 participants for ECTs and Mentors
          expect(ects_joining.count).to eq(2)
          expect(mentors_joining.count).to eq(2)

          # make sure all created participants have 'joining' status
          training_periods = (
            ects_joining.map(&:ect_training_periods) +
            mentors_joining.map(&:mentor_training_periods)
          ).flatten
          participant_statuses = training_periods.map do
            API::TrainingPeriods::TeacherStatus.new(
              latest_training_period: it,
              teacher: it.teacher
            )
          end
          training_statuses = training_periods.map do
            API::TrainingPeriods::TrainingStatus.new(training_period: it)
          end
          expect(participant_statuses).to be_all(&:joining?)
          expect(training_statuses).to be_all(&:active?)
        end
      end
    end
  end

  describe "#active_participants_with_participant_status_leaving_in_the_future" do
    before do
      instance.plant_only(
        :active_participants_with_participant_status_leaving_in_the_future,
        count: 2,
        contract_period_years: [2024, 2025]
      )
    end

    it "creates active participants with leaving training periods " \
       "(to be finished at least 4 months in the future) for each contract period" do
      [2024, 2025].each do |year|
        LeadProvider.find_each do |lead_provider|
          ects_leaving = Teacher
            .joins(ect_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(training_periods: { finished_on: 4.months.from_now.. })
            .where(schedules: { contract_period_year: year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct

          mentors_leaving = Teacher
            .joins(mentor_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(training_periods: { finished_on: 4.months.from_now.. })
            .where(schedules: { contract_period_year: year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct

          # creates 2 participants for ECTs and Mentors
          expect(ects_leaving.count).to eq(2)
          expect(mentors_leaving.count).to eq(2)

          # make sure all created participants have 'leaving' status
          training_periods = (
            ects_leaving.map(&:ect_training_periods) +
            mentors_leaving.map(&:mentor_training_periods)
          ).flatten
          participant_statuses = training_periods.map do
            API::TrainingPeriods::TeacherStatus.new(
              latest_training_period: it,
              teacher: it.teacher
            )
          end
          training_statuses = training_periods.map do
            API::TrainingPeriods::TrainingStatus.new(training_period: it)
          end
          expect(participant_statuses).to be_all(&:leaving?)
          expect(training_statuses).to be_all(&:active?)
        end
      end
    end
  end

  describe "#withdrawn_participants_with_participant_status_left" do
    before do
      instance.plant_only(
        :withdrawn_participants_with_participant_status_left,
        count: 2,
        contract_period_years: [2024, 2025]
      )
    end

    it "creates withdrawn participants with finished training periods " \
       "for each contract period" do
      [2024, 2025].each do |year|
        LeadProvider.find_each do |lead_provider|
          withdrawn_ects_left = Teacher
            .joins(ect_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(training_periods: { started_on: ..Date.current, finished_on: ..Date.current })
            .where.not(training_periods: { withdrawn_at: nil })
            .where(schedules: { contract_period_year: year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct

          withdrawn_mentors_left = Teacher
            .joins(mentor_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(training_periods: { started_on: ..Date.current, finished_on: ..Date.current })
            .where.not(training_periods: { withdrawn_at: nil })
            .where(schedules: { contract_period_year: year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct

          # creates 2 participants for ECTs and Mentors
          expect(withdrawn_ects_left.count).to eq(2)
          expect(withdrawn_mentors_left.count).to eq(2)

          # make sure all created participants have 'leaving' status
          training_periods = (
            withdrawn_ects_left.map(&:ect_training_periods) +
            withdrawn_mentors_left.map(&:mentor_training_periods)
          ).flatten
          participant_statuses = training_periods.map do
            API::TrainingPeriods::TeacherStatus.new(
              latest_training_period: it,
              teacher: it.teacher
            )
          end
          training_statuses = training_periods.map do
            API::TrainingPeriods::TrainingStatus.new(training_period: it)
          end
          expect(participant_statuses).to be_all(&:left?)
          expect(training_statuses).to be_all(&:withdrawn?)
        end
      end
    end
  end

  describe "#active_participants_with_participant_status_left" do
    before do
      instance.plant_only(
        :active_participants_with_participant_status_left,
        count: 2,
        contract_period_years: [2024, 2025]
      )
    end

    it "creates active participants with finished training periods " \
       "for each contract period" do
      [2024, 2025].each do |year|
        LeadProvider.find_each do |lead_provider|
          active_ects_left = Teacher
            .joins(ect_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(training_periods: { started_on: ..Date.current, finished_on: ..Date.current })
            .where(training_periods: { withdrawn_at: nil, deferred_at: nil })
            .where(schedules: { contract_period_year: year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct

          active_mentors_left = Teacher
            .joins(mentor_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
            .where(training_periods: { started_on: ..Date.current, finished_on: ..Date.current })
            .where(training_periods: { withdrawn_at: nil, deferred_at: nil })
            .where(schedules: { contract_period_year: year })
            .where(active_lead_providers: { lead_provider_id: lead_provider.id })
            .distinct

          # creates 2 participants for ECTs and Mentors
          expect(active_ects_left.count).to eq(2)
          expect(active_mentors_left.count).to eq(2)

          # make sure all created participants have 'leaving' status
          training_periods = (
            active_ects_left.map(&:ect_training_periods) +
            active_mentors_left.map(&:mentor_training_periods)
          ).flatten
          participant_statuses = training_periods.map do
            API::TrainingPeriods::TeacherStatus.new(
              latest_training_period: it,
              teacher: it.teacher
            )
          end
          training_statuses = training_periods.map do
            API::TrainingPeriods::TrainingStatus.new(training_period: it)
          end
          expect(participant_statuses).to be_all(&:left?)
          expect(training_statuses).to be_all(&:active?)
        end
      end
    end
  end
end
