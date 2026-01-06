RSpec.describe Declarations::MentorCompletion, :with_metadata do
  let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, started_on: 1.month.ago, finished_on: nil) }
  let(:training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:, started_on: 1.month.ago, finished_on: nil) }

  let(:service) do
    described_class.new(
      author:,
      declaration:
    )
  end

  describe "#perform" do
    context "when declaration is billable or changeable" do
      context "when mentor training is completed" do
        before do
          # Voided declaration with a later declaration_date should be ignored.
          FactoryBot.create(:declaration, :voided, declaration_type: "completed", training_period:, declaration_date: 1.week.ago)
        end

        let(:declaration) { FactoryBot.create(:declaration, :eligible, declaration_type: "completed", training_period:, declaration_date: 2.weeks.ago) }

        it "mentor is now ineligible for funding" do
          expect(teacher.mentor_became_ineligible_for_funding_on).to be_nil
          expect(teacher.mentor_became_ineligible_for_funding_reason).to be_nil

          service.perform

          expect(teacher.mentor_became_ineligible_for_funding_on).to eq(declaration.declaration_date.to_date)
          expect(teacher.mentor_became_ineligible_for_funding_reason).to eq("completed_declaration_received")
        end

        it "finishes the training period" do
          expect { service.perform }.to change { training_period.reload.finished_on }.from(nil).to(declaration.declaration_date.to_date)
        end

        context "when the declaration_date is before the training period started_on date" do
          let(:declaration) { FactoryBot.create(:declaration, :eligible, declaration_type: "completed", training_period:, declaration_date: 2.months.ago) }

          it "sets finished_on to the day after started_on" do
            expect { service.perform }.to change { training_period.reload.finished_on }.from(nil).to(training_period.started_on + 1.day)
          end
        end

        it "records a mentor completion status change event" do
          expect(Events::Record).to receive(:record_mentor_completion_status_change!).with(
            author:,
            teacher:,
            training_period:,
            declaration:,
            modifications: hash_including(
              mentor_became_ineligible_for_funding_on: [nil, declaration.declaration_date.to_date],
              mentor_became_ineligible_for_funding_reason: [nil, "completed_declaration_received"]
            )
          )

          service.perform
        end
      end

      context "when completed mentor training is voided" do
        let!(:teacher) { FactoryBot.create(:teacher, :ineligible_for_mentor_funding) }
        let!(:declaration) { FactoryBot.create(:declaration, :voided, declaration_type: "completed", training_period:) }

        it "mentor is now eligible for funding" do
          expect(teacher.mentor_became_ineligible_for_funding_on).to be_present
          expect(teacher.mentor_became_ineligible_for_funding_reason).to be_present

          service.perform

          expect(teacher.mentor_became_ineligible_for_funding_on).to be_nil
          expect(teacher.mentor_became_ineligible_for_funding_reason).to be_nil
        end

        it "does not create a new training period if there is one already ongoing for the lead provider" do
          expect { service.perform }.not_to change(TrainingPeriod, :count)
        end

        context "when there is no training period ongoing today for the lead provider" do
          before { training_period.update!(finished_on: 1.day.ago) }

          it "creates a new training period, starting the day the previous one finished" do
            expect { service.perform }.to change(TrainingPeriod, :count).by(1)

            new_training_period = TrainingPeriod.last
            expect(new_training_period.mentor_at_school_period).to eq(mentor_at_school_period)
            expect(new_training_period.started_on).to eq(training_period.finished_on)
            expect(new_training_period.school_partnership).to eq(training_period.school_partnership)
            expect(new_training_period.schedule).to eq(training_period.schedule)
            expect(new_training_period.expression_of_interest).to be_nil
          end
        end

        it "records a mentor completion status change event" do
          expect(Events::Record).to receive(:record_mentor_completion_status_change!).with(
            author:,
            teacher:,
            training_period:,
            declaration:,
            modifications: hash_including(
              mentor_became_ineligible_for_funding_on: [teacher.mentor_became_ineligible_for_funding_on, nil],
              mentor_became_ineligible_for_funding_reason: [teacher.mentor_became_ineligible_for_funding_reason, nil]
            )
          )

          service.perform
        end
      end
    end

    context "when declaration is not completed" do
      let(:declaration) { FactoryBot.create(:declaration, :eligible, declaration_type: "started") }

      it "returns false without action" do
        expect(Events::Record).not_to receive(:record_mentor_completion_status_change!)
        expect(service.perform).to be(false)
      end
    end

    context "when teacher type is ECT" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }
      let(:training_period) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }
      let(:declaration) { FactoryBot.create(:declaration, :eligible, declaration_type: "completed", training_period:) }

      it "returns false without action" do
        expect(Events::Record).not_to receive(:record_mentor_completion_status_change!)
        expect(service.perform).to be(false)
      end
    end
  end
end
