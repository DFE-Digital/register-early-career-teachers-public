RSpec.describe Schedules::Assignment do
  include ActiveJob::TestHelper

  
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:) }
  
  let(:year) { Date.current.year }
  
  let(:contract_period) { FactoryBot.create(:contract_period, year:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, :with_training_period, teacher:, school:) }

  

  let(:identifier) { "ecf-#{schedule_type}-#{schedule_month}" }

  before do
    FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-january")
    FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-april")
    FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-september")
  end

  describe '#for_ects' do
    subject(:service) do
      described_class.new(training_period:).call
    end

    context 'when the training period is school-led' do
      let!(:training_period) { FactoryBot.create(:training_period, :school_led, :ongoing, started_on:, ect_at_school_period:) }
      let(:started_on) { Date.new(year, 9, 1) }

      it 'does not assign a schedule to the current training period' do
        service
        expect(training_period.schedule).to be_nil
      end
    end

    context 'when the training period is provider-led' do

      context 'when there are no previous training periods' do
        let!(:training_period) { FactoryBot.create(:training_period, :provider_led, :ongoing, ect_at_school_period:, started_on:, school_partnership:) }
        let(:started_on) { Date.new(year, 7, 1) }

        it 'assigns a standard schedule' do
          service
          expect(training_period.schedule.identifier).to include('standard')
        end

        context 'when they were registered before their start date' do
          let(:registered_on) { started_on - 1.days }

          around do |example|
            travel_to(registered_on) do
              example.run
            end
          end

          context 'when the training period started between 1st June and 31st October' do
            let(:started_on) { Date.new(year, 7, 1) }

            it 'assigns the schedule to the current training period' do
              service
              expect(training_period.schedule.identifier).to include('september')
            end
          end

          context 'when the training period started between 1st November and 29th February' do
            let(:year) { 2023 }

            context 'when the year is a leap year' do
              let(:started_on) { Date.new(year + 1, 2, 29) }

              it 'assigns the schedule to the current training period' do
                service
                expect(training_period.schedule.identifier).to include('january')
              end
            end

            context 'when the year is not a leap year' do
              let(:started_on) { Date.new(year + 1, 1, 15) }

              it 'assigns the schedule to the current training period' do
                service
                expect(training_period.schedule.identifier).to include('january')
              end
            end
          end

          context 'when the training period started between 1st March and 31st May' do
            let(:started_on) { Date.new(year + 1, 4, 10) }

            it 'assigns the schedule to the current training period' do
              service
              expect(training_period.schedule.identifier).to include('april')
            end
          end
        end

        context 'when they were registered after their start date' do
          let(:registered_on) { Date.new(year, 12, 1) }
          let(:started_on) { Date.new(year, 7, 1) }
          
          around do |example|
            travel_to(registered_on) do
              example.run
            end
          end


          it 'assigns the schedule based on the registration date to the current training period' do
            service
            expect(training_period.schedule.identifier).to include('january')
          end
        end
        


        
      end

      context 'when there is a previous school-led training period' do  
        let(:started_on) { Date.new(year, 7, 1) }
        let(:registered_on) { Date.new(year, 6, 15) }
        let(:provider_led_started_on) { Date.new(year, 12, 1) }


        it 'assigns the schedule based on the start date of the current training period' do
          first_training_period = nil
          travel_to(registered_on) do
            first_training_period = FactoryBot.create(:training_period, :school_led, :ongoing , started_on:, ect_at_school_period:)
          end

          travel_to(provider_led_started_on) do
            first_training_period.finished_on = provider_led_started_on - 1.day
            first_training_period.save!

            training_period = FactoryBot.create(:training_period, :provider_led, :ongoing, ect_at_school_period:, started_on: provider_led_started_on, school_partnership:) 
          
            described_class.new(training_period:).call
            expect(training_period.schedule.identifier).to include('january')
          end
        end
      end
    end
  end



end
