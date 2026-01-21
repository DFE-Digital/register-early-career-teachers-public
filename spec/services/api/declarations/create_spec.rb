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
  let(:lead_provider_id) { lead_provider.id }
  let(:teacher) { training_period.teacher }
  let(:teacher_api_id) { teacher.api_id }
  let(:school_partnership) { training_period.school_partnership }
  let(:contract_period) { training_period.contract_period }
  let(:declaration_type) { "started" }
  let(:evidence_type) { "training-event-attended" }
  let(:schedule) { training_period.schedule }
  let!(:milestone) { FactoryBot.create(:milestone, declaration_type:, schedule:, start_date: Date.new(2024, 11, 1), milestone_date: Date.new(2024, 12, 1)) }
  let(:declaration_datetime) { Faker::Time.between(from: milestone.start_date, to: milestone.milestone_date) }
  let(:declaration_date) { declaration_datetime.rfc3339 }
  let(:active_lead_provider) { training_period.active_lead_provider }

  describe "validations" do
    %i[ect mentor].each do |trainee_type|
      context "for #{trainee_type}" do
        let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 2.months.from_now) }
        let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :active, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: 1.week.from_now) }
        let(:teacher_type) { trainee_type }

        it { is_expected.to be_valid }
        it { is_expected.to validate_presence_of(:lead_provider_id).with_message("Enter a '#/lead_provider_id'.") }
        it { is_expected.to validate_presence_of(:teacher_api_id).with_message("Enter a '#/teacher_api_id'.") }
        it { is_expected.to validate_inclusion_of(:teacher_type).in_array(API::Concerns::Teachers::SharedAction::TEACHER_TYPES).with_message("The entered '#/teacher_type' is not recognised for the given participant. Check details and try again.") }

        context "when the `lead_provider` does not exist" do
          let(:lead_provider_id) { 9999 }

          it { is_expected.to have_one_error_per_attribute }
          it { is_expected.to have_error(:lead_provider_id, "The '#/lead_provider_id' you have entered is invalid.") }
        end

        context "when a matching training period does not exist (different teacher type)" do
          let(:teacher_type) { trainee_type == :ect ? :mentor : :ect }

          it { is_expected.to have_one_error_per_attribute }
          it { is_expected.to have_error(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again.") }
        end

        context "when a matching training period does not exist (different lead provider)" do
          let(:lead_provider_id) { FactoryBot.create(:lead_provider, name: "Different to #{lead_provider.name}").id }

          it { is_expected.to have_one_error_per_attribute }
          it { is_expected.to have_error(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again.") }
        end

        context "when the teacher does not exist" do
          let(:teacher_api_id) { "non-existent-participant-id" }

          it { is_expected.to have_one_error_per_attribute }
          it { is_expected.to have_error(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check participant details and try again.") }
        end

        context "when a non-existent teacher type is provided" do
          let(:teacher_type) { :other }

          it { is_expected.to have_one_error_per_attribute }
          it { is_expected.to have_error(:teacher_type, "The entered '#/teacher_type' is not recognised for the given participant. Check details and try again.") }
        end

        context "when an empty teacher type is provided" do
          let(:teacher_type) { "" }

          it { is_expected.to have_error(:teacher_type, "Enter a '#/teacher_type'.") }
        end

        context "when a nil teacher type is provided" do
          let(:teacher_type) { nil }

          it { is_expected.to have_error(:teacher_type, "Enter a '#/teacher_type'.") }
        end

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

        context "when declaration date does not match the milestone start date" do
          let(:declaration_date) { Date.new(2024, 10, 25).rfc3339 }

          it { is_expected.to have_one_error_per_attribute }
          it { is_expected.to have_error(:declaration_date, "Declaration date must be on or after the milestone start date for the same declaration type.") }
        end

        context "when declaration date does not match the milestone date" do
          let(:declaration_date) { Date.new(2024, 12, 25).rfc3339 }

          it { is_expected.to have_one_error_per_attribute }
          it { is_expected.to have_error(:declaration_date, "Declaration date must be on or before the milestone date for the same declaration type.") }
        end

        context "when teacher withdrew before the declaration date" do
          let(:withdrawn_at) { declaration_datetime - 1.second }

          before do
            training_period.update!(withdrawn_at:, withdrawal_reason: "other")
          end

          it { is_expected.to have_one_error_per_attribute }
          it { is_expected.to have_error(:teacher_api_id, "This participant withdrew from this course on #{withdrawn_at.rfc3339}. Enter a '#/declaration_date' that's on or before the withdrawal date.") }
        end

        if trainee_type == :mentor
          context "when declaration type is not started or completed" do
            let(:declaration_type) { "retained-1" }

            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:declaration_type, "You cannot send retained or extended declarations for participants who began their mentor training after June 2025. Resubmit this declaration with either a started or completed declaration.") }

            context "when contract period mentor funding is not enabled" do
              before { contract_period.update!(mentor_funding_enabled: false, detailed_evidence_types_enabled: false) }

              it { is_expected.to be_valid }
            end
          end
        end

        describe "payment statement availability validations" do
          context "when not eligible for funding" do
            before do
              teacher.update!("#{trainee_type}_first_became_eligible_for_training_at": nil)
            end

            it { is_expected.to be_valid }
          end

          context "when payment statement exists" do
            let!(:payment_statement) { FactoryBot.create(:statement, :open, active_lead_provider:) }

            it { is_expected.to be_valid }
          end

          context "when payment statement does not exist" do
            context "when the teacher is fundable" do
              before do
                teacher.update!("#{trainee_type}_first_became_eligible_for_training_at": 3.years.ago)
              end

              it { is_expected.to have_one_error_per_attribute }
              it { is_expected.to have_error(:contract_period_year, "You cannot submit or void declarations for the #{contract_period.year} contract period. The funding contract for this contract period has ended. Get in touch if you need to discuss this with us.") }
            end
          end
        end

        context "when a duplicate declaration already exists" do
          %w[no_payment eligible payable paid].each do |payment_status|
            context "with payment status `#{payment_status}`" do
              let!(:existing_duplicate_declaration) do
                FactoryBot.create(:declaration,
                                  :no_payment,
                                  declaration_date:,
                                  declaration_type:,
                                  evidence_type:,
                                  training_period:)
              end

              let!(:another_existing_declaration) do
                FactoryBot.create(:declaration,
                                  payment_status.to_sym,
                                  declaration_type:)
              end

              it { is_expected.to have_one_error_per_attribute }
              it { is_expected.to have_error(:declaration_type, "A declaration has already been submitted that will be, or has been, paid for this event.") }
            end
          end
        end

        context "validate declaration types are in sequence order" do
          let(:school_partnership) do
            FactoryBot.create(
              :school_partnership,
              :for_year,
              year: contract_period_year,
              school: at_school_period.school
            )
          end
          let!(:training_period) do
            FactoryBot.create(
              :training_period,
              :"for_#{trainee_type}",
              :active,
              "#{trainee_type}_at_school_period": at_school_period,
              school_partnership:,
              started_on: at_school_period.started_on,
              finished_on: 1.week.from_now
            )
          end

          context "when contract period is 2025" do
            let(:contract_period_year) { 2025 }

            context "when theres existing `started` declaration" do
              let!(:milestone) { FactoryBot.create(:milestone, declaration_type: "completed", schedule:, start_date: Date.new(contract_period_year, 1, 1), milestone_date: Date.new(contract_period_year, 12, 1)) }
              let!(:started_milestone) { FactoryBot.create(:milestone, declaration_type: "started", schedule:, start_date: Date.new(contract_period_year, 1, 1), milestone_date: Date.new(contract_period_year, 12, 1)) }

              # Existing `started` declaration
              let!(:started_declaration) do
                FactoryBot.create(
                  :declaration,
                  declaration_type: :started,
                  evidence_type: "training-event-attended",
                  declaration_date: (started_milestone.start_date + 1.month).rfc3339,
                  training_period:
                )
              end

              # New declaration
              let(:declaration_type) { "completed" }
              let(:evidence_type) { "75-percent-engagement-met" }

              context "when `completed` is submitted before `started` declaration date" do
                # New declaration with declaration date set 1 week before `started`
                let(:declaration_date) { (started_declaration.declaration_date - 1.week).rfc3339 }

                it { is_expected.to have_one_error_per_attribute }
                it { is_expected.to have_error(:declaration_date, "This '#/declaration_date' is invalid. Check that it is in sequence with existing declaration dates for this participant.") }
              end

              context "when `completed` is submitted after `started` declaration date" do
                # New declaration with declaration date set 2 weeks after `started`
                let(:declaration_date) { (started_declaration.declaration_date + 2.weeks).rfc3339 }

                it { is_expected.to be_valid }
              end
            end

            context "when theres existing `completed` declaration" do
              let!(:milestone) { FactoryBot.create(:milestone, declaration_type: "started", schedule:, start_date: Date.new(contract_period_year, 1, 1), milestone_date: Date.new(contract_period_year, 12, 1)) }
              let!(:completed_milestone) { FactoryBot.create(:milestone, declaration_type: "completed", schedule:, start_date: Date.new(contract_period_year, 1, 1), milestone_date: Date.new(contract_period_year, 12, 1)) }

              # Existing `completed` declaration
              let!(:completed_declaration) do
                FactoryBot.create(
                  :declaration,
                  declaration_type: :completed,
                  evidence_type: "75-percent-engagement-met",
                  declaration_date: (completed_milestone.start_date + 2.months).rfc3339,
                  training_period:
                )
              end

              # New declaration
              let(:declaration_type) { "started" }
              let(:evidence_type) { "training-event-attended" }

              context "when `started` is submitted after `completed` declaration date" do
                # New declaration with declaration date set 1 week after `completed`
                let(:declaration_date) { (completed_declaration.declaration_date + 1.week).rfc3339 }

                it { is_expected.to have_one_error_per_attribute }
                it { is_expected.to have_error(:declaration_date, "This '#/declaration_date' is invalid. Check that it is in sequence with existing declaration dates for this participant.") }
              end

              context "when `started` is submitted before `completed` declaration date" do
                # New declaration with declaration date set 2 weeks before `completed`
                let(:declaration_date) { (completed_declaration.declaration_date - 2.weeks).rfc3339 }

                it { is_expected.to be_valid }
              end
            end

            # Mentor has `started` and `completed` only, for ECT we do outside of existing declaration date test
            if trainee_type == :ect
              context "when theres existing `started` and `completed` declarations" do
                let!(:milestone) { FactoryBot.create(:milestone, declaration_type: "retained-1", schedule:, start_date: Date.new(contract_period_year, 1, 1), milestone_date: Date.new(contract_period_year, 12, 1)) }
                let!(:started_milestone) { FactoryBot.create(:milestone, declaration_type: "started", schedule:, start_date: Date.new(contract_period_year, 1, 1), milestone_date: Date.new(contract_period_year, 12, 1)) }
                let!(:completed_milestone) { FactoryBot.create(:milestone, declaration_type: "completed", schedule:, start_date: Date.new(contract_period_year, 1, 1), milestone_date: Date.new(contract_period_year, 12, 1)) }

                # Existing `started` declaration
                let!(:started_declaration) do
                  FactoryBot.create(
                    :declaration,
                    declaration_type: :started,
                    evidence_type: "training-event-attended",
                    declaration_date: Date.new(contract_period_year, 2, 1).rfc3339,
                    training_period:
                  )
                end

                # Existing `completed` declaration
                let!(:completed_declaration) do
                  FactoryBot.create(
                    :declaration,
                    declaration_type: :completed,
                    evidence_type: "75-percent-engagement-met",
                    declaration_date: Date.new(contract_period_year, 6, 1).rfc3339,
                    training_period:
                  )
                end

                let(:declaration_type) { "retained-1" }
                let(:evidence_type) { "training-event-attended" }

                context "when `retained-1` is submitted outside of `started` and `completed` declaration dates" do
                  context "when declaration date is before started" do
                    # New declaration with declaration date set 1 day before `started`
                    let(:declaration_date) { (started_declaration.declaration_date - 1.day).rfc3339 }

                    it { is_expected.to have_one_error_per_attribute }
                    it { is_expected.to have_error(:declaration_date, "This '#/declaration_date' is invalid. Check that it is in sequence with existing declaration dates for this participant.") }
                  end

                  context "when declaration date is after completed" do
                    # New declaration with declaration date set 1 day after `completed`
                    let(:declaration_date) { (completed_declaration.declaration_date + 1.day).rfc3339 }

                    it { is_expected.to have_one_error_per_attribute }
                    it { is_expected.to have_error(:declaration_date, "This '#/declaration_date' is invalid. Check that it is in sequence with existing declaration dates for this participant.") }
                  end
                end

                context "when `retained-1` is submitted within `started` and `completed` declaration dates" do
                  # New declaration with declaration date set 1 day after `started`
                  let(:declaration_date) { (started_declaration.declaration_date + 1.day).rfc3339 }

                  it { is_expected.to be_valid }
                end

                context "when `extended-1` is submitted after `completed` declaration dates" do
                  let(:declaration_type) { "extended-1" }
                  let!(:milestone) { FactoryBot.create(:milestone, declaration_type:, schedule:, start_date: Date.new(contract_period_year, 1, 1), milestone_date: Date.new(contract_period_year, 12, 1)) }

                  # New declaration with declaration date set 1 day after `completed`
                  let(:declaration_date) { (completed_declaration.declaration_date + 1.day).rfc3339 }

                  it { is_expected.to be_valid }
                end
              end
            end
          end

          context "when contract period is 2024" do
            let(:contract_period_year) { 2024 }

            context "when `completed` is submitted before `started` declaration date" do
              let!(:milestone) { FactoryBot.create(:milestone, declaration_type: "completed", schedule:, start_date: Date.new(contract_period_year, 1, 1), milestone_date: Date.new(contract_period_year, 12, 1)) }
              let!(:started_milestone) { FactoryBot.create(:milestone, declaration_type: "started", schedule:, start_date: Date.new(contract_period_year, 1, 1), milestone_date: Date.new(contract_period_year, 12, 1)) }

              # Existing `started` declaration
              let!(:started_declaration) do
                FactoryBot.create(
                  :declaration,
                  declaration_type: :started,
                  evidence_type: "training-event-attended",
                  declaration_date: Date.new(contract_period_year, 6, 1).rfc3339,
                  training_period:
                )
              end

              # New declaration with declaration date set 1 month before `started`
              let(:declaration_date) { (started_declaration.declaration_date - 1.month).rfc3339 }
              let(:declaration_type) { "completed" }
              let(:evidence_type) { "75-percent-engagement-met" }

              it { is_expected.to be_valid }
            end

            context "when `started` is submitted after `completed` declaration date" do
              let!(:milestone) { FactoryBot.create(:milestone, declaration_type: "started", schedule:, start_date: Date.new(contract_period_year, 1, 1), milestone_date: Date.new(contract_period_year, 12, 1)) }
              let!(:completed_milestone) { FactoryBot.create(:milestone, declaration_type: "completed", schedule:, start_date: Date.new(contract_period_year, 1, 1), milestone_date: Date.new(contract_period_year, 12, 1)) }

              # Existing `started` declaration
              let!(:completed_declaration) do
                FactoryBot.create(
                  :declaration,
                  declaration_type: :completed,
                  evidence_type: "75-percent-engagement-met",
                  declaration_date: Date.new(contract_period_year, 3, 1).rfc3339,
                  training_period:
                )
              end

              # New declaration with declaration date set 1 month before `completed`
              let(:declaration_date) { (completed_declaration.declaration_date + 1.month).rfc3339 }
              let(:declaration_type) { "started" }
              let(:evidence_type) { "training-event-attended" }

              it { is_expected.to be_valid }
            end
          end
        end
      end
    end
  end

  describe "#create" do
    subject(:create_declaration) { instance.create }

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
          let!(:payment_statement) { FactoryBot.create(:statement, :open, active_lead_provider:) }
          let!(:mentorship_period) do
            if trainee_type == :ect
              mentor = FactoryBot.create(
                :mentor_at_school_period,
                school: at_school_period.school,
                started_on: at_school_period.started_on,
                finished_on: at_school_period.finished_on
              )
              FactoryBot.create(:mentorship_period, mentee: at_school_period, mentor:, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on)
            end
          end
          let(:delivery_partner) { training_period.delivery_partner }

          before do
            author = an_instance_of(Events::LeadProviderAPIAuthor)
            allow(Declarations::Create).to receive(:new).with(author:,
                                                              lead_provider:,
                                                              teacher:,
                                                              training_period:,
                                                              declaration_date:,
                                                              declaration_type:,
                                                              evidence_type:,
                                                              payment_statement:,
                                                              mentorship_period:,
                                                              delivery_partner:).and_return(service)
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
