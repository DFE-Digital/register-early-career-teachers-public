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
  let(:teacher) { training_period.trainee.teacher }
  let(:school_partnership) { training_period.school_partnership }
  let(:contract_period) { training_period.contract_period }
  let(:contract_period_year) { contract_period.year }
  let!(:schedule) { FactoryBot.create(:schedule, identifier: schedule_identifier, contract_period_year: contract_period.year) }
  let(:schedule_identifier) { training_period.for_ect? ? "ecf-standard-april" : "ecf-replacement-september" }

  it_behaves_like "an API teacher shared action" do
    describe "validations" do
      %i[ect mentor].each do |trainee_type|
        context "for #{trainee_type}" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 2.weeks.from_now) }
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :active, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on) }
          let(:teacher_type) { trainee_type }

          it { is_expected.to be_valid }

          it { is_expected.to validate_presence_of(:contract_period_year).with_message("Enter a '#/contract_period_year'.") }
          it { is_expected.to validate_presence_of(:schedule_identifier).with_message("The property '#/schedule_identifier' must be present and correspond to a valid schedule.") }

          context "when contract_period does not exist" do
            let(:contract_period_year) { 2030 }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:contract_period_year, "The '#/contract_period_year' you have entered is invalid. Check contract period details and try again.") }
          end

          context "when schedule does not exist" do
            before do
              schedule_identifier
              schedule.destroy!
            end

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:schedule_identifier, "The property '#/schedule_identifier' must be present and correspond to a valid schedule") }
          end

          context "when training_period is withdrawn" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :withdrawn, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "Cannot perform actions on a withdrawn participant") }
          end

          context "when changing to the same schedule" do
            let!(:schedule) { training_period.schedule }
            let(:schedule_identifier) { schedule.identifier }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:schedule_identifier, "The '#/schedule_identifier' is already on the profile") }
          end

          context "when changing to wrong teacher type schedule" do
            let(:schedule_identifier) { training_period.for_ect? ? "ecf-replacement-september" : "ecf-standard-april" }
            let!(:schedule) { FactoryBot.create(:schedule, identifier: schedule_identifier, contract_period_year: contract_period.year) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:schedule_identifier, "The '#/schedule_identifier' is not valid for '#/teacher_type'") }
          end

          context "when changing contract_period_year without a school partnership" do
            let(:contract_period_year) { Time.zone.today.year + 3 }

            before do
              FactoryBot.create(:contract_period, year: contract_period_year)
              FactoryBot.create(:schedule, identifier: schedule_identifier, contract_period_year:)
            end

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:contract_period_year, "You cannot change a participant to this '#/contract_period_year' as you do not have a partnership with the school for the cohort. Contact the DfE for assistance.") }
          end

          context "when lead provider does not belong to the latest training period" do
            let(:another_lead_provider) { FactoryBot.create(:lead_provider) }
            let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider: another_lead_provider, contract_period:) }
            let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
            let!(:new_school_partnership) { FactoryBot.create(:school_partnership, school: at_school_period.school, lead_provider_delivery_partnership:) }

            before do
              training_period.update!(finished_on: Time.zone.today)
              opts = {
                started_on: Time.zone.today,
                school_partnership: new_school_partnership,
                schedule:
              }
              if training_period.for_ect?
                FactoryBot.create(:training_period, :for_ect, **opts, ect_at_school_period: training_period.trainee)
              else
                FactoryBot.create(:training_period, :for_mentor, **opts, mentor_at_school_period: training_period.trainee)
              end
            end

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "Lead provider is not currently training '#/teacher_api_id'.") }
          end

          context "guarded error messages" do
            subject(:instance) { described_class.new }

            it { is_expected.to have_one_error_per_attribute }
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

            it "changes the schedule via change schedule service" do
              change_schedule_service = double("Teachers::ChangeSchedule")

              allow(Teachers::ChangeSchedule).to receive(:new).with(lead_provider:, teacher:, training_period:, schedule:, school_partnership:).and_return(change_schedule_service)
              allow(change_schedule_service).to receive(:change_schedule)

              instance.change_schedule

              expect(change_schedule_service).to have_received(:change_schedule).once
            end
          end
        end
      end
    end
  end
end
