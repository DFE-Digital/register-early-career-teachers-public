RSpec.describe API::Teachers::ChangeSchedule, type: :model do
  subject(:instance) do
    described_class.new(
      lead_provider_id:,
      teacher_api_id:,
      teacher_type:,
      contract_period_year:,
      schedule_identifier:
    )
  end

  let(:lead_provider) { training_period.lead_provider }
  let(:teacher) { training_period.teacher }
  let(:school_partnership) { training_period.school_partnership }
  let(:contract_period) { training_period.contract_period }
  let(:contract_period_year) { contract_period.year }
  let!(:schedule) { FactoryBot.create(:schedule, identifier: schedule_identifier, contract_period:) }
  let(:schedule_identifier) { training_period.for_ect? ? "ecf-standard-april" : "ecf-replacement-september" }

  it_behaves_like "an API teacher shared action" do
    describe "validations" do
      %i[ect mentor].each do |trainee_type|
        context "for #{trainee_type}" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 2.months.from_now) }
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :active, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: 1.week.from_now) }
          let(:teacher_type) { trainee_type }

          it { is_expected.to be_valid }

          it { is_expected.to validate_presence_of(:schedule_identifier).with_message("The property '#/schedule_identifier' must be present and correspond to a valid schedule.") }

          context "when schedule does not exist" do
            before do
              schedule_identifier
              schedule.destroy!
            end

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:schedule_identifier, "The property '#/schedule_identifier' must be present and correspond to a valid schedule.") }
          end

          context "when training_period is withdrawn" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :withdrawn, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: 1.week.from_now) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "Cannot perform actions on a withdrawn participant") }
          end

          context "when changing to the same schedule" do
            let!(:schedule) { training_period.schedule }
            let(:schedule_identifier) { schedule.identifier }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:schedule_identifier, "Selected schedule is already on the profile") }
          end

          if trainee_type == :ect
            context "when an ECT attempts to change to a replacement schedule" do
              let(:schedule_identifier) { "ecf-replacement-september" }
              let!(:schedule) { FactoryBot.create(:schedule, identifier: schedule_identifier, contract_period:) }

              it { is_expected.to have_one_error_per_attribute }
              it { is_expected.to have_error(:schedule_identifier, "Selected schedule is not valid for the teacher_type") }
            end
          end

          context "when changing contract_period_year without a school partnership" do
            let(:contract_period_year) { Time.zone.today.year + 3 }

            before do
              contract_period = FactoryBot.create(:contract_period, year: contract_period_year)
              FactoryBot.create(:schedule, identifier: schedule_identifier, contract_period:)
            end

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:contract_period_year, "You cannot change a participant to this contract_period as you do not have a partnership with the school for the contract_period. Contact the DfE for assistance.") }
          end

          context "when the training period is not ongoing today" do
            before { training_period.update!(finished_on: 1.day.ago) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "You cannot change this participant's schedule. Only the lead provider currently training this participant can update their schedule.") }
          end

          context "when there are future training periods (for the same teacher)" do
            before do
              FactoryBot.create(:training_period, :"for_#{trainee_type}", started_on: training_period.finished_on, finished_on: at_school_period.finished_on, "#{trainee_type}_at_school_period": at_school_period)
            end

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "You cannot change this participant’s schedule as they are due to start with another lead provider in the future.") }
          end

          context "when there are future training periods (for a different teacher)" do
            before do
              at_school_period = FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 3.years.ago, finished_on: nil)
              FactoryBot.create(:training_period, :"for_#{trainee_type}", started_on: training_period.finished_on, finished_on: at_school_period.finished_on, "#{trainee_type}_at_school_period": at_school_period)
            end

            it { is_expected.to be_valid }
          end

          context "when the contract_period_year is not specified and the teacher_type is invalid" do
            let(:contract_period_year) { nil }
            let(:teacher_type) { "invalid" }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_type, "The entered '#/teacher_type' is not recognised for the given participant. Check details and try again.") }
          end

          context "when participant has completed training" do
            before do
              training_period.update!(finished_on: 1.day.ago)
              if trainee_type == :ect
                FactoryBot.create(:induction_period, :pass, teacher:)
              else
                teacher.update!(mentor_became_ineligible_for_funding_on: Time.zone.now, mentor_became_ineligible_for_funding_reason: "completed_declaration_received")
              end
            end

            it "returns error" do
              expect(subject).to have_one_error_per_attribute
              expect(subject).to have_error(:teacher_api_id, "You cannot change this participant’s schedule as they have completed their training or induction.")
            end
          end

          context "guarded error messages" do
            subject(:instance) { described_class.new }

            it { is_expected.to have_one_error_per_attribute }
          end

          context "when moving to a frozen contract period where the participant has not been before" do
            let(:contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen, year: training_period.contract_period.year + 1) }
            let!(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: contract_period.year, lead_provider:, school: training_period.school_partnership.school) }

            it { is_expected.to have_one_error_per_attribute }

            it { is_expected.to have_error(:contract_period_year, "You cannot move a participant to a payments frozen cohort unless they previously belonged to that cohort.") }
          end

          context "when the training period `started_on` has not yet passed and there are existing declarations" do
            let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: Time.zone.today, finished_on: 2.weeks.from_now) }
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :active, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on) }
            let!(:declaration) { FactoryBot.create(:declaration, training_period:) }

            context "when declarations are valid for the new schedule" do
              it { is_expected.to be_valid }
            end

            context "when declarations are not valid for the new schedule" do
              before do
                declaration.update!(declaration_date: 5.years.ago)
                FactoryBot.create(:milestone, schedule:)
              end

              it { is_expected.to have_one_error_per_attribute }

              it { is_expected.to have_error(:schedule_identifier, "The change of schedule cannot be applied because a previous change of schedule and a declaration were made on the same day. Applying another change of schedule would invalidate existing declarations. Please contact DfE for assistance.") }
            end
          end
        end
      end
    end

    describe "#change_schedule" do
      %i[ect mentor].each do |trainee_type|
        context "for #{trainee_type}" do
          let(:teacher_type) { trainee_type }

          context "when invalid" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing) }
            let(:teacher_api_id) { SecureRandom.uuid }

            it { expect(instance.change_schedule).to be(false) }
            it { expect { instance.change_schedule }.not_to(change { training_period.reload.attributes }) }
          end

          context "when valid" do
            let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 2.weeks.from_now) }
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :active, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on) }
            let(:service) { instance_double(Teachers::ChangeSchedule) }

            before do
              author = an_instance_of(Events::LeadProviderAPIAuthor)
              allow(Teachers::ChangeSchedule).to receive(:new).with(lead_provider:, teacher:, training_period:, schedule:, school_partnership:, author:).and_return(service)
              allow(service).to receive(:change_schedule)
            end

            context "when the contract period year is not changing" do
              it "changes the schedule via change schedule service" do
                instance.change_schedule

                expect(service).to have_received(:change_schedule).once
              end
            end

            context "when the contract period year is changing" do
              let(:contract_period) { FactoryBot.create(:contract_period, year: training_period.contract_period.year + 1) }
              let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: contract_period_year, lead_provider:, school: training_period.school_partnership.school) }

              it "changes the schedule via change schedule service" do
                instance.change_schedule

                expect(service).to have_received(:change_schedule).once
              end
            end

            context "when the contract_period_year is not specified" do
              let(:contract_period_year) { nil }
              let(:schedule) { FactoryBot.create(:schedule, identifier: schedule_identifier, contract_period: training_period.contract_period) }

              it "uses to their current contract period year" do
                instance.change_schedule

                expect(service).to have_received(:change_schedule).once
              end
            end

            context "when moving back to a frozen contract period" do
              let(:contract_period) { FactoryBot.create(:contract_period, :with_payments_frozen, year: training_period.contract_period.year + 1) }
              let!(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: contract_period.year, lead_provider:, school: training_period.school_partnership.school) }

              before { teacher.update!("#{trainee_type}_payments_frozen_year": contract_period.year) }

              it "changes the schedule via change schedule service" do
                instance.change_schedule

                expect(service).to have_received(:change_schedule).once
              end
            end

            context "when the training period `started_on` has not yet passed" do
              let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: Time.zone.today, finished_on: 2.weeks.from_now) }
              let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :active, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on) }

              it "changes the schedule via change schedule service" do
                instance.change_schedule

                expect(service).to have_received(:change_schedule).once
              end
            end
          end
        end
      end
    end
  end
end
