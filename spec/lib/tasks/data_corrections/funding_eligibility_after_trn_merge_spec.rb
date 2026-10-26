describe "Data Corrections tasks" do
  describe "data_corrections:set_funding_eligibility_after_trn_merge" do
    subject :run_task do
      Rake::Task["data_corrections:set_funding_eligibility_after_trn_merge"].invoke
    end

    let(:stdout_lines) { [] }
    let!(:teacher) { FactoryBot.create(:teacher) }
    let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year:, framework_agreement:) }
    let(:school) { school_partnership.school }
    let(:payment_statement) { FactoryBot.create(:statement) }
    let(:other_statement) { FactoryBot.create(:statement) }
    let(:framework_agreement) { payment_statement.framework_agreement }
    let(:contract) { payment_statement.contract }
    let(:year) { payment_statement.contract_period.year }
    let(:service_dummy) { double(:service_dummy) }

    before do
      Rake::Task["data_corrections:set_funding_eligibility_after_trn_merge"].reenable

      allow($stdout).to receive(:puts) { |msg| stdout_lines << msg.to_s }
      allow(Declarations::Actions::MarkDeclarationsEligible).to receive(:new).and_call_original
    end

    context "when the teacher has not had their TRN merged" do
      it "does nothing to teachers which have not been merged" do
        expect { run_task }.not_to(change { teacher.reload.attributes })
      end
    end

    context "when there is a teacher with ect_at_school_periods whose TRNs have been merged" do
      let!(:teacher) { ect_at_school_period.teacher }
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period) }
      let(:ect_first_became_eligible_for_training_at) { induction_start_date }
      let(:ect_became_ineligible_for_funding_on) { nil }
      let(:induction_start_date) { nil }
      let(:trs_induction_status) { "InProgress" }

      before do
        teacher.update!(
          ect_first_became_eligible_for_training_at:,
          ect_became_ineligible_for_funding_on:,
          trs_induction_start_date: induction_start_date,
          trs_induction_status:
        )

        FactoryBot.create(:event, event_type: :teacher_merged, teacher:)
      end

      it "does not update mentor eligibility" do
        expect { run_task }.not_to(change do
          teacher.reload
          [
            teacher.mentor_first_became_eligible_for_training_at,
            teacher.mentor_became_ineligible_for_funding_on,
            teacher.mentor_became_ineligible_for_funding_reason
          ]
        end)
      end

      context "when the teacher has not started induction" do
        let(:induction_start_date) { nil }
        let(:ect_first_became_eligible_for_training_at) { nil }
        let(:trs_induction_status) { "RequiredToComplete" }

        it "does not change the ECT eligibility" do
          expect { run_task }.not_to(change { teacher.reload.ect_first_became_eligible_for_training_at })
        end

        it "does not mark any declarations as eligible" do
          expect(Declarations::Actions::MarkDeclarationsEligible).not_to receive(:new)

          run_task
        end
      end

      context "when the teacher has started induction" do
        let(:induction_start_date) { Date.new(2026, 9, 1) }

        let!(:ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :unfinished,
            started_on: induction_start_date
          )
        end

        context "and their eligibility is set" do
          let(:ect_first_became_eligible_for_training_at) { induction_start_date }

          it "does not change the ECT eligibility" do
            expect { run_task }.not_to(change { teacher.reload.ect_first_became_eligible_for_training_at })
          end
        end

        context "and their eligibility is not set" do
          let(:ect_first_became_eligible_for_training_at) { nil }

          it "corrects the ECT eligibility" do
            expect { run_task }.to change {
              teacher.reload.ect_first_became_eligible_for_training_at
            }.from(nil).to(induction_start_date.in_time_zone)
          end
        end
      end

      context "when the teacher TRS induction status in progress" do
        let(:induction_start_date) { nil }
        let(:trs_induction_status) { "InProgress" }

        let!(:ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            :unfinished
          )
        end

        context "and their eligibility is set" do
          let(:ect_first_became_eligible_for_training_at) { Date.new(2026, 9, 1) }

          it "does not change the ECT eligibility" do
            expect { run_task }.not_to(change { teacher.reload.ect_first_became_eligible_for_training_at })
          end
        end

        context "and their eligibility is not set" do
          let(:ect_first_became_eligible_for_training_at) { nil }

          it "corrects the ECT eligibility" do
            expect { run_task }.to change {
              teacher.reload.ect_first_became_eligible_for_training_at
            }.from(nil).to(ect_at_school_period.started_on.in_time_zone)
          end
        end
      end

      context "when the teacher is exempt from induction" do
        let(:trs_induction_status) { "Exempt" }
        let(:induction_start_date) { nil }
        let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period) }

        context "when the ECT's ineligible date is not set" do
          let(:ect_became_ineligible_for_funding_on) { nil }

          it "sets the ECT as ineligible for funding" do
            expect { run_task }.to change { teacher.reload.ect_became_ineligible_for_funding_on }.to(Date.current)
          end
        end

        context "when the ECT's ineligible date is already set" do
          let(:ect_became_ineligible_for_funding_on) { Date.current }

          it "does not change the ECT's ineligible date" do
            expect { run_task }.not_to(change { teacher.reload.ect_became_ineligible_for_funding_on })
          end
        end

        it "does not mark any declarations as eligible" do
          expect(Declarations::Actions::MarkDeclarationsEligible).not_to receive(:new)

          run_task
        end
      end

      context "when the teacher is eligible for funding and has declarations" do
        let(:induction_start_date) { Date.new(2026, 9, 1) }
        let(:ect_at_school_period) { declaration.ect_at_school_period }

        let!(:declaration) { FactoryBot.create(:declaration, :with_ect, payment_statement:, school_partnership:) }
        let!(:voided_declaration) do
          FactoryBot.create(
            :declaration,
            :voided,
            payment_statement: other_statement,
            training_period: declaration.training_period
          )
        end

        it "calls the MarkDeclarationsEligible service on no_payment declarations" do
          expect(teacher.ect_declarations).to contain_exactly(declaration, voided_declaration)

          expect(Declarations::Actions::MarkDeclarationsEligible).to receive(:new)
          .with(
            declarations: [declaration],
            author: anything
          ).and_call_original

          run_task
        end

        it "marks the no_payment declaration as eligible" do
          expect { run_task }.to change { declaration.reload.payment_status }.from("no_payment").to("eligible")
        end

        it "does not change other declarations" do
          expect { run_task }.not_to(change { voided_declaration.reload.payment_status })
        end

        context "when there is no payment statement" do
          before do
            allow(Declarations::Actions::MarkDeclarationsEligible).to receive(:new).and_return(service_dummy)
            allow(service_dummy).to receive(:mark).and_raise(Declarations::Actions::MarkDeclarationsEligible::MissingPaymentStatementError)
          end

          it "rescues MissingPaymentStatementError, continues, and reports failed TRNs at the end" do
            expect { run_task }.not_to raise_error

            expect(stdout_lines).to include("Failed to mark ECT declarations as eligible")
          end
        end
      end
    end

    context "when there is a teacher with mentor_at_school_periods whose TRNs have been merged" do
      let(:mentor_first_became_eligible_for_training_at) { started_on }
      let!(:mentor_at_school_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          :unfinished,
          teacher:,
          school:,
          started_on:
        )
      end

      let(:started_on) { Date.new(2026, 9, 1) }
      let(:mentor_became_ineligible_for_funding_on) { nil }
      let(:mentor_became_ineligible_for_funding_reason) { nil }

      before do
        teacher.update!(
          mentor_first_became_eligible_for_training_at:,
          mentor_became_ineligible_for_funding_on:,
          mentor_became_ineligible_for_funding_reason:
        )

        FactoryBot.create(:event, event_type: :teacher_merged, teacher:)
      end

      it "does not update ect eligibility" do
        expect { run_task }.not_to(change { teacher.reload.ect_first_became_eligible_for_training_at })
      end

      context "when the mentor did their own induction in the past" do
        before do
          teacher.update!(
            ect_first_became_eligible_for_training_at: nil,
            trs_induction_start_date: 2.years.ago.to_date
          )
        end

        it "does not change the mentor's eligibility" do
          expect { run_task }.not_to(change { teacher.reload.ect_first_became_eligible_for_training_at })
        end
      end

      context "when the mentor does not have training_periods" do
        let(:mentor_first_became_eligible_for_training_at) { nil }

        it "does not change the mentor eligibility" do
          expect { run_task }.not_to(change { teacher.reload.mentor_first_became_eligible_for_training_at })
        end
      end

      context "when the mentor has training_periods" do
        let!(:training_period) do
          FactoryBot.create(
            :training_period,
            :for_mentor,
            mentor_at_school_period:,
            started_on:
          )
        end

        context "and their eligibility is set" do
          let(:mentor_first_became_eligible_for_training_at) { started_on }

          it "does not change the mentor's eligibility" do
            expect { run_task }.not_to(change { teacher.reload.mentor_first_became_eligible_for_training_at })
          end
        end

        context "and their eligibility is not set" do
          let(:mentor_first_became_eligible_for_training_at) { nil }

          it "corrects the Mentor eligibility" do
            expect { run_task }.to change {
              teacher.reload.mentor_first_became_eligible_for_training_at
            }.from(nil).to(started_on.in_time_zone)
          end
        end
      end

      context "when the teacher is eligible for funding and there are declarations" do
        let(:mentor_at_school_period) { declaration.mentor_at_school_period }
        let(:teacher) { mentor_at_school_period.teacher }

        let!(:declaration) { FactoryBot.create(:declaration, :with_mentor, payment_statement:, school_partnership:) }
        let!(:voided_declaration) do
          FactoryBot.create(
            :declaration,
            :voided,
            payment_statement: other_statement,
            training_period: declaration.training_period
          )
        end

        it "calls the MarkDeclarationsEligible service on no_payment declarations" do
          expect(teacher.mentor_declarations).to contain_exactly(declaration, voided_declaration)

          expect(Declarations::Actions::MarkDeclarationsEligible).to receive(:new)
          .with(
            declarations: [declaration],
            author: anything
          ).and_call_original

          run_task
        end

        it "marks the no_payment declaration as eligible" do
          expect { run_task }.to change { declaration.reload.payment_status }.from("no_payment").to("eligible")
        end

        it "does not change other declarations" do
          expect { run_task }.not_to(change { voided_declaration.reload.payment_status })
        end

        context "when there is a completed declaration" do
          let!(:completed_declaration) do
            FactoryBot.create(
              :declaration,
              declaration_type: :completed,
              payment_statement: other_statement,
              training_period: declaration.training_period
            )
          end

          let(:training_period_finished_on) { declaration.training_period.started_on + 1.day }

          before do
            declaration.training_period.update!(finished_on: training_period_finished_on)
          end

          context "when mentor_became_ineligible_for_funding_on is not set" do
            it "marks the mentor as ineligible for funding" do
              expect { run_task }.to change {
                teacher.reload.mentor_became_ineligible_for_funding_on
              }.from(nil).to(training_period_finished_on).and change {
                teacher.reload.mentor_became_ineligible_for_funding_reason
              }.from(nil).to("completed_declaration_received")
            end
          end

          context "when mentor_became_ineligible_for_funding_on is already set" do
            let(:mentor_became_ineligible_for_funding_on) { training_period_finished_on - 1.day }
            let(:mentor_became_ineligible_for_funding_reason) { "completed_during_early_roll_out" }

            it "does not change the mentor's ineligibility" do
              expect { run_task }.not_to(change do
                teacher.reload
                [
                  teacher.mentor_became_ineligible_for_funding_on,
                  teacher.mentor_became_ineligible_for_funding_reason
                ]
              end)
            end
          end
        end

        context "when there is no payment statement" do
          before do
            allow(Declarations::Actions::MarkDeclarationsEligible).to receive(:new).and_return(service_dummy)
            allow(service_dummy).to receive(:mark).and_raise(Declarations::Actions::MarkDeclarationsEligible::MissingPaymentStatementError)
          end

          it "rescues MissingPaymentStatementError, continues, and reports failed TRNs at the end" do
            expect { run_task }.not_to raise_error

            expect(stdout_lines).to include("Failed to mark ECT declarations as eligible")
          end
        end
      end
    end

    context "when there are several teachers with merged TRNs" do
      let(:teachers) { [ect_at_school_period.teacher, other_ect_at_school_period.teacher, third_teacher] }
      let(:third_teacher) { third_ect_at_school_period.teacher }
      let(:ect_at_school_period) { declaration.ect_at_school_period }
      let(:other_ect_at_school_period) { other_declaration.ect_at_school_period }
      let!(:third_ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          :unfinished,
          started_on: trs_induction_start_date
        )
      end

      let(:trs_induction_start_date) { Date.new(2026, 9, 1) }

      let!(:declaration) { FactoryBot.create(:declaration, :with_ect, payment_statement:, school_partnership:) }
      let!(:other_declaration) { FactoryBot.create(:declaration, :with_ect, payment_statement:, school_partnership:) }

      before do
        teachers.each do |teacher|
          teacher.update!(
            ect_first_became_eligible_for_training_at: nil,
            trs_induction_start_date:,
            trs_induction_status: "InProgress"
          )
          FactoryBot.create(:event, event_type: :teacher_merged, teacher:)
        end

        allow(Declarations::Actions::MarkDeclarationsEligible).to receive(:new)
        .with(declarations: [declaration], author: anything)
        .and_call_original
        allow(Declarations::Actions::MarkDeclarationsEligible).to receive(:new)
        .with(declarations: [other_declaration], author: anything)
        .and_return(service_dummy)

        allow(service_dummy).to receive(:mark).and_raise(Declarations::Actions::MarkDeclarationsEligible::MissingPaymentStatementError)

        # Force a validation failure instead of stubbing save!
        third_teacher.update_column(:mentor_became_ineligible_for_funding_on, Time.zone.today)
      end

      it "continues processing other teachers when one teacher fails" do
        expect { run_task }.not_to raise_error

        expect(declaration.reload.payment_status).to eq("eligible")
        expect(other_declaration.reload.payment_status).to eq("no_payment")

        teachers.each do |teacher|
          expect(stdout_lines).to include("Processing teacher with TRN: #{teacher.trn}")
        end

        expect(stdout_lines).to include("Failed to mark ECT declarations as eligible")
        expect(stdout_lines).to include("Failed TRNs:")
        expect(stdout_lines).to include("#{other_ect_at_school_period.teacher.trn} (Declarations::Actions::MarkDeclarationsEligible::MissingPaymentStatementError)")
        expect(stdout_lines).to include("#{third_teacher.trn} (ActiveRecord::RecordInvalid)")
      end
    end
  end
end
