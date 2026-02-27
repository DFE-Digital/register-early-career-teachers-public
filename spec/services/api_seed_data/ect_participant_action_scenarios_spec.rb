RSpec.describe APISeedData::ECTParticipantActionScenarios do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
  let(:other_contract_period) { FactoryBot.create(:contract_period, year: 2023) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }

  def setup_test_data(lead_provider:)
    # Scenario 1a - allowing lead providers to resume a participant without errors
    first_lead_provider_school_partnership = FactoryBot.create(:school_partnership, :for_year, year: contract_period.year, lead_provider:)
    FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-september")

    # Scenario 1b - preventing lead providers from resuming a participant as the participant has started with another lead provider
    other_lead_provider = FactoryBot.create(:lead_provider)
    school = first_lead_provider_school_partnership.school
    FactoryBot.create(:school_partnership, :for_year, year: contract_period.year, lead_provider: other_lead_provider, school:)

    # Scenario 4b - ECT record with billable declaration that can have their contract period and schedule identifier changed
    school = first_lead_provider_school_partnership.school
    FactoryBot.create(:school_partnership, :for_year, year: other_contract_period.year, lead_provider:, school:)
  end

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }

    stub_const("#{described_class}::NUMBER_OF_RECORDS_PER_SCENARIO", 1)

    # Ensure there is test data
    setup_test_data(lead_provider:)
  end

  describe "#plant" do
    subject(:plant) { instance.plant }

    it "creates participants relative to the NUMBER_OF_RECORDS_PER_SCENARIO constant for each scenario" do
      stub_const("#{described_class}::NUMBER_OF_RECORDS_PER_SCENARIO", 0)

      expect { plant }.not_to change(TrainingPeriod, :count)
    end

    it "creates a resumable 2024 participant for the lead provider" do
      plant

      # The first training period/teacher created is for the first scenario for the first LP.
      training_period = TrainingPeriod.first
      teacher = training_period.teacher

      Metadata::Manager.new.refresh_metadata!(teacher)

      expect(API::TrainingPeriods::TrainingStatus.new(training_period:).status).to eq(:withdrawn)
      expect(training_period.at_school_period).to be_ongoing
      expect(teacher.induction_periods).to be_present
      expect(teacher.finished_induction_period).to be_nil

      service = API::Teachers::Resume.new(
        lead_provider_id: lead_provider.id,
        teacher_api_id: teacher.api_id,
        teacher_type: :ect
      )

      expect(service).to be_valid

      expect { service.resume }.not_to raise_error
    end

    it "creates a 2024 participant that has started with another lead provider" do
      plant

      # A training period is created for the first scenario for each LP
      # so this is the first training period/teacher of the second scenario.
      training_period = TrainingPeriod.all[LeadProvider.count]
      teacher = training_period.teacher

      Metadata::Manager.refresh_all_metadata!

      expect(API::TrainingPeriods::TrainingStatus.new(training_period:).status).to eq(:withdrawn)
      expect(API::TrainingPeriods::TeacherStatus.new(latest_training_period: training_period, teacher:).status).to eq(:left)
      expect(training_period.at_school_period).to be_ongoing
      expect(teacher.induction_periods).to be_present
      expect(teacher.finished_induction_period).to be_nil

      service = API::Teachers::Resume.new(
        lead_provider_id: lead_provider.id,
        teacher_api_id: teacher.api_id,
        teacher_type: :ect
      )

      expect(service).not_to be_valid

      expect(service.errors[:teacher_api_id]).to include("This participant cannot be resumed because they are already active with another provider.")
    end

    it "creates a 2024 participant with a billable declaration that can have their contract period and schedule changed" do
      plant

      # The last training period/teacher created is for this scenario.
      training_period = TrainingPeriod.joins(:declarations).first
      teacher = training_period.teacher

      Metadata::Manager.refresh_all_metadata!

      expect(API::TrainingPeriods::TrainingStatus.new(training_period:).status).to eq(:active)
      expect(API::TrainingPeriods::TeacherStatus.new(latest_training_period: training_period, teacher:).status).to eq(:active)
      expect(training_period.at_school_period).to be_ongoing
      expect(teacher.induction_periods).to be_present
      expect(teacher.finished_induction_period).to be_nil

      declaration = teacher.ect_declarations.first
      expect(declaration).to be_declaration_type_started
      expect(declaration.overall_status).to eq("paid")

      other_schedule = FactoryBot.create(:schedule, contract_period: other_contract_period, identifier: "ecf-standard-april")

      service = API::Teachers::ChangeSchedule.new(
        lead_provider_id: training_period.lead_provider.id,
        teacher_api_id: teacher.api_id,
        teacher_type: :ect,
        contract_period_year: other_contract_period.year,
        schedule_identifier: other_schedule.identifier
      )

      expect(service).to be_valid

      expect { service.change_schedule }.not_to raise_error
    end

    it "logs the creation of records" do
      plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting api testing 2024 ECT participant seed scenarios/).once
      expect(logger).to have_received(:info).with(/Created resumable participant for #{lead_provider.name}/).once
      expect(logger).to have_received(:info).with(/Created participant started with another lead provider for #{lead_provider.name}/).once
      expect(logger).to have_received(:info).with(/Created participant with declaration that can change contract period\/schedule for #{lead_provider.name}/).once
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any data" do
        expect { instance.plant }.not_to change(TrainingPeriod, :count)
      end
    end
  end
end
