RSpec.describe API::Declarations::Create, type: :model do
  subject(:instance) do
    described_class.new(
      lead_provider_id:,
      teacher_api_id:,
      teacher_type:,
      declaration_date:,
      declaration_type:,
      evidence_type:
    )
  end

  let(:lead_provider) { training_period.lead_provider }
  let(:teacher) { training_period.trainee.teacher }
  let(:school_partnership) { training_period.school_partnership }
  let(:contract_period) { training_period.contract_period }
  let!(:declaration_type) { "started" }
  let(:evidence_type) { "training-event-attended" }
  let(:schedule) { training_period.schedule }
  let!(:milestone) { FactoryBot.create(:milestone, declaration_type:, schedule:, start_date: Date.new(2024, 11, 1), milestone_date: Date.new(2024, 12, 1)) }
  let(:declaration_datetime) { Faker::Time.between(from: milestone.start_date, to: milestone.milestone_date) }
  let(:declaration_date) { declaration_datetime.rfc3339 }

  it_behaves_like "an API teacher shared action" do
    describe "validations" do
      %i[ect mentor].each do |trainee_type|
        context "for #{trainee_type}" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 2.months.from_now) }
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :active, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: 1.week.from_now) }
          let(:teacher_type) { trainee_type }

          it { is_expected.to be_valid }

          context "when `declaration_date` is nil" do
            let!(:declaration_date) { nil }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:declaration_date, "Enter a '#/declaration_date'.") }
          end

          context "when `declaration_date` is in the future" do
            let!(:declaration_date) { 1.day.from_now.rfc3339 }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:declaration_date, "The '#/declaration_date' value cannot be a future date. Check the date and try again.") }
          end

          context "when `declaration_date` is not in the correct format" do
            let!(:declaration_date) { declaration_datetime.to_s }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:declaration_date, "Enter a valid RCF3339 '#/declaration_date'.") }
          end

          context "when `declaration_type` is nil" do
            let!(:milestone) { FactoryBot.create(:milestone, declaration_type: "started", schedule:) }
            let!(:declaration_type) { nil }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:declaration_type, "Enter a '#/declaration_type'.") }
          end

          context "when `evidence_type` is invalid for the given `declaration_type`" do
            let!(:evidence_type) { "75-percent-engagement-met" }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:evidence_type, "Enter an available '#/evidence_type' type for this participant.") }
          end

          context "when milestone does not exist" do
            before do
              milestone.destroy!
            end

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:declaration_type, "The property '#/declaration_type' does not exist for this schedule.") }
          end

          context "when teacher is withdrawn" do
            let(:withdrawn_at) { declaration_datetime - 1.second }

            before do
              training_period.update!(withdrawn_at:, withdrawal_reason: "other")
            end

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "This participant withdrew from this course on #{withdrawn_at.rfc3339}. Enter a '#/declaration_date' that's on or before the withdrawal date.") }
          end

          if trainee_type == :mentor
            context "when declaration type is not started or completed" do
              let!(:declaration_type) { "retained-1" }

              it { is_expected.to have_one_error_per_attribute }
              it { is_expected.to have_error(:declaration_type, "You cannot send retained or extended declarations for participants who began their mentor training after June 2025. Resubmit this declaration with either a started or completed declaration.") }
            end
          end

          context "when no payment statement exists" do
            before do
              teacher.update!("#{trainee_type}_first_became_eligible_for_training_at": 3.years.ago)
            end

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:contract_period_year, "You cannot submit or void declarations for the #{contract_period.year} cohort. The funding contract for this cohort has ended. Get in touch if you need to discuss this with us.") }
          end

          context "when a declaration already exists" do
            %w[no_payment eligible payable paid].each do |payment_status|
              context "with payment status `#{payment_status}`" do
                let!(:existing_declaration) do
                  FactoryBot.create(:declaration,
                                    payment_status.to_sym,
                                    declaration_type:,
                                    declaration_date:,
                                    evidence_type:,
                                    training_period:)
                end

                it { is_expected.to have_one_error_per_attribute }
                it { is_expected.to have_error(:base, "A declaration has already been submitted that will be, or has been, paid for this event.") }
              end
            end
          end
        end
      end
    end

    describe "#create" do
      subject(:create_declaration) { service.create }

      %i[ect mentor].each do |trainee_type|
        context "for #{trainee_type}" do
          let(:teacher_type) { trainee_type }

          context "when invalid" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing) }
            let(:teacher_api_id) { SecureRandom.uuid }

            it { expect(instance.create).to be(false) }
            it { expect { instance.create }.not_to(change(Declaration, :count)) }
          end

          context "when valid" do
            let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 2.weeks.from_now) }
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :active, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on) }
            let(:service) { instance_double(Declarations::Create) }

            before do
              author = an_instance_of(Events::LeadProviderAPIAuthor)
              allow(Declarations::Create).to receive(:new).with(author:,
                                                                lead_provider:,
                                                                teacher:,
                                                                training_period:,
                                                                declaration_date:,
                                                                declaration_type:,
                                                                evidence_type:).and_return(service)
              allow(service).to receive(:create)
            end

            it "creates a new declaration via declarations create service" do
              create_declaration

              expect(service).to have_received(:create).once
            end
          end
        end
      end
    end
  end
end
