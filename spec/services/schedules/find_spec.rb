RSpec.describe Schedules::Find do
  include ActiveJob::TestHelper

  let(:year) { Date.current.year }

  let(:contract_period) { FactoryBot.create(:contract_period, year:) }
  let(:previous_contract_period) { FactoryBot.create(:contract_period, year: year - 1) }
  let(:contract_period_year) { year }

  let(:training_programme) { 'provider_led' }
  let(:period) { ect_at_school_period }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, :with_training_period, teacher:, school:) }

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: previous_contract_period) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:) }

  before do
    FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-january")
    FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-april")
    FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-september")
    FactoryBot.create(:schedule, contract_period:, identifier: "ecf-reduced-september")
  end

  describe '#for_ects' do
    subject(:service) do
      described_class.new(period:, training_programme:, started_on:).call
    end

    context 'when the training period is school-led' do
      let(:started_on) { Date.new(year, 9, 1) }
      let(:training_programme) { 'school_led' }

      it 'does not assign a schedule to the current training period' do
        expect(service).to be_nil
      end
    end

    context 'when the training period is provider-led' do
      context 'when there are no previous training periods' do
        let(:started_on) { Date.new(year, 7, 1) }

        it 'assigns a standard schedule' do
          expect(service.identifier).to include('standard')
        end

        context 'when they were registered before their start date' do
          let(:registered_on) { started_on - 1.day }

          around do |example|
            travel_to(registered_on) do
              example.run
            end
          end

          context 'when the training period started between 1st June and 31st October' do
            let(:started_on) { Date.new(year, 7, 1) }

            it 'assigns the schedule to the current training period' do
              expect(service.identifier).to include('september')
            end
          end

          context 'when the training period started between 1st November and 29th February' do
            let(:year) { 2024 }

            context 'when the year is a leap year' do
              let(:started_on) { Date.new(year, 2, 29) }

              it 'assigns the schedule to the current training period' do
                expect(service.identifier).to include('january')
              end
            end

            context 'when the year is not a leap year' do
              let(:year) { 2023 }

              let(:started_on) { Date.new(year, 1, 15) }

              it 'assigns the schedule to the current training period' do
                expect(service.identifier).to include('january')
              end
            end
          end

          context 'when the training period started between 1st March and 31st May' do
            let(:started_on) { Date.new(year, 4, 10) }

            it 'assigns the schedule to the current training period' do
              expect(service.identifier).to include('april')
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
            expect(service.identifier).to include('january')
          end
        end
      end

      context 'when there is one previous training period' do
        let(:started_on) { provider_led_start_date }
        let(:registered_on) { Date.new(year, 6, 15) }
        let(:provider_led_start_date) { Date.new(year, 12, 1) }
        let(:previous_start_date) { Date.new(year, 7, 1) }

        context 'when the previous training period is school-led' do
          it 'assigns the schedule based on the start date of the current training period' do
            first_training_period = nil
            travel_to(registered_on) do
              first_training_period = FactoryBot.create(:training_period, :school_led, :ongoing, started_on: previous_start_date, ect_at_school_period:)
            end

            travel_to(provider_led_start_date) do
              expect(service.identifier).to include('standard-january')
            end
          end
        end

        context 'when the previous training period is provider-led' do
          let(:schedule) { FactoryBot.create(:schedule, contract_period: previous_contract_period, identifier: 'ecf-reduced-september') }

          it 'uses the identifier from the previous provider-led training period' do
            first_training_period = nil
            travel_to(registered_on) do
              first_training_period = FactoryBot.create(:training_period, :provider_led, :ongoing,
                                                        started_on: previous_start_date,
                                                        ect_at_school_period:,
                                                        schedule:,
                                                        school_partnership:)
            end

            travel_to(provider_led_start_date) do
              expect(service.identifier).to include('reduced-september')
            end
          end
        end
      end

      context 'when there is more than one previous training period' do
        let(:schedule) { FactoryBot.create(:schedule, contract_period: previous_contract_period, identifier: 'ecf-reduced-september') }

        let(:started_on) { provider_led_start_date }
        let(:registered_on) { Date.new(year - 1, 6, 15) }
        let(:provider_led_start_date) { Date.new(year - 1, 12, 1) }
        let(:previous_start_date) { Date.new(year, 7, 1) }

        context 'when the first training period is provider-led and the second is school-led' do
          it 'uses the identifier from the most recent provider-led training period' do
            first_training_period = nil
            travel_to(registered_on) do
              first_training_period = FactoryBot.create(:training_period, :provider_led,
                                                        started_on: previous_start_date,
                                                        finished_on: previous_start_date + 50.days,
                                                        ect_at_school_period:,
                                                        schedule:,
                                                        school_partnership:)
            end

            second_training_period = nil
            travel_to(registered_on + 60.days) do
              second_training_period = FactoryBot.create(:training_period, :school_led, :ongoing,
                                                         started_on: previous_start_date + 60.days,
                                                         ect_at_school_period:)
            end

            travel_to(provider_led_start_date) do
              expect(service.identifier).to include('reduced-september')
            end
          end
        end
      end

      context 'when the teacher has moved school' do
        let(:new_school_start_date) { old_school_end_date + 3.months }
        let(:year) { 2025 }
        let(:old_school_start_date) { Date.new(2024, 6, 1) }
        let(:old_school_end_date) { Date.new(2025, 7, 15) }
        let(:registered_on) { Date.new(year, 6, 15) }
        let(:started_on) { new_school_start_date }
        let(:old_school) { FactoryBot.create(:school) }
        let(:ect_at_old_school_period) { FactoryBot.create(:ect_at_school_period, :finished, teacher:, school: old_school, started_on: old_school_start_date, finished_on: old_school_end_date) }
        let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, :with_training_period, teacher:, school:, started_on:) }

        let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school: old_school) }

        context 'when the previous training period is provider-led' do
          let(:schedule) { FactoryBot.create(:schedule, contract_period: previous_contract_period, identifier: 'ecf-reduced-september') }

          it 'uses the identifier from the previous provider-led training period' do
            first_training_period = nil
            travel_to(registered_on) do
              first_training_period = FactoryBot.create(:training_period, :provider_led,
                                                        started_on: old_school_start_date,
                                                        finished_on: old_school_end_date,
                                                        ect_at_school_period: ect_at_old_school_period,
                                                        schedule:,
                                                        school_partnership:)
            end

            travel_to(new_school_start_date) do
              expect(service.identifier).to include('reduced-september')
            end
          end
        end
      end
    end
  end
end
