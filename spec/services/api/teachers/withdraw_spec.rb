RSpec.describe API::Teachers::Withdraw, type: :model do
  subject(:instance) do
    described_class.new(
      lead_provider_id:,
      teacher_api_id:,
      reason:,
      teacher_type:
    )
  end

  let(:reason) { described_class::WITHDRAWAL_REASONS.sample }

  it_behaves_like "an API teacher shared action" do
    describe "validations" do
      API::Concerns::Teachers::SharedAction::TEACHER_TYPES.each do |trainee_type|
        context "for #{trainee_type}" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 2.months.ago) }
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }
          let(:teacher_type) { trainee_type }

          it { is_expected.to be_valid }

          context "when reason is invalid" do
            let(:reason) { "does-not-exist" }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:reason, "The entered '#/reason' is not recognised for the given participant. Check details and try again.") }
          end

          context "when reason values are dashed" do
            described_class::WITHDRAWAL_REASONS.each do |reason_val|
              let(:reason) { reason_val }

              it "is valid when reason is '#{reason_val}'" do
                expect(instance).to be_valid
              end
            end
          end

          context "when reason is underscored" do
            let(:reason) { "long_term_sickness" }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:reason, "The entered '#/reason' is not recognised for the given participant. Check details and try again.") }
          end

          context "when teacher already withdrawn" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :withdrawn, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "The '#/teacher_api_id' is already withdrawn.") }
          end

          context "when training not started yet" do
            let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 3.months.from_now) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "You cannot withdraw #/teacher_api_id. This is because they have not been training with you for at least one day.") }
          end

          context "when training started today" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", "#{trainee_type}_at_school_period": at_school_period, started_on: Time.zone.today) }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "You cannot withdraw #/teacher_api_id. This is because they have not been training with you for at least one day.") }

            context "when an earlier training period exists for the lead provider" do
              let!(:previous_training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", "#{trainee_type}_at_school_period": at_school_period, school_partnership: training_period.school_partnership, started_on: 3.days.ago, finished_on: 1.day.ago) }

              it { is_expected.to be_valid }
            end
          end

          context "guarded error messages" do
            subject(:instance) { described_class.new }

            it { is_expected.to have_one_error_per_attribute }
          end
        end
      end
    end

    shared_context "withdraws the teacher" do
      it "returns teacher" do
        expect(subject.withdraw).to eq(teacher)
      end

      it "withdraws the training period via withdraw service" do
        withdraw_service = double("Teachers::Withdraw")
        author = an_instance_of(Events::LeadProviderAPIAuthor)

        allow(Teachers::Withdraw).to receive(:new).with(author:, lead_provider:, reason:, teacher:, training_period:).and_return(withdraw_service)
        allow(withdraw_service).to receive(:withdraw)

        instance.withdraw

        expect(withdraw_service).to have_received(:withdraw).once
      end
    end

    describe "#withdraw" do
      API::Concerns::Teachers::SharedAction::TEACHER_TYPES.each do |trainee_type|
        context "for #{trainee_type}" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: nil) }
          let(:teacher_type) { trainee_type }

          context "when invalid" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing) }
            let(:teacher_api_id) { SecureRandom.uuid }

            it { expect(instance.withdraw).to be(false) }
            it { expect { instance.withdraw }.not_to(change { training_period.reload.attributes }) }
          end

          context "when valid" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

            include_context "withdraws the teacher"

            context "when the training period is deferred deferred" do
              let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :deferred, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

              include_context "withdraws the teacher"
            end
          end
        end
      end
    end
  end
end
