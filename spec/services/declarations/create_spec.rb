RSpec.describe Declarations::Create do
  let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
  let(:lead_provider) { training_period.lead_provider }
  let(:teacher) { training_period.trainee.teacher }
  let!(:declaration_type) { "started" }
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

        context "when there's no existing declaration" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 2.weeks.from_now) }
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :active, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on) }
          let!(:mentorship_period) do
            if trainee_type == :ect
              mentor = FactoryBot.create(:mentor_at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on)
              FactoryBot.create(:mentorship_period, mentee: at_school_period, mentor:, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on)
            end
          end

          it "creates a new declaration" do
            expect { create_declaration }.to change(Declaration, :count).by(1)
          end

          it "does not assign a payment statement" do
            expect(create_declaration.payment_statement).to be_nil
          end

          if trainee_type == :ect
            it "assigns a mentorship period" do
              expect(create_declaration.mentorship_period).to eq(mentorship_period)
            end
          end

          it "runs mentor completion" do
            allow(Declarations::MentorCompletion).to receive(:new).and_call_original

            declaration = create_declaration

            expect(Declarations::MentorCompletion).to have_received(:new).with(author:, declaration:).once
          end

          it "sets the evidence type" do
            expect(create_declaration.evidence_type).to eq(evidence_type)
          end

          context "when teacher is eligible for funding" do
            before do
              teacher.update!("#{trainee_type}_first_became_eligible_for_training_at": 1.year.ago)
            end

            it "marks declaration `payment_status` as eligible" do
              declaration = create_declaration

              expect(declaration.payment_status_eligible?).to be(true)
            end

            it "assigns a payment statement" do
              declaration = create_declaration

              expect(declaration.payment_statement).to eq(payment_statement)
            end
          end

          context "when teacher is not eligible for funding" do
            it "does not mark declaration `payment_status` as eligible" do
              declaration = create_declaration

              expect(declaration.payment_status_eligible?).to be(false)
            end

            it "does not assign a payment statement" do
              declaration = create_declaration

              expect(declaration.payment_statement).to be_nil
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
        end

        context "when an existing declaration exists" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago, finished_on: 2.weeks.from_now) }
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :active, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on) }
          let(:mentorship_period) do
            if trainee_type == :ect
              mentor = FactoryBot.create(:mentor_at_school_period, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on)
              FactoryBot.create(:mentorship_period, mentee: at_school_period, mentor:, started_on: at_school_period.started_on, finished_on: at_school_period.finished_on)
            end
          end

          let!(:existing_declaration) do
            FactoryBot.create(:declaration, :no_payment, training_period:, declaration_type:, declaration_date:, evidence_type:, mentorship_period:)
          end

          it "does not create a new declaration" do
            expect { create_declaration }.not_to change(Declaration, :count)
          end

          it "returns the existing declaration" do
            expect(create_declaration).to eq(existing_declaration)
          end

          it "does not assign a payment statement" do
            expect(create_declaration.payment_statement).to be_nil
          end

          if trainee_type == :ect
            it "updates the existing declaration's pupil premium and sparsity uplifts" do
              expect(existing_declaration.pupil_premium_uplift).to be(false)
              expect(existing_declaration.sparsity_uplift).to be(false)

              teacher.update!("#{trainee_type}_pupil_premium_uplift": true, "#{trainee_type}_sparsity_uplift": true)

              create_declaration

              expect(existing_declaration.reload.pupil_premium_uplift).to be(true)
              expect(existing_declaration.reload.sparsity_uplift).to be(true)
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

              expect(declaration.payment_status_eligible?).to be(true)
            end

            it "assigns a payment statement" do
              declaration = create_declaration

              expect(declaration.payment_statement).to eq(payment_statement)
            end
          end

          context "when teacher is not eligible for funding" do
            it "does not mark declaration `payment_status` as eligible" do
              declaration = create_declaration

              expect(declaration.payment_status_eligible?).to be(false)
            end

            it "does not assign a payment statement" do
              declaration = create_declaration

              expect(declaration.payment_statement).to be_nil
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
        end
      end
    end
  end
end
