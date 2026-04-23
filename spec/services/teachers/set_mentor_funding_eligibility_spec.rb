RSpec.describe Teachers::SetMentorFundingEligibility do
  let(:teacher) { FactoryBot.create(:teacher, api_ect_training_record_id: SecureRandom.uuid) }
  let(:author) { Events::SystemAuthor.new }
  let(:service) { described_class.new(teacher:, author:) }

  describe "#set!" do
    context "when teacher is eligible for mentor training" do
      let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:) }
      let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:) }

      context "when `mentor_first_became_eligible_for_training_at` is not already set" do
        it "sets `mentor_first_became_eligible_for_training_at`" do
          freeze_time do
            expect { service.set! }.to change(teacher, :mentor_first_became_eligible_for_training_at).from(nil).to(Time.zone.now)
          end
        end
      end

      context "when `mentor_first_became_eligible_for_training_at` is already set" do
        before do
          teacher.update!(mentor_first_became_eligible_for_training_at: 1.day.ago)
        end

        it "does not change `mentor_first_became_eligible_for_training_at`" do
          expect { service.set! }.not_to change(teacher, :mentor_first_became_eligible_for_training_at)
        end
      end

      context "with no-payment and eligible mentor declarations" do
        let!(:no_payment_declaration) { FactoryBot.create(:declaration, training_period:, declaration_type: "started") }
        let!(:eligible_declaration) { FactoryBot.create(:declaration, :payable, training_period:, declaration_type: "completed") }

        it "only passes no_payment declarations to MarkDeclarationsEligible" do
          mark_declarations = instance_double(Declarations::Actions::MarkDeclarationsEligible, mark: true)
          allow(Declarations::Actions::MarkDeclarationsEligible).to receive(:new).and_return(mark_declarations)

          service.set!

          expect(Declarations::Actions::MarkDeclarationsEligible).to have_received(:new)
            .with(declarations: [no_payment_declaration], author:)
        end
      end
    end

    context "when teacher is not eligible for mentor training" do
      before do
        teacher.update!(mentor_became_ineligible_for_funding_on: Time.zone.now, mentor_became_ineligible_for_funding_reason: "completed_declaration_received")
      end

      it "does not set mentor_first_became_eligible_for_training_at" do
        expect { service.set! }.not_to change(teacher, :mentor_first_became_eligible_for_training_at)
      end

      it "does not call `Declarations::Actions::MarkDeclarationsEligible` service" do
        expect(Declarations::Actions::MarkDeclarationsEligible).not_to receive(:new)

        service.set!
      end
    end

    context "when teacher has no mentor training period" do
      it "does not set mentor_first_became_eligible_for_training_at" do
        expect { service.set! }.not_to change(teacher, :mentor_first_became_eligible_for_training_at)
      end

      it "does not call `Declarations::Actions::MarkDeclarationsEligible` service" do
        expect(Declarations::Actions::MarkDeclarationsEligible).not_to receive(:new)

        service.set!
      end

      context "when the teacher has a mentor at school period but no training period" do
        before do
          FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:)
        end

        it "does not set mentor_first_became_eligible_for_training_at" do
          expect { service.set! }.not_to change(teacher, :mentor_first_became_eligible_for_training_at)
        end
      end

      context "when the teacher also has an ongoing induction period and an ECT at school period" do
        before do
          FactoryBot.create(:induction_period, :ongoing, teacher:)
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher:)
        end

        it "does not set mentor_first_became_eligible_for_training_at" do
          expect { service.set! }.not_to change(teacher, :mentor_first_became_eligible_for_training_at)
        end
      end
    end

    context "does not touch ECT eligibility" do
      before do
        FactoryBot.create(:induction_period, :ongoing, teacher:)
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher:)
        mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:)
        FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:)
      end

      it "does not set `ect_first_became_eligible_for_training_at`" do
        expect { service.set! }.not_to change(teacher, :ect_first_became_eligible_for_training_at)
      end
    end

    context "when teacher attributes are changed" do
      it "records a teacher set funding eligibility event" do
        freeze_time do
          mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:)
          FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:)

          expect(Events::Record).to receive(:record_teacher_set_funding_eligibility_event!)
            .with(author:,
                  teacher:,
                  teacher_type: "Mentor",
                  happened_at: Time.zone.now,
                  modifications: hash_including("mentor_first_became_eligible_for_training_at" => [nil, Time.zone.now]))

          service.set!
        end
      end
    end

    context "when teacher attributes are not changed" do
      before do
        teacher.update!(mentor_first_became_eligible_for_training_at: Time.zone.now)
      end

      it "does not record a teacher set funding eligibility event" do
        expect(Events::Record).not_to receive(:record_teacher_set_funding_eligibility_event!)

        service.set!
      end
    end

    context "when an error is raised during the eligibility setting" do
      it "rolls back any changes" do
        mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:)
        FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:)
        original_mentor_eligible_at = teacher.mentor_first_became_eligible_for_training_at

        allow(teacher).to receive(:touch).and_raise(ActiveRecord::RecordInvalid)

        expect { service.set! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(teacher.reload.mentor_first_became_eligible_for_training_at).to eq(original_mentor_eligible_at)
      end
    end
  end
end
