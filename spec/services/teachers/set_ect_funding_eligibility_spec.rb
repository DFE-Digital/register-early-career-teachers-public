RSpec.describe Teachers::SetECTFundingEligibility do
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:author) { Events::SystemAuthor.new }
  let(:service) { described_class.new(teacher:, author:) }

  describe "#set!" do
    context "when teacher is eligible for ECT training" do
      before do
        FactoryBot.create(:induction_period, :ongoing, teacher:)
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher:)
      end

      context "when `ect_first_became_eligible_for_training_at` is not already set" do
        it "sets `ect_first_became_eligible_for_training_at`" do
          freeze_time do
            expect { service.set! }.to change(teacher, :ect_first_became_eligible_for_training_at).from(nil).to(Time.zone.now)
          end
        end
      end

      context "when `ect_first_became_eligible_for_training_at` is already set" do
        before do
          teacher.update!(ect_first_became_eligible_for_training_at: 1.day.ago)
        end

        it "does not change `ect_first_became_eligible_for_training_at`" do
          expect { service.set! }.not_to change(teacher, :ect_first_became_eligible_for_training_at)
        end
      end

      context "with no-payment and eligible ECT declarations" do
        let(:ect_at_school_period) { teacher.ect_at_school_periods.first }
        let(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, ect_at_school_period:) }
        let!(:no_payment_declaration) { FactoryBot.create(:declaration, training_period:, declaration_type: "started") }
        let!(:eligible_declaration) { FactoryBot.create(:declaration, :payable, training_period:, declaration_type: "retained-1") }

        it "only passes no_payment declarations to MarkDeclarationsEligible" do
          mark_declarations = instance_double(Declarations::Actions::MarkDeclarationsEligible, mark: true)
          allow(Declarations::Actions::MarkDeclarationsEligible).to receive(:new).and_return(mark_declarations)

          service.set!

          expect(Declarations::Actions::MarkDeclarationsEligible).to have_received(:new)
            .with(declarations: [no_payment_declaration], author:)
        end
      end
    end

    context "when teacher has an ongoing induction but only a future-dated ECT at school period" do
      before do
        FactoryBot.create(:induction_period, :ongoing, teacher:)
        FactoryBot.create(:ect_at_school_period,
                          teacher:,
                          started_on: 1.month.from_now,
                          finished_on: nil)
      end

      it "sets `ect_first_became_eligible_for_training_at`" do
        freeze_time do
          expect { service.set! }.to change(teacher, :ect_first_became_eligible_for_training_at).from(nil).to(Time.zone.now)
        end
      end
    end

    context "when teacher has an ongoing induction but only a finished ECT at school period" do
      before do
        FactoryBot.create(:induction_period, :ongoing, teacher:)
        FactoryBot.create(:ect_at_school_period,
                          teacher:,
                          started_on: 6.months.ago,
                          finished_on: 1.month.ago)
      end

      it "sets `ect_first_became_eligible_for_training_at`" do
        freeze_time do
          expect { service.set! }.to change(teacher, :ect_first_became_eligible_for_training_at).from(nil).to(Time.zone.now)
        end
      end
    end

    context "when teacher has an ongoing induction but no ECT at school periods" do
      before do
        FactoryBot.create(:induction_period, :ongoing, teacher:)
      end

      it "does not set `ect_first_became_eligible_for_training_at`" do
        expect { service.set! }.not_to change(teacher, :ect_first_became_eligible_for_training_at)
      end
    end

    context "when the teacher has no induction periods or ECT at school periods" do
      it "does not set `ect_first_became_eligible_for_training_at`" do
        expect { service.set! }.not_to change(teacher, :ect_first_became_eligible_for_training_at)
      end

      it "does not call `Declarations::Actions::MarkDeclarationsEligible` service" do
        expect(Declarations::Actions::MarkDeclarationsEligible).not_to receive(:new)

        service.set!
      end
    end

    context "does not touch mentor eligibility" do
      before do
        FactoryBot.create(:induction_period, :ongoing, teacher:)
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher:)
        mentor_at_school_period = FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:)
        FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:)
      end

      it "does not set `mentor_first_became_eligible_for_training_at`" do
        expect { service.set! }.not_to change(teacher, :mentor_first_became_eligible_for_training_at)
      end
    end

    context "when teacher attributes are changed" do
      it "records a teacher set funding eligibility event" do
        freeze_time do
          FactoryBot.create(:induction_period, :ongoing, teacher:)
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher:)

          expect(Events::Record).to receive(:record_teacher_set_funding_eligibility_event!)
            .with(author:,
                  teacher:,
                  teacher_type: "ECT",
                  happened_at: Time.zone.now,
                  modifications: hash_including("ect_first_became_eligible_for_training_at" => [nil, Time.zone.now]))

          service.set!
        end
      end
    end

    context "when teacher attributes are not changed" do
      before do
        teacher.update!(ect_first_became_eligible_for_training_at: Time.zone.now)
      end

      it "does not record a teacher set funding eligibility event" do
        expect(Events::Record).not_to receive(:record_teacher_set_funding_eligibility_event!)

        service.set!
      end
    end

    context "when an error is raised during the eligibility setting" do
      it "rolls back any changes" do
        FactoryBot.create(:induction_period, :ongoing, teacher:)
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher:)
        original_ect_eligible_at = teacher.ect_first_became_eligible_for_training_at

        allow(teacher).to receive(:touch).and_raise(ActiveRecord::RecordInvalid)

        expect { service.set! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(teacher.reload.ect_first_became_eligible_for_training_at).to eq(original_ect_eligible_at)
      end
    end
  end
end
