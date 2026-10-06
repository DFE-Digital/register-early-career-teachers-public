RSpec.describe Teachers::MergeTRN do
  subject(:service) do
    described_class.new(teacher:)
  end

  let(:teacher) do
    FactoryBot.create(:teacher,
                      :merged_in_trs,
                      trn: source_trn,
                      trs_redirected_to: destination_trn)
  end

  let(:school) { FactoryBot.create(:school) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: 2025, school:) }

  let!(:destination) { FactoryBot.create(:teacher, :with_realistic_name, trn: destination_trn) }

  let(:source_trn) { "654321" }
  let(:destination_trn) { "123456" }

  let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on: first_period_started_on, finished_on: first_period_finished_on) }
  let!(:ect_training_period) do
    FactoryBot.create(:training_period,
                      :for_ect,
                      :with_framework_agreement,
                      ect_at_school_period:,
                      school_partnership:,
                      started_on: first_period_started_on,
                      finished_on: first_period_finished_on)
  end
  let!(:ect_declaration) { FactoryBot.create(:declaration, training_period: ect_training_period) }

  let!(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, started_on: first_period_started_on, finished_on: first_period_finished_on) }
  let!(:mentor_training_period) do
    FactoryBot.create(:training_period,
                      :for_mentor,
                      :with_framework_agreement,
                      mentor_at_school_period:,
                      school_partnership:,
                      started_on: first_period_started_on,
                      finished_on: first_period_finished_on)
  end

  let!(:mentor_declaration) { FactoryBot.create(:declaration, training_period: mentor_training_period) }

  let!(:destination_mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher: destination, school:, started_on: second_period_started_on, finished_on: second_period_finished_on) }
  let!(:destination_mentor_training_period) do
    FactoryBot.create(:training_period,
                      :for_mentor,
                      :with_framework_agreement,
                      mentor_at_school_period: destination_mentor_at_school_period,
                      school_partnership:,
                      started_on: second_period_started_on,
                      finished_on: second_period_finished_on)
  end
  let!(:destination_ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher: destination, school:, started_on: second_period_started_on, finished_on: second_period_finished_on) }

  let!(:destination_ect_training_period) do
    FactoryBot.create(:training_period,
                      :for_ect,
                      :with_framework_agreement,
                      school_partnership:,
                      ect_at_school_period: destination_ect_at_school_period,
                      started_on: second_period_started_on,
                      finished_on: second_period_finished_on)
  end

  let(:mentor) do
    FactoryBot.create(:mentor_at_school_period,
                      :unfinished,
                      school:,
                      started_on: first_period_started_on)
  end

  let!(:source_mentorship_period) do
    FactoryBot.create(:mentorship_period,
                      mentee: ect_at_school_period,
                      mentor:,
                      started_on: first_period_started_on,
                      finished_on: first_period_finished_on)
  end

  let!(:destination_mentorship_period) do
    FactoryBot.create(:mentorship_period,
                      mentee: destination_ect_at_school_period,
                      mentor:,
                      started_on: second_period_started_on,
                      finished_on: second_period_finished_on)
  end

  let(:first_period_started_on) { Date.new(2025, 1, 1) }
  let(:first_period_finished_on) { Date.new(2025, 3, 31) }
  let(:second_period_started_on) { Date.new(2025, 6, 1) }
  let(:second_period_finished_on) { Date.new(2025, 11, 30) }
  let(:overlapping_period_started_on) { Date.new(2025, 5, 1) }
  let(:overlapping_period_finished_on) { Date.new(2025, 7, 30) }

  before do
    allow(BeginECTInductionJob).to receive(:perform_now)
  end

  describe "#merge!" do
    context "when the destination has no overlapping records" do
      it "moves the at-school periods to the destination teacher" do
        service.merge!

        expect(ect_at_school_period.reload.teacher).to eq(destination)
        expect(mentor_at_school_period.reload.teacher).to eq(destination)
      end

      it "leaves the destinations teacher's periods in place" do
        service.merge!

        expect(destination.reload.ect_at_school_periods).to contain_exactly(ect_at_school_period, destination_ect_at_school_period)
        expect(destination.mentor_at_school_periods).to contain_exactly(mentor_at_school_period, destination_mentor_at_school_period)
        expect(destination.mentor_training_periods).to contain_exactly(mentor_training_period, destination_mentor_training_period)
        expect(destination.ect_training_periods).to contain_exactly(ect_training_period, destination_ect_training_period)
      end

      it "moves the declarations with their training periods to the destination teacher" do
        service.merge!

        expect(ect_declaration.reload.training_period.teacher).to eq(destination)
        expect(mentor_declaration.reload.training_period.teacher).to eq(destination)
      end

      it "does not merge any periods" do
        expect(Teachers::MergeTRN::ECTAtSchoolPeriods::Merge).not_to receive(:call)
        expect(Teachers::MergeTRN::MentorAtSchoolPeriods::Merge).not_to receive(:call)
        expect(Teachers::MergeTRN::TrainingPeriods::Merge).not_to receive(:call)
        expect(Teachers::MergeTRN::MentorshipPeriods::Merge).not_to receive(:call)

        service.merge!
      end

      context "when the source has induction records" do
        let!(:induction_period) { FactoryBot.create(:induction_period, teacher:) }
        let!(:induction_extension) { FactoryBot.create(:induction_extension, teacher:) }

        it "moves the induction records to the destination teacher" do
          service.merge!

          expect(induction_period.reload.teacher).to eq(destination)
          expect(induction_extension.reload.teacher).to eq(destination)
        end

        it "syncs the moved induction start date with TRS" do
          expect(BeginECTInductionJob).to receive(:perform_now).with(
            trn: destination.trn,
            start_date: induction_period.started_on
          )

          service.merge!
        end
      end

      context "when the source has no induction records" do
        it "does not sync induction data with TRS" do
          expect(BeginECTInductionJob).not_to receive(:perform_now)

          service.merge!
        end
      end

      context "eligibility dates" do
        context "when the teacher is an ECT" do
          let(:teacher) do
            FactoryBot.create(:teacher,
                              :merged_in_trs,
                              ect_first_became_eligible_for_training_at: Date.new(2025, 1, 1),
                              trn: source_trn,
                              trs_redirected_to: destination_trn)
          end

          let!(:destination) do
            FactoryBot.create(:teacher,
                              ect_first_became_eligible_for_training_at: Date.new(2026, 1, 1),
                              trn: destination_trn)
          end

          it "moves the earliest eligibility dates to the destination" do
            service.merge!

            expect(destination.reload.ect_first_became_eligible_for_training_at).to eq(Date.new(2025, 1, 1))
          end

          context "when the teacher is an ECT who became ineligible for funding" do
            let(:teacher) do
              FactoryBot.create(:teacher,
                                :merged_in_trs,
                                ect_became_ineligible_for_funding_on: Date.new(2023, 1, 1),
                                trn: source_trn,
                                trs_redirected_to: destination_trn)
            end

            let!(:destination) do
              FactoryBot.create(:teacher,
                                ect_became_ineligible_for_funding_on: Date.new(2024, 1, 1),
                                trn: destination_trn)
            end

            it "moves the earliest ineligibility date to the destination" do
              service.merge!

              expect(destination.reload.ect_became_ineligible_for_funding_on).to eq(Date.new(2023, 1, 1))
            end
          end
        end

        context "when the teacher is a mentor" do
          let(:teacher) do
            FactoryBot.create(:teacher,
                              :merged_in_trs,
                              mentor_first_became_eligible_for_training_at: Date.new(2023, 1, 1),
                              trn: source_trn,
                              trs_redirected_to: destination_trn)
          end

          let!(:destination) do
            FactoryBot.create(:teacher,
                              mentor_first_became_eligible_for_training_at: Date.new(2025, 1, 1),
                              trn: destination_trn)
          end

          it "moves the earliest eligibility dates to the destination" do
            service.merge!

            expect(destination.reload.mentor_first_became_eligible_for_training_at).to eq(Date.new(2023, 1, 1))
          end
        end

        context "when the teacher is a mentor who became ineligible for funding" do
          let(:teacher) do
            FactoryBot.create(:teacher,
                              :merged_in_trs,
                              mentor_became_ineligible_for_funding_on: Date.new(2026, 1, 1),
                              mentor_became_ineligible_for_funding_reason: "started_not_completed",
                              trn: source_trn,
                              trs_redirected_to: destination_trn)
          end

          let!(:destination) do
            FactoryBot.create(:teacher,
                              mentor_became_ineligible_for_funding_on: Date.new(2026, 6, 1),
                              mentor_became_ineligible_for_funding_reason: "completed_declaration_received",
                              trn: destination_trn)
          end

          it "moves the earliest mentor funding ineligibility date and reason to the destination" do
            service.merge!

            expect(destination.reload.mentor_became_ineligible_for_funding_on).to eq(Date.new(2026, 1, 1))
            expect(destination.mentor_became_ineligible_for_funding_reason).to eq("started_not_completed")
          end
        end
      end

      context "frozen payment data" do
        let(:frozen_contract_period_1) { FactoryBot.create(:contract_period, :with_payments_frozen, year: 2023) }
        let(:frozen_contract_period_2) { FactoryBot.create(:contract_period, :with_payments_frozen, year: 2024) }

        context "when the teacher is a mentor with frozen payment data" do
          let(:teacher) do
            FactoryBot.create(:teacher,
                              :merged_in_trs,
                              mentor_payments_frozen_year: frozen_contract_period_1.year,
                              trn: source_trn,
                              trs_redirected_to: destination_trn)
          end

          let!(:destination) do
            FactoryBot.create(:teacher,
                              mentor_payments_frozen_year: frozen_contract_period_2.year,
                              trn: destination_trn)
          end

          it "moves the earliest frozen payment years to the destination" do
            service.merge!

            expect(destination.reload.mentor_payments_frozen_year).to eq(2023)
          end
        end

        context "when the teacher is an ECT with frozen payment data" do
          let(:teacher) do
            FactoryBot.create(:teacher,
                              :merged_in_trs,
                              ect_payments_frozen_year: frozen_contract_period_1.year,
                              trn: source_trn,
                              trs_redirected_to: destination_trn)
          end

          let!(:destination) do
            FactoryBot.create(:teacher,
                              ect_payments_frozen_year: frozen_contract_period_2.year,
                              trn: destination_trn)
          end

          it "moves the earliest frozen payment years to the destination" do
            service.merge!

            expect(destination.reload.ect_payments_frozen_year).to eq(2023)
          end
        end
      end
    end

    context "when the destination has overlapping records" do
      context "mentor at school periods" do
        let!(:overlapping_mentor_period) do
          FactoryBot.create(:mentor_at_school_period, teacher:, school:,
                                                      started_on: overlapping_period_started_on,
                                                      finished_on: overlapping_period_finished_on)
        end

        it "calls the mentor at school periods merge service" do
          allow(Teachers::MergeTRN::MentorAtSchoolPeriods::Merge).to receive(:call).and_call_original

          service.merge!

          expect(Teachers::MergeTRN::MentorAtSchoolPeriods::Merge).to have_received(:call).with(
            periods: contain_exactly(
              overlapping_mentor_period,
              destination_mentor_at_school_period
            ),
            destination:
          ).once
        end

        it "merges the overlapping mentor at school periods" do
          service.merge!

          expect(destination_mentor_at_school_period.reload.started_on).to eq(overlapping_period_started_on)
        end

        it "destroys the original overlapping mentor at school period" do
          service.merge!

          expect { overlapping_mentor_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "moves the non-overlapping mentor at school periods to the destination teacher" do
          service.merge!

          expect(mentor_at_school_period.reload.teacher).to eq(destination)
          expect(mentor_at_school_period.started_on).to eq(first_period_started_on)
          expect(mentor_at_school_period.finished_on).to eq(first_period_finished_on)
        end

        context "when there are no overlapping training periods" do
          it "does not merge any training periods" do
            expect(Teachers::MergeTRN::TrainingPeriods::Merge).not_to receive(:call)
            service.merge!
          end
        end

        context "when there are overlapping training periods" do
          let!(:overlapping_training_period) do
            FactoryBot.create(:training_period,
                              :for_mentor,
                              mentor_at_school_period: overlapping_mentor_period,
                              school_partnership:,
                              started_on: overlapping_period_started_on,
                              finished_on: overlapping_period_finished_on)
          end

          it "calls the training periods merge service" do
            expect(Teachers::MergeTRN::TrainingPeriods::Merge).to receive(:call).with(
              periods: contain_exactly(
                overlapping_training_period,
                destination_mentor_training_period
              ),
              destination:
            ).once

            service.merge!
          end

          it "merges overlapping training periods" do
            service.merge!

            expect(destination_mentor_training_period.reload.started_on).to eq(overlapping_period_started_on)
          end

          it "moves the non-overlapping training periods to the destination teacher" do
            service.merge!

            expect(mentor_training_period.reload.teacher).to eq(destination)
            expect(mentor_training_period.started_on).to eq(first_period_started_on)
            expect(mentor_training_period.finished_on).to eq(first_period_finished_on)
          end
        end
      end

      context "ect at school periods" do
        let!(:overlapping_ect_period) do
          FactoryBot.create(:ect_at_school_period,
                            teacher:, school:,
                            started_on: overlapping_period_started_on, finished_on: overlapping_period_finished_on)
        end

        it "calls the ect at school periods merge service" do
          allow(Teachers::MergeTRN::ECTAtSchoolPeriods::Merge).to receive(:call).and_call_original

          service.merge!

          expect(Teachers::MergeTRN::ECTAtSchoolPeriods::Merge).to have_received(:call).with(
            periods: contain_exactly(overlapping_ect_period,
                                     destination_ect_at_school_period),
            destination:
          ).once
        end

        it "merges the overlapping ect at school periods" do
          service.merge!

          expect(destination_ect_at_school_period.reload.started_on).to eq(overlapping_period_started_on)
        end

        it "deletes the overlapping ect at school period from the source teacher" do
          service.merge!

          expect { overlapping_ect_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "moves the non-overlapping ect at school periods to the destination teacher" do
          service.merge!

          expect(ect_at_school_period.reload.teacher).to eq(destination)
          expect(ect_at_school_period.started_on).to eq(first_period_started_on)
          expect(ect_at_school_period.finished_on).to eq(first_period_finished_on)
        end

        context "when there are no overlapping ect training periods" do
          it "does not merge any training periods" do
            expect(Teachers::MergeTRN::TrainingPeriods::Merge).not_to receive(:call)
            service.merge!
          end
        end

        context "when there are overlapping training periods" do
          let!(:overlapping_training_period) do
            FactoryBot.create(:training_period,
                              :for_ect,
                              ect_at_school_period: overlapping_ect_period,
                              school_partnership:,
                              started_on: overlapping_period_started_on,
                              finished_on: overlapping_period_finished_on)
          end

          it "calls the training periods merge service" do
            expect(Teachers::MergeTRN::TrainingPeriods::Merge).to receive(:call).with(
              periods: contain_exactly(
                overlapping_training_period,
                destination_ect_training_period
              ),
              destination:
            ).once

            service.merge!
          end

          it "merges overlapping training periods" do
            service.merge!

            expect(destination_ect_training_period.reload.started_on).to eq(overlapping_period_started_on)
          end

          it "moves the non-overlapping training periods to the destination teacher" do
            service.merge!

            expect(ect_training_period.reload.teacher).to eq(destination)
            expect(ect_training_period.started_on).to eq(first_period_started_on)
            expect(ect_training_period.finished_on).to eq(first_period_finished_on)
          end
        end

        context "when there are no overlapping mentorship periods" do
          it "does not call the mentorship periods merge service" do
            expect(Teachers::MergeTRN::MentorshipPeriods::Merge).not_to receive(:call)

            service.merge!
          end
        end

        context "when there are overlapping mentorship periods" do
          let!(:overlapping_ect_period) { nil }
          let(:first_period_finished_on) { Date.new(2025, 7, 30) }

          let!(:overlapping_mentorship_period) do
            FactoryBot.create(:mentorship_period,
                              mentee: ect_at_school_period,
                              mentor:,
                              started_on: overlapping_period_started_on,
                              finished_on: overlapping_period_finished_on)
          end

          let!(:source_mentorship_period) do
            FactoryBot.create(:mentorship_period,
                              mentee: ect_at_school_period,
                              mentor:,
                              started_on: first_period_started_on,
                              finished_on: Date.new(2025, 3, 30))
          end

          it "calls the mentorship periods merge service" do
            expect(Teachers::MergeTRN::MentorshipPeriods::Merge).to receive(:call).with(
              periods: contain_exactly(
                overlapping_mentorship_period,
                destination_mentorship_period
              ),
              destination:
            ).once

            service.merge!
          end

          it "merges overlapping mentorship periods" do
            service.merge!

            expect(destination_mentorship_period.reload.mentee.teacher).to eq(destination)
            expect(destination_mentorship_period.started_on).to eq(overlapping_period_started_on)
            expect(destination_mentorship_period.finished_on).to eq(second_period_finished_on)
          end

          it "moves the non-overlapping mentorship periods to the destination teacher" do
            service.merge!

            expect(source_mentorship_period.reload.mentee.teacher).to eq(destination)
          end
        end
      end
    end

    context "when the teachers cannot be merged" do
      before do
        allow(Teachers::MergeTRN::Eligibility).to receive(:new).with(teacher:).and_return(double(can_be_merged?: false))
      end

      it "does not move any ect_at_school_periods" do
        expect { service.merge! }.not_to(change { teacher.reload.ect_at_school_periods.map(&:teacher_id) })
      end

      it "does not move any mentor_at_school_periods" do
        expect { service.merge! }.not_to(change { teacher.reload.mentor_at_school_periods.map(&:teacher_id) })
      end

      context "when the source has induction records" do
        let!(:induction_period) { FactoryBot.create(:induction_period, teacher:) }
        let!(:induction_extension) { FactoryBot.create(:induction_extension, teacher:) }

        it "does not move any induction periods" do
          expect { service.merge! }.not_to(change { teacher.reload.induction_periods.map(&:teacher_id) })
        end

        it "does not move any induction extensions" do
          expect { service.merge! }.not_to(change { teacher.reload.induction_extensions.map(&:teacher_id) })
        end

        it "does not sync the induction start date with TRS" do
          expect(BeginECTInductionJob).not_to receive(:perform_now)

          service.merge!
        end
      end

      it "does not move any ect declarations or training periods" do
        expect { service.merge! }.not_to(change { ect_declaration.reload.training_period.teacher })
      end

      it "does not move any mentor declarations or training periods" do
        expect { service.merge! }.not_to(change { mentor_declaration.reload.training_period.teacher })
      end

      it "does not record a TeacherIdChange" do
        expect { service.merge! }.not_to change(TeacherIdChange, :count)
      end

      it "does not remove any metadata" do
        expect { service.merge! }.not_to(change { teacher.reload.lead_provider_metadata.count })
      end

      it "does not destroy the source teacher" do
        expect { service.merge! }.not_to(change { Teacher.exists?(teacher.id) })
      end

      it "does not change any eligibility dates or other attributes of the teacher" do
        expect { service.merge! }.not_to(change { teacher.reload.attributes })
      end

      it "does not record a merge event" do
        service.merge!

        expect(Event.where(event_type: "teacher_merged")).to be_empty
      end

      it "does not sync induction data with TRS" do
        expect(BeginECTInductionJob).not_to receive(:perform_now)

        service.merge!
      end

      it "does not resync with TRS" do
        expect(Teachers::SyncTeacherWithTRSJob).not_to receive(:perform_later)

        service.merge!
      end
    end

    context "when merging an overlapping period fails" do
      let!(:overlapping_mentor_period) do
        FactoryBot.create(:mentor_at_school_period, teacher:, school:,
                                                    started_on: overlapping_period_started_on,
                                                    finished_on: overlapping_period_finished_on)
      end

      let!(:overlapping_training_period) do
        FactoryBot.create(:training_period,
                          :for_mentor,
                          mentor_at_school_period: overlapping_mentor_period,
                          school_partnership:,
                          started_on: overlapping_period_started_on,
                          finished_on: overlapping_period_finished_on)
      end

      before do
        allow(Teachers::MergeTRN::TrainingPeriods::Merge)
          .to receive(:call)
          .and_raise(Teachers::MergeTRN::TrainingPeriods::Merge::CannotMergePeriods)
      end

      it "does not change the teacher's record" do
        original_attributes = ect_at_school_period.attributes.slice("started_on", "finished_on", "teacher_id")

        expect { service.merge! }.to raise_error(Teachers::MergeTRN::TrainingPeriods::Merge::CannotMergePeriods)

        expect(ect_at_school_period.reload.attributes.slice(*original_attributes.keys))
          .to eq(original_attributes)
      end

      it "does not destroy the source teacher or any related data" do
        expect { service.merge! }.to raise_error(Teachers::MergeTRN::TrainingPeriods::Merge::CannotMergePeriods)

        expect(Teacher.exists?(teacher.id)).to be true
        expect(ECTAtSchoolPeriod.exists?(ect_at_school_period.id)).to be true
        expect(MentorAtSchoolPeriod.exists?(mentor_at_school_period.id)).to be true
        expect(MentorAtSchoolPeriod.exists?(overlapping_mentor_period.id)).to be true
        expect(TrainingPeriod.exists?(ect_training_period.id)).to be true
        expect(TrainingPeriod.exists?(mentor_training_period.id)).to be true
        expect(TrainingPeriod.exists?(overlapping_training_period.id)).to be true
        expect(Declaration.exists?(ect_declaration.id)).to be true
        expect(Declaration.exists?(mentor_declaration.id)).to be true
      end

      it "does not record a merge event" do
        expect { service.merge! }.to raise_error(Teachers::MergeTRN::TrainingPeriods::Merge::CannotMergePeriods)

        expect(Event.where(event_type: "teacher_merged")).to be_empty
      end

      it "does not sync induction data with TRS" do
        expect(BeginECTInductionJob).not_to receive(:perform_now)

        expect { service.merge! }.to raise_error(Teachers::MergeTRN::TrainingPeriods::Merge::CannotMergePeriods)
      end

      it "does not resync with TRS" do
        expect(Teachers::SyncTeacherWithTRSJob).not_to receive(:perform_later)

        expect { service.merge! }.to raise_error(Teachers::MergeTRN::TrainingPeriods::Merge::CannotMergePeriods)
      end
    end
  end
end
