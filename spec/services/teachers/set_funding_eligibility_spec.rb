RSpec.describe Teachers::SetFundingEligibility do
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:author) { Events::SystemAuthor.new }
  let(:service) { described_class.new(teacher:, author:) }

  describe "#set!" do
    context "when teacher is eligible for ECT training" do
      before do
        FactoryBot.create(:induction_period, :ongoing, teacher:)
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher:)
      end

      it "sets `first_became_eligible_for_ect_training_at` if not already set" do
        freeze_time do
          expect { service.set! }.to change(teacher, :first_became_eligible_for_ect_training_at).from(nil).to(Time.zone.now)
        end
      end

      it "does not change `first_became_eligible_for_ect_training_at` if already set" do
        teacher.update!(first_became_eligible_for_ect_training_at: 1.day.ago)

        expect { service.set! }.not_to change(teacher, :first_became_eligible_for_ect_training_at)
      end
    end

    context "when teacher is not eligible for ECT training" do
      it "does not set `first_became_eligible_for_ect_training_at`" do
        expect { service.set! }.not_to change(teacher, :first_became_eligible_for_ect_training_at)
      end
    end

    context "when teacher is eligible for mentor training" do
      it "sets first_became_eligible_for_mentor_training_at if not already set" do
        freeze_time do
          expect { service.set! }.to change(teacher, :first_became_eligible_for_mentor_training_at).from(nil).to(Time.zone.now)
        end
      end

      it "does not `change first_became_eligible_for_mentor_training_at` if already set" do
        teacher.update!(first_became_eligible_for_mentor_training_at: 1.day.ago)

        expect { service.set! }.not_to change(teacher, :first_became_eligible_for_mentor_training_at)
      end
    end

    context "when teacher is not eligible for mentor training" do
      before do
        teacher.update!(mentor_became_ineligible_for_funding_on: Time.zone.now, mentor_became_ineligible_for_funding_reason: "completed_declaration_received")
      end

      it "does not set first_became_eligible_for_mentor_training_at" do
        expect { service.set! }.not_to change(teacher, :first_became_eligible_for_mentor_training_at)
      end
    end

    context "when teacher attributes are changed" do
      it "records a teacher set funding eligibility event" do
        freeze_time do
          expect(Events::Record).to receive(:record_teacher_set_funding_eligibility_event!)
            .with(author:,
                  teacher:,
                  happened_at: Time.zone.now,
                  modifications: { "first_became_eligible_for_mentor_training_at" => [nil, Time.zone.now] })

          service.set!
        end
      end
    end

    context "when teacher attributes are not changed" do
      before do
        teacher.update!(first_became_eligible_for_ect_training_at: Time.zone.now, first_became_eligible_for_mentor_training_at: Time.zone.now)
      end

      it "does not record a teacher set funding eligibility event" do
        expect(Events::Record).not_to receive(:record_teacher_set_funding_eligibility_event!)

        service.set!
      end
    end

    context "when an error is raised during the eligibility setting" do
      before do
        allow(teacher).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "rolls back any changes" do
        original_ect_eligible_at = teacher.first_became_eligible_for_ect_training_at
        original_mentor_eligible_at = teacher.first_became_eligible_for_mentor_training_at

        FactoryBot.create(:induction_period, :ongoing, teacher:)
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher:)

        expect { service.set! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(teacher.reload.first_became_eligible_for_ect_training_at).to eq(original_ect_eligible_at)
        expect(teacher.reload.first_became_eligible_for_mentor_training_at).to eq(original_mentor_eligible_at)
      end
    end
  end
end
