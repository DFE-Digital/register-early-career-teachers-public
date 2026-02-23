RSpec.describe APISeedData::MentorScenarios do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  let(:contract_period_2024) { FactoryBot.create(:contract_period, year: 2024) }
  let(:contract_period_2025) { FactoryBot.create(:contract_period, year: 2025) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }

    # Create support data
    FactoryBot.create_list(:lead_provider, 2).each do |lead_provider|
      FactoryBot.create_list(:lead_provider_delivery_partnership, 2, :for_year, lead_provider:, year: contract_period_2024.year)
      FactoryBot.create_list(:lead_provider_delivery_partnership, 2, :for_year, lead_provider:, year: contract_period_2025.year)
    end
    APISeedData::Schools.new.plant
    APISeedData::SchoolPartnerships.new.plant
    APISeedData::SchedulesAndMilestones.new.plant
  end

  describe "#plant" do
    it "logs the creation of scenarios" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO).at_least(:once)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter).at_least(:once)
      expect(logger).to have_received(:info).with(/Planting api mentor seed scenarios/).once
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any teachers" do
        expect { instance.plant }.not_to change(Teacher, :count)
      end
    end
  end

  describe "#mentor_with_three_ects_2025" do
    it "creates a mentor with 3 ECTs across 2 schools" do
      expect {
        instance.send(:mentor_with_three_ects_2025)
      }.to change(Teacher, :count).by_at_least(4) # 1 mentor + 3 ECTs per active lead provider
    end

    it "creates 1 mentor per active lead provider for contract period 2025" do
      instance.send(:mentor_with_three_ects_2025)

      mentors_count = Teacher
        .joins(mentor_at_school_periods: { training_periods: :active_lead_provider })
        .where(active_lead_providers: { contract_period_year: contract_period_2025.year })
        .distinct
        .count

      expect(mentors_count).to be >= 1
    end

    it "creates 3 ECTs per active lead provider for contract period 2025" do
      instance.send(:mentor_with_three_ects_2025)

      ects_count = Teacher
        .joins(ect_at_school_periods: { training_periods: :active_lead_provider })
        .where(active_lead_providers: { contract_period_year: contract_period_2025.year })
        .distinct
        .count

      expect(ects_count).to be >= 3
    end

    it "creates mentor and ECTs with correct start dates" do
      instance.send(:mentor_with_three_ects_2025)

      training_periods = TrainingPeriod
        .joins(:active_lead_provider)
        .where(active_lead_providers: { contract_period_year: contract_period_2025.year })

      expect(training_periods.pluck(:started_on).uniq).to include(Date.new(2025, 9, 1))
    end

    it "creates ECTs across 2 different schools" do
      instance.send(:mentor_with_three_ects_2025)

      schools = Teacher
        .joins(ect_at_school_periods: { training_periods: :active_lead_provider })
        .where(active_lead_providers: { contract_period_year: contract_period_2025.year })
        .pluck("ect_at_school_periods.school_id").uniq

      expect(schools.count).to be >= 2
    end

    it "logs the creation of mentor scenarios" do
      instance.send(:mentor_with_three_ects_2025)

      expect(logger).to have_received(:info).with(/Created mentor with 3 ECTs \(2025\)/).at_least(:once)
    end
  end

  describe "#mentor_with_two_ects_2024" do
    it "creates a mentor with 2 ECTs across 2 schools" do
      expect {
        instance.send(:mentor_with_two_ects_2024)
      }.to change(Teacher, :count).by_at_least(3) # 1 mentor + 2 ECTs per active lead provider
    end

    it "creates 1 mentor per active lead provider for contract period 2024" do
      instance.send(:mentor_with_two_ects_2024)

      mentors_count = Teacher
        .joins(mentor_at_school_periods: { training_periods: :active_lead_provider })
        .where(active_lead_providers: { contract_period_year: contract_period_2024.year })
        .distinct
        .count

      expect(mentors_count).to be >= 1
    end

    it "creates 2 ECTs per active lead provider for contract period 2024" do
      instance.send(:mentor_with_two_ects_2024)

      ects_count = Teacher
        .joins(ect_at_school_periods: { training_periods: :active_lead_provider })
        .where(active_lead_providers: { contract_period_year: contract_period_2024.year })
        .distinct
        .count

      expect(ects_count).to be >= 2
    end

    it "creates mentor and ECTs with correct start dates" do
      instance.send(:mentor_with_two_ects_2024)

      training_periods = TrainingPeriod
        .joins(:active_lead_provider)
        .where(active_lead_providers: { contract_period_year: contract_period_2024.year })

      expect(training_periods.pluck(:started_on).uniq).to include(Date.new(2024, 9, 1))
    end

    it "creates ECTs across 2 different schools" do
      instance.send(:mentor_with_two_ects_2024)

      schools = Teacher
        .joins(ect_at_school_periods: { training_periods: :active_lead_provider })
        .where(active_lead_providers: { contract_period_year: contract_period_2024.year })
        .pluck("ect_at_school_periods.school_id").uniq

      expect(schools.count).to be >= 2
    end

    it "logs the creation of mentor scenarios" do
      instance.send(:mentor_with_two_ects_2024)

      expect(logger).to have_received(:info).with(/Created mentor with 2 ECTs \(2024\)/).at_least(:once)
    end
  end
end
