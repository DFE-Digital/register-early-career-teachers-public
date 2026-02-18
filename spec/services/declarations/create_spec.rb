RSpec.describe Declarations::Create do
  let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
  let(:lead_provider) { training_period.lead_provider }
  let(:teacher) { training_period.teacher }
  let(:declaration_type) { "started" }
  let(:evidence_type) { "training-event-attended" }
  let(:schedule) { training_period.schedule }
  let!(:milestone) { FactoryBot.create(:milestone, declaration_type:, schedule:) }
  let(:declaration_datetime) { Faker::Time.between(from: milestone.start_date, to: milestone.milestone_date) }
  let(:declaration_date) { declaration_datetime.iso8601 }
  let(:contract_period) { training_period.contract_period }
  let(:active_lead_provider) { training_period.active_lead_provider }
  let(:delivery_partner) { training_period.delivery_partner }
  let(:payment_statement) { FactoryBot.create(:statement, :open, active_lead_provider:) }

  let(:service) do
    described_class.new(
      author:,
      lead_provider:,
      teacher:,
      training_period:,
      declaration_date:,
      declaration_type:,
      evidence_type:,
      payment_statement:,
      mentorship_period:,
      delivery_partner:
    )
  end

  describe "#create" do
    subject(:create_declaration) { service.create }

    %i[ect mentor].each do |trainee_type|
      context "for #{trainee_type}" do
        let(:teacher_type) { trainee_type }
        let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 2.weeks.from_now) }
        let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :active, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on) }
        let!(:mentorship_period) do
          if trainee_type == :ect
            mentor = FactoryBot.create(
              :mentor_at_school_period,
              school: at_school_period.school,
              started_on: at_school_period.started_on,
              finished_on: at_school_period.finished_on
            )

            FactoryBot.create(
              :mentorship_period,
              mentee: at_school_period,
              mentor:,
              started_on: at_school_period.started_on,
              finished_on: at_school_period.finished_on
            )
          end
        end

        it "creates a new declaration with correct attributes" do
          declaration = nil
          expect { declaration = create_declaration }.to change(Declaration, :count).by(1)

          expect(declaration.payment_statement).to be_nil
          if trainee_type == :ect
            expect(declaration.mentorship_period).to eq(mentorship_period)
          end
          expect(declaration.evidence_type).to eq(evidence_type)
          expect(declaration).not_to be_payment_status_eligible
        end

        context "when pupil premium and sparsity uplifts are set on the teacher" do
          before { teacher.update!(ect_pupil_premium_uplift: true, ect_sparsity_uplift: true) }

          it "sets pupil premium and sparsity uplifts on the declaration" do
            declaration = create_declaration

            expect(declaration.reload.pupil_premium_uplift).to be(true)
            expect(declaration.reload.sparsity_uplift).to be(true)
          end

          context "when the declaration type is not started" do
            let(:declaration_type) { "completed" }

            it "does not set pupil premium and sparsity uplifts on the declaration" do
              allow(Declarations::MentorCompletion).to receive(:new) { instance_double(Declarations::MentorCompletion, perform: nil) }

              declaration = create_declaration

              expect(declaration.reload.pupil_premium_uplift).to be(false)
              expect(declaration.reload.sparsity_uplift).to be(false)
            end
          end

          context "when the contract period does not have uplift fees enabled" do
            before { contract_period.update!(uplift_fees_enabled: false) }

            it "does not set pupil premium and sparsity uplifts on the declaration" do
              declaration = create_declaration

              expect(declaration.reload.pupil_premium_uplift).to be(false)
              expect(declaration.reload.sparsity_uplift).to be(false)
            end
          end
        end

        it "runs mentor completion" do
          allow(Declarations::MentorCompletion).to receive(:new).and_call_original

          declaration = create_declaration

          expect(Declarations::MentorCompletion).to have_received(:new).with(author:, declaration:).once
        end

        context "when teacher is eligible for funding" do
          before do
            teacher.update!("#{trainee_type}_first_became_eligible_for_training_at": 1.year.ago)
          end

          it "marks declaration `payment_status` as eligible" do
            declaration = create_declaration

            expect(declaration).to be_payment_status_eligible
          end

          it "assigns a payment statement" do
            declaration = create_declaration

            expect(declaration.payment_statement).to eq(payment_statement)
          end
        end

        it "records a declaration created event" do
          allow(Events::Record).to receive(:record_declaration_created_event!).once.and_call_original

          declaration = create_declaration

          expect(Events::Record).to have_received(:record_declaration_created_event!).once.with(
            hash_including(
              {
                author: an_object_having_attributes(
                  class: Events::LeadProviderAPIAuthor,
                  lead_provider:
                ),
                teacher:,
                lead_provider:,
                declaration:
              }
            )
          )
        end

        context "when a duplicate declaration exists" do
          let!(:existing_declaration) { service.create }

          it "returns the existing declaration with correct attributes" do
            declaration = nil
            expect { declaration = create_declaration }.not_to change(Declaration, :count)

            expect(declaration).to eq(existing_declaration)
            expect(declaration.payment_statement).to be_nil
            if trainee_type == :ect
              expect(declaration.mentorship_period).to eq(mentorship_period)
            end
            expect(declaration.evidence_type).to eq(evidence_type)
            expect(declaration).not_to be_payment_status_eligible
          end

          it "acquires a lock on the run" do
            expect(Declaration).to receive(:with_advisory_lock).with("lock_#{training_period.id}_#{declaration_type}").and_call_original

            create_declaration
          end
        end
      end
    end
  end
end
