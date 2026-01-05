RSpec.shared_examples "no replacement schedule assigned" do
  it "does not assign a replacement schedule" do
    expect(service.identifier).not_to include("replacement")
    expect(service.identifier).not_to be_nil
  end
end

RSpec.shared_examples "replacement schedule assigned" do
  it "assigns a replacement schedule" do
    expect(service.identifier).to include("replacement")
  end
end

RSpec.describe Schedules::Find do
  include ActiveJob::TestHelper

  let(:year) { Date.current.year }

  let(:contract_period) { FactoryBot.create(:contract_period, year:) }
  let(:previous_contract_period) { FactoryBot.create(:contract_period, year: year - 1) }
  let(:contract_period_year) { year }

  let(:training_programme) { "provider_led" }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, :with_training_period, teacher:, school:) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, :with_training_period, teacher:, school:) }
  let(:mentee) {}

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: previous_contract_period) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:) }

  describe "#call" do
    subject(:service) do
      described_class.new(period:, training_programme:, started_on:, period_type_key:, mentee:).call
    end

    %i[mentor_at_school_period ect_at_school_period].each do |period_type|
      before do
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-january")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-april")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-september")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-reduced-september")
        FactoryBot.create(:schedule, contract_period: previous_contract_period, identifier: "ecf-standard-january")
        FactoryBot.create(:schedule, contract_period: previous_contract_period, identifier: "ecf-standard-april")
      end

      let(:period_type_key) { period_type }

      context "when the period is a #{period_type.to_s.humanize}" do
        let(:period) { send(period_type) }
        let(:started_on) { Date.new(year, 7, 1) }

        context "when the training period is school-led" do
          let(:training_programme) { "school_led" }

          it "does not assign a schedule to the current training period" do
            expect(service).to be_nil
          end
        end

        context "when the training period is provider-led" do
          context "when there are no previous training periods" do
            it "assigns a standard schedule" do
              expect(service.identifier).to include("standard")
            end

            context "when they were registered before their start date" do
              let(:registered_on) { started_on - 1.day }

              around do |example|
                travel_to(registered_on) do
                  example.run
                end
              end

              context "when the training period started between 1st June and 31st October" do
                let(:started_on) { Date.new(year, 7, 1) }

                it "assigns the schedule to the current training period" do
                  expect(service.identifier).to include("september")
                end
              end

              context "when the training period started between 1st November and 29th February" do
                let(:year) { 2024 }

                context "when the year is a leap year" do
                  let(:started_on) { Date.new(year, 2, 29) }

                  it "assigns the schedule to the current training period" do
                    expect(service.identifier).to include("january")
                  end
                end

                context "when the year is not a leap year" do
                  let(:year) { 2023 }

                  let(:started_on) { Date.new(year, 1, 15) }

                  it "assigns the schedule to the current training period" do
                    expect(service.identifier).to include("january")
                  end
                end
              end

              context "when the training period started between 1st March and 31st May" do
                let(:started_on) { Date.new(year + 1, 4, 10) }

                it "assigns the schedule to the current training period" do
                  expect(service.identifier).to include("april")
                end
              end
            end

            context "when they were registered after their start date" do
              let(:registered_on) { Date.new(year, 12, 1) }
              let(:started_on) { Date.new(year, 7, 1) }

              around do |example|
                travel_to(registered_on) do
                  example.run
                end
              end

              it "assigns the schedule based on the registration date to the current training period" do
                expect(service.identifier).to include("january")
              end
            end
          end

          context "when there is one previous training period" do
            let(:started_on) { provider_led_start_date }
            let(:registered_on) { Date.new(year, 6, 15) }
            let(:provider_led_start_date) { Date.new(year, 12, 1) }
            let(:previous_start_date) { Date.new(year, 7, 1) }

            context "when the previous training period is school-led" do
              it "assigns the schedule based on the start date of the current training period" do
                first_training_period = nil
                travel_to(registered_on) do
                  first_training_period = FactoryBot.create(:training_period, :school_led, :ongoing, started_on: previous_start_date, ect_at_school_period:)
                end

                travel_to(provider_led_start_date) do
                  expect(service.identifier).to include("standard-january")
                end
              end
            end

            context "when the previous training period is provider-led" do
              let(:schedule) { FactoryBot.create(:schedule, contract_period: previous_contract_period, identifier: "ecf-reduced-september") }

              it "uses the identifier from the previous provider-led training period" do
                first_training_period = nil
                travel_to(registered_on) do
                  first_training_period = FactoryBot.create(:training_period, :provider_led, :ongoing,
                                                            started_on: previous_start_date,
                                                            ect_at_school_period:,
                                                            schedule:,
                                                            school_partnership:)
                end

                travel_to(provider_led_start_date) do
                  expect(service.identifier).to include("reduced-september")
                end
              end
            end
          end

          context "when there is more than one previous training period" do
            let(:schedule) { FactoryBot.create(:schedule, contract_period: previous_contract_period, identifier: "ecf-reduced-september") }

            let(:started_on) { provider_led_start_date }
            let(:registered_on) { Date.new(year - 1, 6, 15) }
            let(:provider_led_start_date) { Date.new(year - 1, 12, 1) }
            let(:previous_start_date) { Date.new(year, 7, 1) }

            context "when the first training period is provider-led and the second is school-led" do
              it "uses the identifier from the most recent provider-led training period" do
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
                  expect(service.identifier).to include("reduced-september")
                end
              end
            end
          end

          context "when the teacher has moved school" do
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

            context "when the previous training period is provider-led" do
              let(:schedule) { FactoryBot.create(:schedule, contract_period: previous_contract_period, identifier: "ecf-reduced-september") }

              it "uses the identifier from the previous provider-led training period" do
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
                  expect(service.identifier).to include("reduced-september")
                end
              end
            end
          end
        end
      end
    end

    context "replacement schedule for mentor" do
      let(:period_type_key) { :mentor_at_school_period }
      let(:period) { mentor_at_school_period }

      let(:started_on) { provider_led_start_date }
      let(:registered_on) { Date.new(year, 6, 15) }
      let(:provider_led_start_date) { Date.new(year, 12, 1) }
      let(:previous_start_date) { Date.new(year, 7, 1) }

      let(:mentee) { FactoryBot.create(:ect_at_school_period, started_on: previous_start_date, finished_on: 1.day.ago) }
      let(:schedule) { FactoryBot.create(:schedule, contract_period: previous_contract_period, identifier: "ecf-standard-september") }

      before do
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-january")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-april")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-september")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-replacement-january")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-replacement-april")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-replacement-september")
      end

      around do |example|
        travel_to(provider_led_start_date) do
          example.run
        end
      end

      context "when the mentee has not previously received training" do
        it_behaves_like "no replacement schedule assigned"
      end

      context "when the mentee has previously received school-led training" do
        let!(:mentee_training_period) { FactoryBot.create(:training_period, :school_led, :ongoing, started_on: previous_start_date, ect_at_school_period: mentee) }

        it_behaves_like "no replacement schedule assigned"
      end

      context "when the mentee has previously received provider-led training" do
        context "when there is one previous mentor with a training period" do
          let!(:mentee_training_period) { FactoryBot.create(:training_period, :provider_led, :ongoing, started_on: previous_start_date, ect_at_school_period: mentee) }
          let(:previous_mentor) { FactoryBot.create(:mentor_at_school_period, started_on: previous_start_date, finished_on: 1.day.ago) }
          let!(:mentorship_period) { FactoryBot.create(:mentorship_period, started_on: previous_start_date, finished_on: 1.day.ago, mentee:, mentor: previous_mentor) }
          let!(:mentor_training_period) { FactoryBot.create(:training_period, :provider_led, :ongoing, :for_mentor, started_on: previous_start_date, mentor_at_school_period: previous_mentor) }

          context "when the previous mentor has not started training" do
            it_behaves_like "no replacement schedule assigned"
          end

          context "when the previous mentor is the same as the current mentor" do
            let!(:previous_mentor) { mentor_at_school_period }

            it_behaves_like "no replacement schedule assigned"
          end

          context "when the previous mentor has started training" do
            let!(:declaration) { FactoryBot.create(:declaration, training_period: mentor_training_period) }

            it_behaves_like "replacement schedule assigned"

            context "when the mentor is ineligible for funding" do
              let(:teacher) { FactoryBot.create(:teacher, :ineligible_for_mentor_funding) }

              it_behaves_like "no replacement schedule assigned"
            end

            context "when the previous mentor has both ect and mentor periods" do
              before do
                FactoryBot.create(:ect_at_school_period, started_on: previous_start_date - 1.year, teacher: previous_mentor.teacher, school:)
                FactoryBot.create(:training_period, :provider_led, :ongoing, started_on: previous_start_date - 1.year, ect_at_school_period: previous_mentor.teacher.ect_at_school_periods.last, school_partnership:)
              end

              it_behaves_like "replacement schedule assigned"
            end
          end
        end

        context "when there are multiple previous mentors with training periods" do
          let(:first_date) { Date.new(year, 7, 1) }
          let(:second_date) { Date.new(year, 7, 15) }

          let(:first_mentor) { FactoryBot.create(:mentor_at_school_period, started_on: first_date, finished_on: second_date) }
          let(:second_mentor) { FactoryBot.create(:mentor_at_school_period, started_on: first_date, finished_on: 1.day.ago) }
          let!(:first_mentor_training_period) { FactoryBot.create(:training_period, :provider_led, :ongoing, :for_mentor, started_on: first_date, mentor_at_school_period: first_mentor) }
          let!(:second_mentor_training_period) { FactoryBot.create(:training_period, :provider_led, :ongoing, :for_mentor, started_on: second_date, mentor_at_school_period: second_mentor) }

          before do
            FactoryBot.create(:training_period, :provider_led, :ongoing, started_on: first_date, ect_at_school_period: mentee)
            FactoryBot.create(:mentorship_period, started_on: first_date, finished_on: second_date - 1.day, mentee:, mentor: first_mentor)
            FactoryBot.create(:mentorship_period, started_on: second_date, finished_on: 1.day.ago, mentee:, mentor: second_mentor)
          end

          context "when none of the previous mentors have started training" do
            it_behaves_like "no replacement schedule assigned"
          end

          context "when the earliest previous mentor has started training" do
            let!(:declaration) { FactoryBot.create(:declaration, training_period: first_mentor_training_period) }

            it_behaves_like "replacement schedule assigned"
          end

          context "when the latest previous mentor has started training" do
            let!(:declaration) { FactoryBot.create(:declaration, training_period: second_mentor_training_period) }

            it_behaves_like "replacement schedule assigned"
          end

          context "when the new mentor is ineligible for funding" do
            let(:teacher) { FactoryBot.create(:teacher, :ineligible_for_mentor_funding) }
            let!(:declaration) { FactoryBot.create(:declaration, training_period: second_mentor_training_period) }

            it_behaves_like "no replacement schedule assigned"
          end
        end
      end
    end

    context "when the most recent provider-led schedule is from a different contract period" do
      let(:year) { 2025 }
      let(:period) { ect_at_school_period }
      let(:started_on) { Date.new(year, 7, 1) }
      let(:previous_start_date) { Date.new(year - 1, 7, 1) }
      let!(:old_schedule) { FactoryBot.create(:schedule, contract_period: previous_contract_period, identifier: "ecf-standard-september") }

      around { |example| travel_to(started_on) { example.run } }

      before do
        FactoryBot.create(:training_period, :provider_led, :ongoing,
                          ect_at_school_period:,
                          started_on: previous_start_date,
                          schedule: old_schedule,
                          school_partnership:)
      end

      it "returns a schedule in the current contract period" do
        expect(service).to eq(Schedule.find_by(contract_period_year: contract_period.year, identifier: "ecf-standard-september"))
      end
    end

    context "when the most recent provider-led schedule is from a different contract period for a mentor replacement" do
      let(:year) { 2025 }
      let(:period) { mentor_at_school_period }
      let(:started_on) { Date.new(year, 7, 1) }
      let(:previous_start_date) { Date.new(year - 1, 7, 1) }
      let!(:old_schedule) { FactoryBot.create(:schedule, contract_period: previous_contract_period, identifier: "ecf-replacement-september") }

      around { |example| travel_to(started_on) { example.run } }

      before do
        FactoryBot.create(:training_period, :provider_led, :ongoing,
                          :for_mentor,
                          mentor_at_school_period:,
                          started_on: previous_start_date,
                          schedule: old_schedule,
                          school_partnership:)
      end

      context "and the identifier exists in the current contract period" do
        before do
          FactoryBot.create(:schedule, contract_period:, identifier: "ecf-replacement-september")
        end

        it "carries over the replacement schedule into the current contract period" do
          expect(service).to eq(Schedule.find_by(contract_period_year: contract_period.year,
                                                 identifier: "ecf-replacement-september"))
        end
      end

      context "and the identifier is missing in the current contract period" do
        it_behaves_like "no replacement schedule assigned"

        it "falls back to the standard schedule in the current contract period" do
          expect(service).to eq(Schedule.find_by(contract_period_year: contract_period.year,
                                                 identifier: "ecf-standard-september"))
        end
      end
    end
  end
end
