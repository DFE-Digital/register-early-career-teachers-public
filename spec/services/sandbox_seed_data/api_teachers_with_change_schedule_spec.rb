RSpec.describe SandboxSeedData::APITeachersWithChangeSchedule do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  let(:contract_period) { FactoryBot.create :contract_period, year: described_class::CHANGE_FROM_CONTRACT_PERIOD_YEAR }
  let(:next_contract_period) { FactoryBot.create :contract_period, year: contract_period.year + 1 }
  let(:active_lead_providers) { FactoryBot.create_list(:active_lead_provider, 2, contract_period:) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }
    stub_const("#{described_class}::NUMBER_OF_RECORDS", 1)

    active_lead_providers.each do |active_lead_provider|
      # Create school partnerships for contract period
      FactoryBot.create_list(:school_partnership, 2, :for_year, lead_provider: active_lead_provider.lead_provider, year: contract_period.year)
      # Create school partnerships for next contract period with same school
      SchoolPartnership.find_each do |school_partnership|
        FactoryBot.create_list(:school_partnership, 2, :for_year, school: school_partnership.school, lead_provider: active_lead_provider.lead_provider, year: next_contract_period.year)

        # Ensure schedules exist for contract periods and school partnerships
        Schedule.identifiers.each_value do |identifier|
          FactoryBot.create(:schedule, contract_period: school_partnership.contract_period, identifier:)
        end
      end
    end
  end

  describe "#plant" do
    subject(:plant) { instance.plant }

    let(:teacher_data) do
      data = {}
      Teacher.find_each do |teacher|
        (teacher.ect_at_school_periods + teacher.mentor_at_school_periods).each do |school_period|
          school_period.training_periods.latest_first.each do |training_period|
            data[teacher.id] ||= []
            data[teacher.id] << {
              schedule: training_period.schedule.identifier,
              contract_period: training_period.school_partnership.contract_period.year,
            }
          end
        end
      end
      data
    end

    it "creates teachers for every lead provider" do
      plant

      # 2x lead providers
      # 2x teachers (ect + mentor)
      # 3x variations
      # 1x number of records
      teachers_count = active_lead_providers.count * 2 * 3 * described_class::NUMBER_OF_RECORDS

      expect(Teacher.count).to eq(teachers_count)
    end

    it "creates teachers with all variations" do
      plant

      # Check for schedule and contract period change
      change = teacher_data.find { |_, change| change[0][:schedule] != change[1][:schedule] && change[0][:contract_period] != change[1][:contract_period] }
      expect(change).to be_present

      # Check for only schedule change
      change = teacher_data.find { |_, change| change[0][:schedule] != change[1][:schedule] && change[0][:contract_period] == change[1][:contract_period] }
      expect(change).to be_present

      # Check for only contract period change
      change = teacher_data.find { |_, change| change[0][:schedule] == change[1][:schedule] && change[0][:contract_period] != change[1][:contract_period] }
      expect(change).to be_present
    end

    it "logs the creation of api teachers records" do
      plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting api teachers with change schedule/).once

      training_period = TrainingPeriod.all.sample
      training_status = ::API::TrainingPeriods::TrainingStatus.new(training_period:).status
      expect(logger).to have_received(:info).with(/(training period - provider-led - #{training_status})/).at_least(:once)
      expect(logger).to have_received(:info).with(/trained by #{training_period.school_partnership.active_lead_provider.lead_provider.name} \(LP\)/).at_least(:once)
      expect(logger).to have_received(:info).with(/and #{training_period.school_partnership.delivery_partner.name} \(DP\)/).at_least(:once)
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any teachers, training periods or school periods" do
        expect { instance.plant }.not_to change(Teacher, :count)
        expect { instance.plant }.not_to change(TrainingPeriod, :count)
        expect { instance.plant }.not_to change(ECTAtSchoolPeriod, :count)
        expect { instance.plant }.not_to change(MentorAtSchoolPeriod, :count)
      end
    end
  end
end
