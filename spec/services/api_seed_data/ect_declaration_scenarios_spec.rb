RSpec.describe APISeedData::ECTDeclarationScenarios do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }

  def setup_test_data(lead_provider:)
    FactoryBot.create(:school_partnership, :for_year, year: contract_period.year, lead_provider:)
    FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-september").tap do |schedule|
      Declaration.declaration_types.each_key do |declaration_type|
        schedule.milestones.create!(declaration_type:, start_date: Date.new(2025, 6, 1))
      end
    end
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

    it "creates a 2025 participant with a retrained-1 declaration but no started declaration" do
      plant

      # The first training period/teacher created is for the first scenario.
      training_period = TrainingPeriod.first
      teacher = training_period.teacher

      Metadata::Manager.new.refresh_metadata!(teacher)

      expect(training_period.contract_period.year).to eq(2025)

      expect(training_period.schedule.identifier).to eq("ecf-standard-september")

      expect(training_period.started_on).to eq(Date.new(2025, 9, 2))
      expect(training_period).to be_ongoing

      expect(training_period.at_school_period.started_on).to eq(Date.new(2025, 9, 2))
      expect(training_period.at_school_period).to be_ongoing

      expect(teacher.induction_periods).to be_present
      expect(teacher.finished_induction_period).to be_nil

      expect(teacher.ect_declarations.count).to eq(1)
      expect(teacher.ect_declarations.first).to have_attributes(
        declaration_type: "retained-1",
        declaration_date: Date.new(2026, 1, 1).in_time_zone,
        overall_status: "paid"
      )

      service = API::Declarations::Create.new(
        lead_provider_id: lead_provider.id,
        teacher_api_id: teacher.api_id,
        teacher_type: :ect,
        evidence_type: "other",
        declaration_date: "2025-11-21T08:46:29Z",
        declaration_type: "started"
      )

      expect(service).to be_valid
      expect { service.create }.not_to raise_error
    end

    it "creates a 2025 participant with a paid started and submitted retained-2 declaration" do
      plant

      # The last training period/teacher created is for the second scenario.
      training_period = TrainingPeriod.last
      teacher = training_period.teacher

      Metadata::Manager.new.refresh_metadata!(teacher)

      expect(training_period.contract_period.year).to eq(2025)

      expect(training_period.schedule.identifier).to eq("ecf-standard-september")

      expect(training_period.started_on).to eq(Date.new(2025, 9, 1))
      expect(training_period).to be_ongoing

      expect(training_period.at_school_period.started_on).to eq(Date.new(2025, 9, 1))
      expect(training_period.at_school_period).to be_ongoing

      expect(teacher.induction_periods).to be_present
      expect(teacher.finished_induction_period).to be_nil

      expect(teacher.ect_declarations.count).to eq(2)
      started_declaration = teacher.ect_declarations.find_by(declaration_type: "started")
      expect(started_declaration).to have_attributes(
        declaration_type: "started",
        declaration_date: Date.new(2025, 9, 1).in_time_zone,
        overall_status: "paid"
      )
      retained_2_declaration = teacher.ect_declarations.find_by(declaration_type: "retained-2")
      expect(retained_2_declaration).to have_attributes(
        declaration_type: "retained-2",
        declaration_date: Date.new(2025, 9, 2).in_time_zone,
        overall_status: "no_payment"
      )

      void_service = API::Declarations::Void.new(
        lead_provider_id: lead_provider.id,
        declaration_api_id: retained_2_declaration.api_id
      )

      expect(void_service).to be_valid
      expect { void_service.void }.not_to raise_error

      service = API::Declarations::Create.new(
        lead_provider_id: lead_provider.id,
        teacher_api_id: teacher.api_id,
        teacher_type: :ect,
        evidence_type: "other",
        declaration_date: "2025-09-02T08:46:29Z",
        declaration_type: "retained-1"
      )

      expect(service).to be_valid
      expect { service.create }.not_to raise_error
    end

    it "logs the creation of records" do
      plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting api testing 2025 ECT declaration seed scenarios/).once
      expect(logger).to have_received(:info).with(/Created participant for #{lead_provider.name} with retained-1 declaration and no started declaration/).once
      expect(logger).to have_received(:info).with(/Created participant for #{lead_provider.name} with paid started declaration and submitted retained-2 declaration/).once
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any data" do
        expect { instance.plant }.not_to change(TrainingPeriod, :count)
      end
    end
  end
end
