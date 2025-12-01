RSpec.describe API::Teachers::Resume, type: :model do
  subject(:instance) do
    described_class.new(
      lead_provider_id:,
      teacher_api_id:,
      teacher_type:
    )
  end

  it_behaves_like "an API teacher shared action" do
    describe "validations" do
      %i[ect mentor].each do |trainee_type|
        context "for #{trainee_type}" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 2.weeks.from_now) }
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :deferred, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on) }
          let(:teacher_type) { trainee_type }

          it { is_expected.to be_valid }

          context "when teacher training period is active/ongoing" do
            let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", :ongoing, started_on: 2.months.ago) }
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "The '#/teacher_api_id' is already active.") }
          end

          context "when there is another active/ongoing training period for the school period at a different lead provider" do
            let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", :ongoing, started_on: 2.months.ago) }
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :deferred, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: 1.month.ago) }
            let!(:other_training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: 2.weeks.ago) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "This participant cannot be resumed because they are already active with another provider.") }
          end

          context "when there is another active/ongoing training period that finishes in the future for the school period at a different lead provider" do
            let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", :ongoing, started_on: 2.months.ago) }
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :deferred, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: 1.month.ago) }
            let!(:other_training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: 2.weeks.ago, finished_on: 3.months.from_now) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "This participant cannot be resumed because they are already active with another provider.") }

            context "when resuming after the other active/ongoing training period has finished" do
              before { travel_to 3.months.from_now }

              it { is_expected.to be_valid }
            end
          end

          context "when at school period is finished" do
            let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", :ongoing, started_on: 2.months.ago, finished_on: 1.month.ago) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "The participant is no longer at the school. Please contact the induction tutor to resolve.") }
          end

          context "when the school period finishes today" do
            let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", :ongoing, started_on: 2.months.ago, finished_on: Date.current) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "The participant is no longer at the school. Please contact the induction tutor to resolve.") }
          end

          context "when the school period finishes tomorrow" do
            let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", :ongoing, started_on: 2.months.ago, finished_on: Date.tomorrow) }

            it { is_expected.to be_valid }
          end

          context "guarded error messages" do
            subject(:instance) { described_class.new }

            it { is_expected.to have_one_error_per_attribute }
          end
        end
      end
    end

    describe "#resume" do
      %i[ect mentor].each do |trainee_type|
        context "for #{trainee_type}" do
          let(:teacher_type) { trainee_type }

          context "when invalid" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing) }
            let(:teacher_api_id) { SecureRandom.uuid }

            it { expect(instance.resume).to be(false) }
            it { expect { instance.resume }.not_to(change { training_period.reload.attributes }) }
          end

          context "when valid" do
            let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 2.weeks.from_now) }
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :deferred, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on) }

            it "resumes the training period via resume service" do
              resume_service = double("Teachers::Resume")
              author = an_instance_of(Events::LeadProviderAPIAuthor)

              allow(Teachers::Resume).to receive(:new).with(author:, lead_provider:, teacher:, training_period:).and_return(resume_service)
              allow(resume_service).to receive(:resume)

              instance.resume

              expect(resume_service).to have_received(:resume).once
            end
          end
        end
      end
    end
  end
end
