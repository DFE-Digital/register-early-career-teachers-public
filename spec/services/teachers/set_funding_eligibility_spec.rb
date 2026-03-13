RSpec.describe Teachers::SetFundingEligibility do
  let(:teacher) { FactoryBot.create(:teacher, api_ect_training_record_id: SecureRandom.uuid) }
  let(:author) { Events::SystemAuthor.new }
  let(:service) { described_class.new(teacher:, author:) }

  describe "#set!" do
    context "when teacher is eligible for ECT training" do
      before do
        FactoryBot.create(:induction_period, :ongoing, teacher:)
        ect_at_school_period = FactoryBot.create(:ect_at_school_period,
                                                 teacher:,
                                                 started_on: 2.months.ago,
                                                 finished_on: nil)
        training_period = FactoryBot.create(:training_period,
                                            :for_ect,
                                            :ongoing,
                                            ect_at_school_period:)
        FactoryBot.create(:declaration, training_period:)
        FactoryBot.create(:statement, :open, active_lead_provider: training_period.active_lead_provider)
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

      it "calls `Declarations::Actions::MarkDeclarationsEligible` service" do
        expect(Declarations::Actions::MarkDeclarationsEligible).to receive(:new).with(declarations: teacher.ect_declarations, author:).and_call_original

        service.set!
      end
    end

    context "when teacher is not eligible for ECT training" do
      it "does not set `ect_first_became_eligible_for_training_at`" do
        expect { service.set! }.not_to change(teacher, :ect_first_became_eligible_for_training_at)
      end

      it "does not call `Declarations::Actions::MarkDeclarationsEligible` service" do
        expect(Declarations::Actions::MarkDeclarationsEligible).not_to receive(:new)

        service.set!
      end
    end

    context "when teacher is eligible for mentor training" do
      before do
        mentor_at_school_period = FactoryBot.create(:mentor_at_school_period,
                                                    teacher:,
                                                    started_on: 2.months.ago,
                                                    finished_on: nil)
        training_period = FactoryBot.create(:training_period,
                                            :for_mentor,
                                            :ongoing,
                                            mentor_at_school_period:)
        FactoryBot.create(:declaration, training_period:)
        FactoryBot.create(:statement, :open, active_lead_provider: training_period.active_lead_provider)
      end

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

      it "calls `Declarations::Actions::MarkDeclarationsEligible` service" do
        expect(Declarations::Actions::MarkDeclarationsEligible).to receive(:new).with(declarations: teacher.mentor_declarations, author:).and_call_original

        service.set!
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

    context "when teacher attributes are changed" do
      it "records a teacher set funding eligibility event" do
        freeze_time do
          expect(Events::Record).to receive(:record_teacher_set_funding_eligibility_event!)
            .with(author:,
                  teacher:,
                  happened_at: Time.zone.now,
                  modifications: { "mentor_first_became_eligible_for_training_at" => [nil, Time.zone.now] })

          service.set!
        end
      end
    end

    context "when teacher attributes are not changed" do
      before do
        teacher.update!(ect_first_became_eligible_for_training_at: Time.zone.now, mentor_first_became_eligible_for_training_at: Time.zone.now)
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
        original_ect_eligible_at = teacher.ect_first_became_eligible_for_training_at
        original_mentor_eligible_at = teacher.mentor_first_became_eligible_for_training_at

        FactoryBot.create(:induction_period, :ongoing, teacher:)
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher:)

        expect { service.set! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(teacher.reload.ect_first_became_eligible_for_training_at).to eq(original_ect_eligible_at)
        expect(teacher.reload.mentor_first_became_eligible_for_training_at).to eq(original_mentor_eligible_at)
      end
    end

    context "when teacher is eligible for ECT training and also for mentor training" do
      before do
        FactoryBot.create(:induction_period, :ongoing, teacher:)
        ect_at_school_period = FactoryBot.create(:ect_at_school_period,
                                                 teacher:,
                                                 started_on: 2.months.ago,
                                                 finished_on: nil)
        training_period = FactoryBot.create(:training_period,
                                            :for_ect,
                                            :ongoing,
                                            ect_at_school_period:)
        FactoryBot.create(:declaration, training_period:)
        FactoryBot.create(:statement, :open, active_lead_provider: training_period.active_lead_provider)

        mentor_at_school_period = FactoryBot.create(:mentor_at_school_period,
                                                    teacher:,
                                                    started_on: 2.months.ago,
                                                    finished_on: nil)
        training_period = FactoryBot.create(:training_period,
                                            :for_mentor,
                                            :ongoing,
                                            mentor_at_school_period:)
        FactoryBot.create(:declaration, training_period:)
        FactoryBot.create(:statement, :open, active_lead_provider: training_period.active_lead_provider)
      end

      it "calls `Declarations::Actions::MarkDeclarationsEligible` service" do
        expect(Declarations::Actions::MarkDeclarationsEligible).to receive(:new).with(declarations: teacher.ect_declarations + teacher.mentor_declarations, author:).and_call_original

        service.set!
      end

      context "when `ect/mentor_first_became_eligible_for_training_at` is not already set" do
        it "sets `ect/mentor_first_became_eligible_for_training_at`" do
          freeze_time do
            expect { service.set! }
            .to change(teacher, :ect_first_became_eligible_for_training_at).from(nil).to(Time.zone.now)
            .and change(teacher, :mentor_first_became_eligible_for_training_at).from(nil).to(Time.zone.now)
          end
        end
      end

      context "when `ect/mentor_first_became_eligible_for_training_at` is already set" do
        it "does not change `ect/mentor_first_became_eligible_for_training_at`" do
          freeze_time do
            teacher.update!(
              ect_first_became_eligible_for_training_at: 1.day.ago,
              mentor_first_became_eligible_for_training_at: 1.day.ago
            )

            service.set!

            expect(teacher.reload.ect_first_became_eligible_for_training_at).to eq(1.day.ago)
            expect(teacher.reload.mentor_first_became_eligible_for_training_at).to eq(1.day.ago)
          end
        end
      end
    end
  end
end
