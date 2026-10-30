RSpec.describe Teachers::TRN::Merge do
  subject(:service) { described_class.new(teacher:) }

  include_context "a teacher merged in TRS"

  let(:teacher) { source }

  let(:school) { FactoryBot.create(:school) }
  let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: 2025, school:) }

  let!(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      teacher:,
      school:,
      started_on: first_period_started_on,
      finished_on: first_period_finished_on
    )
  end

  let!(:ect_training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      :with_framework_agreement,
      ect_at_school_period:,
      school_partnership:,
      started_on: first_period_started_on,
      finished_on: first_period_finished_on
    )
  end

  let!(:ect_declaration) do
    FactoryBot.create(
      :declaration,
      training_period: ect_training_period
    )
  end

  let!(:mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      teacher:,
      started_on: first_period_started_on,
      finished_on: first_period_finished_on
    )
  end

  let!(:mentor_training_period) do
    FactoryBot.create(
      :training_period,
      :for_mentor,
      :with_framework_agreement,
      mentor_at_school_period:,
      school_partnership:,
      started_on: first_period_started_on,
      finished_on: first_period_finished_on
    )
  end

  let!(:mentor_declaration) do
    FactoryBot.create(
      :declaration,
      training_period: mentor_training_period
    )
  end

  let!(:destination_mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      teacher: destination,
      school:,
      started_on: second_period_started_on,
      finished_on: second_period_finished_on
    )
  end

  let!(:destination_mentor_training_period) do
    FactoryBot.create(
      :training_period,
      :for_mentor,
      :with_framework_agreement,
      mentor_at_school_period: destination_mentor_at_school_period,
      school_partnership:,
      started_on: second_period_started_on,
      finished_on: second_period_finished_on
    )
  end

  let!(:destination_ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      teacher: destination,
      school:,
      started_on: second_period_started_on,
      finished_on: second_period_finished_on
    )
  end

  let!(:destination_ect_training_period) do
    FactoryBot.create(
      :training_period,
      :for_ect,
      :with_framework_agreement,
      school_partnership:,
      ect_at_school_period: destination_ect_at_school_period,
      started_on: second_period_started_on,
      finished_on: second_period_finished_on
    )
  end

  let(:mentor) do
    FactoryBot.create(
      :mentor_at_school_period,
      :unfinished,
      school:,
      started_on: first_period_started_on
    )
  end

  let!(:source_mentorship_period) do
    FactoryBot.create(
      :mentorship_period,
      mentee: ect_at_school_period,
      mentor:,
      started_on: first_period_started_on,
      finished_on: first_period_finished_on
    )
  end

  let!(:destination_mentorship_period) do
    FactoryBot.create(
      :mentorship_period,
      mentee: destination_ect_at_school_period,
      mentor:,
      started_on: second_period_started_on,
      finished_on: second_period_finished_on
    )
  end

  let(:first_period_started_on) { Date.new(2025, 1, 1) }
  let(:first_period_finished_on) { Date.new(2025, 3, 31) }
  let(:second_period_started_on) { Date.new(2025, 6, 1) }
  let(:second_period_finished_on) { Date.new(2025, 11, 30) }
  let(:overlapping_period_started_on) { Date.new(2025, 5, 1) }
  let(:overlapping_period_finished_on) { Date.new(2025, 7, 30) }

  describe "#initialize" do
    ["", "   "].each do |new_trn|
      it "rejects a blank TRN supplied as #{new_trn.inspect}" do
        expect { described_class.new(teacher:, new_trn:) }
          .to raise_error(ArgumentError, "new_trn must not be blank when supplied")
      end
    end
  end

  describe "#merge!" do
    subject(:merge!) { service.merge! }

    context "when the source changes after it was loaded" do
      before do
        teacher
        Teacher.find(teacher.id).update!(trs_response: "ok", trs_redirected_to: nil)
      end

      it "refreshes the source before checking eligibility" do
        merge!

        expect(Teacher.exists?(teacher.id)).to be(true)
        expect(ect_at_school_period.reload.teacher).to eq(teacher)
        expect(destination.events.where(event_type: "teacher_merged")).to be_empty
        expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when the destination changes after it was loaded" do
      before do
        allow(Teacher).to receive(:find_by_trn).with(destination.trn).and_return(destination)
        Teacher.find(destination.id).update!(trn: "8888888")
      end

      it "refreshes the destination and rejects a changed TRN" do
        merge!

        expect(Teacher.exists?(teacher.id)).to be(true)
        expect(destination.trn).to eq("8888888")
        expect(ect_at_school_period.reload.teacher).to eq(teacher)
        expect(destination.events.where(event_type: "teacher_merged")).to be_empty
        expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when destination data changes after it was loaded" do
      before do
        allow(Teacher).to receive(:find_by_trn).with(destination.trn).and_return(destination)
        Teacher.find(destination.id).update!(mentor_first_became_eligible_for_training_at: Date.new(2020, 1, 1))
      end

      it "preserves the latest destination data when merging" do
        merge!

        expect(Teacher.exists?(teacher.id)).to be(false)
        expect(destination.reload.mentor_first_became_eligible_for_training_at).to eq(Date.new(2020, 1, 1))
        expect(Teachers::TRN::TRSSyncJob).to have_been_enqueued.exactly(:once)
      end
    end

    context "when a replacement TRN is supplied for a deactivated teacher" do
      subject(:service) { described_class.new(teacher:, new_trn: destination.trn) }

      before { teacher.update!(trs_response: "gone", trs_redirected_to: nil) }

      it "merges into the teacher with the supplied TRN" do
        merge!

        expect(Teacher.exists?(teacher.id)).to be(false)
        expect(ect_at_school_period.reload.teacher).to eq(destination)
        expect(Teachers::TRN::TRSSyncJob).to have_been_enqueued.with(
          teacher: destination, teacher_started_induction_on: nil
        )
      end
    end

    context "when the destination has no overlapping records" do
      it "moves the at-school periods to the destination teacher" do
        merge!

        expect(ect_at_school_period.reload.teacher).to eq(destination)
        expect(mentor_at_school_period.reload.teacher).to eq(destination)
      end

      it "leaves the destinations teacher's periods in place" do
        merge!

        expect(destination.reload.ect_at_school_periods)
          .to contain_exactly(ect_at_school_period, destination_ect_at_school_period)
        expect(destination.mentor_at_school_periods)
          .to contain_exactly(mentor_at_school_period, destination_mentor_at_school_period)
        expect(destination.mentor_training_periods)
          .to contain_exactly(mentor_training_period, destination_mentor_training_period)
        expect(destination.ect_training_periods)
          .to contain_exactly(ect_training_period, destination_ect_training_period)
      end

      it "moves the declarations with their training periods to the destination teacher" do
        merge!

        expect(ect_declaration.reload.training_period.teacher).to eq(destination)
        expect(mentor_declaration.reload.training_period.teacher).to eq(destination)
      end

      it "does not merge any periods" do
        expect(Teachers::TRN::ECTAtSchoolPeriods::Merge).not_to receive(:call)
        expect(Teachers::TRN::MentorAtSchoolPeriods::Merge).not_to receive(:call)
        expect(Teachers::TRN::TrainingPeriods::Merge).not_to receive(:call)
        expect(Teachers::TRN::MentorshipPeriods::Merge).not_to receive(:call)

        merge!
      end

      context "when the source has induction records" do
        let!(:induction_period) { FactoryBot.create(:induction_period, teacher:) }
        let!(:induction_extension) { FactoryBot.create(:induction_extension, teacher:) }

        it "moves the induction records to the destination teacher" do
          merge!

          expect(induction_period.reload.teacher).to eq(destination)
          expect(induction_extension.reload.teacher).to eq(destination)
        end

        it "enqueues a `Teachers::TRN::TRSSyncJob` with an induction start date" do
          expect { merge! }
            .to have_enqueued_job(Teachers::TRN::TRSSyncJob)
            .with(teacher: destination, teacher_started_induction_on: induction_period.started_on)
        end
      end

      context "when the source has no induction records" do
        it "enqueues a `Teachers::TRN::TRSSyncJob` without an induction start date" do
          expect { merge! }
            .to have_enqueued_job(Teachers::TRN::TRSSyncJob)
            .with(teacher: destination, teacher_started_induction_on: nil)
        end
      end

      context "eligibility dates" do
        context "when the teacher is an ECT" do
          let(:teacher) do
            FactoryBot.create(
              :teacher,
              :merged_in_trs,
              ect_first_became_eligible_for_training_at: Date.new(2025, 1, 1),
              trn: source_trn,
              trs_redirected_to: destination_trn
            )
          end

          let!(:destination) do
            FactoryBot.create(
              :teacher,
              ect_first_became_eligible_for_training_at: Date.new(2026, 1, 1),
              trn: destination_trn
            )
          end

          it "moves the earliest eligibility dates to the destination" do
            merge!

            expect(destination.reload.ect_first_became_eligible_for_training_at)
              .to eq(Date.new(2025, 1, 1))
          end

          context "when the teacher is an ECT who became ineligible for funding" do
            let(:teacher) do
              FactoryBot.create(
                :teacher,
                :merged_in_trs,
                ect_became_ineligible_for_funding_on: Date.new(2023, 1, 1),
                trn: source_trn,
                trs_redirected_to: destination_trn
              )
            end

            let!(:destination) do
              FactoryBot.create(
                :teacher,
                ect_became_ineligible_for_funding_on: Date.new(2024, 1, 1),
                trn: destination_trn
              )
            end

            it "moves the earliest ineligibility date to the destination" do
              merge!

              expect(destination.reload.ect_became_ineligible_for_funding_on)
                .to eq(Date.new(2023, 1, 1))
            end
          end
        end

        context "when the teacher is a mentor" do
          let(:teacher) do
            FactoryBot.create(
              :teacher,
              :merged_in_trs,
              mentor_first_became_eligible_for_training_at: Date.new(2023, 1, 1),
              trn: source_trn,
              trs_redirected_to: destination_trn
            )
          end

          let!(:destination) do
            FactoryBot.create(
              :teacher,
              mentor_first_became_eligible_for_training_at: Date.new(2025, 1, 1),
              trn: destination_trn
            )
          end

          it "moves the earliest eligibility dates to the destination" do
            merge!

            expect(destination.reload.mentor_first_became_eligible_for_training_at)
              .to eq(Date.new(2023, 1, 1))
          end
        end

        context "when the teacher is a mentor who became ineligible for funding" do
          let(:teacher) do
            FactoryBot.create(
              :teacher,
              :merged_in_trs,
              mentor_became_ineligible_for_funding_on: Date.new(2026, 1, 1),
              mentor_became_ineligible_for_funding_reason: "started_not_completed",
              trn: source_trn,
              trs_redirected_to: destination_trn
            )
          end

          let!(:destination) do
            FactoryBot.create(
              :teacher,
              mentor_became_ineligible_for_funding_on: Date.new(2026, 6, 1),
              mentor_became_ineligible_for_funding_reason: "completed_declaration_received",
              trn: destination_trn
            )
          end

          it "moves the earliest mentor funding ineligibility date and reason to the destination" do
            merge!

            expect(destination.reload.mentor_became_ineligible_for_funding_on)
              .to eq(Date.new(2026, 1, 1))
            expect(destination.mentor_became_ineligible_for_funding_reason)
              .to eq("started_not_completed")
          end
        end
      end

      context "frozen payment data" do
        let(:frozen_contract_period_1) do
          FactoryBot.create(:contract_period, :with_payments_frozen, year: 2023)
        end
        let(:frozen_contract_period_2) do
          FactoryBot.create(:contract_period, :with_payments_frozen, year: 2024)
        end

        context "when the teacher is a mentor with frozen payment data" do
          let(:teacher) do
            FactoryBot.create(
              :teacher,
              :merged_in_trs,
              mentor_payments_frozen_year: frozen_contract_period_1.year,
              trn: source_trn,
              trs_redirected_to: destination_trn
            )
          end

          let!(:destination) do
            FactoryBot.create(
              :teacher,
              mentor_payments_frozen_year: frozen_contract_period_2.year,
              trn: destination_trn
            )
          end

          it "moves the earliest frozen payment years to the destination" do
            merge!

            expect(destination.reload.mentor_payments_frozen_year).to eq(2023)
          end
        end

        context "when the teacher is an ECT with frozen payment data" do
          let(:teacher) do
            FactoryBot.create(
              :teacher,
              :merged_in_trs,
              ect_payments_frozen_year: frozen_contract_period_1.year,
              trn: source_trn,
              trs_redirected_to: destination_trn
            )
          end

          let!(:destination) do
            FactoryBot.create(
              :teacher,
              ect_payments_frozen_year: frozen_contract_period_2.year,
              trn: destination_trn
            )
          end

          it "moves the earliest frozen payment years to the destination" do
            merge!

            expect(destination.reload.ect_payments_frozen_year).to eq(2023)
          end
        end
      end

      it "destroys the source teacher" do
        expect { merge! }
          .to change { Teacher.exists?(teacher.id) }
          .from(true)
          .to(false)
      end

      it "records a TeacherIdChange from the source participant to the destination participant" do
        source_api_id = teacher.api_id

        expect { merge! }.to change(TeacherIdChange, :count).by(1)

        change = TeacherIdChange.last
        expect(change.teacher).to eq(destination)
        expect(change.api_from_teacher_id).to eq(source_api_id)
        expect(change.api_to_teacher_id).to eq(destination.api_id)
      end

      it "moves the source's existing teacher_id_changes onto the destination" do
        earlier_change = FactoryBot.create(:teacher_id_change, teacher:)

        merge!

        expect(earlier_change.reload.teacher).to eq(destination)
      end

      it "populates the destination's metadata (which the model hooks do not do on reassignment)" do
        expect { merge! }
          .to change { destination.reload.lead_provider_metadata.count }
          .from(0)
      end

      it "preserves the source teacher’s timeline events on the destination" do
        Events::Record.record_teacher_trn_replaced_event!(
          teacher:,
          author: Events::SystemAuthor.new,
          old_trn: "1234567",
          new_trn: teacher.trn
        )
        event = teacher.events.where(event_type: "teacher_trn_replaced").sole

        merge!

        expect(event.reload.teacher_id).to eq(destination.id)
      end

      it "records a merge event" do
        merge!

        events = Event.where(event_type: "teacher_merged")
        expect(events.count).to eq(1)
        expect(events.pluck(:teacher_id).compact)
          .to eq([destination.id])
        expect(events.map(&:body).join)
          .to include(teacher.api_id, destination.api_id)
      end

      it "enqueues a `Teachers::TRN::TRSSyncJob` without an induction start date" do
        expect { merge! }
          .to have_enqueued_job(Teachers::TRN::TRSSyncJob)
          .with(teacher: destination, teacher_started_induction_on: nil)
      end
    end

    context "when the destination has overlapping records" do
      context "mentor at school periods" do
        let!(:overlapping_mentor_period) do
          FactoryBot.create(:mentor_at_school_period, teacher:, school:,
                                                      started_on: overlapping_period_started_on,
                                                      finished_on: overlapping_period_finished_on)
        end

        it "calls the mentor_at_school_periods merge service" do
          allow(Teachers::TRN::MentorAtSchoolPeriods::Merge).to receive(:call).and_call_original

          merge!

          expect(Teachers::TRN::MentorAtSchoolPeriods::Merge).to have_received(:call).with(
            periods: contain_exactly(
              overlapping_mentor_period,
              destination_mentor_at_school_period
            ),
            destination:
          ).once
        end

        it "moves the non-overlapping mentor_at_school_period to the destination teacher" do
          merge!

          expect(mentor_at_school_period.reload.teacher).to eq(destination)
          expect(mentor_at_school_period.started_on).to eq(first_period_started_on)
          expect(mentor_at_school_period.finished_on).to eq(first_period_finished_on)
        end

        it "merges the overlapping mentor_at_school_period" do
          merge!

          expect(destination_mentor_at_school_period.reload.started_on).to eq(overlapping_period_started_on)
          expect { overlapping_mentor_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "ect at school periods" do
        let!(:overlapping_ect_period) do
          FactoryBot.create(
            :ect_at_school_period,
            teacher:, school:,
            started_on: overlapping_period_started_on, finished_on: overlapping_period_finished_on
          )
        end

        it "calls the ect_at_school_period merge service" do
          allow(Teachers::TRN::ECTAtSchoolPeriods::Merge).to receive(:call).and_call_original

          merge!

          expect(Teachers::TRN::ECTAtSchoolPeriods::Merge).to have_received(:call).with(
            periods: contain_exactly(overlapping_ect_period,
                                     destination_ect_at_school_period),
            destination:
          ).once
        end

        it "moves the non-overlapping ect_at_school_period to the destination teacher" do
          merge!

          expect(ect_at_school_period.reload.teacher).to eq(destination)
          expect(ect_at_school_period.started_on).to eq(first_period_started_on)
          expect(ect_at_school_period.finished_on).to eq(first_period_finished_on)
        end

        it "merges the overlapping ect_at_school_period" do
          merge!

          expect(destination_ect_at_school_period.reload.started_on).to eq(overlapping_period_started_on)
          expect { overlapping_ect_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "when the teachers cannot be merged" do
      before do
        allow(Teachers::TRN::Eligibility).to receive(:new).with(teacher:, new_trn: nil, destination:).and_return(double(can_be_merged?: false))
      end

      it "does not move any ect_at_school_periods" do
        expect { merge! }.not_to(change { teacher.reload.ect_at_school_periods.map(&:teacher_id) })
      end

      it "does not move any mentor_at_school_periods" do
        expect { merge! }.not_to(change { teacher.reload.mentor_at_school_periods.map(&:teacher_id) })
      end

      context "when the source has induction records" do
        let!(:induction_period) { FactoryBot.create(:induction_period, teacher:) }
        let!(:induction_extension) { FactoryBot.create(:induction_extension, teacher:) }

        it "does not move any induction periods" do
          expect { merge! }.not_to(change { teacher.reload.induction_periods.map(&:teacher_id) })
        end

        it "does not move any induction extensions" do
          expect { merge! }.not_to(change { teacher.reload.induction_extensions.map(&:teacher_id) })
        end
      end

      it "does not move any ect declarations or training periods" do
        expect { merge! }.not_to(change { ect_declaration.reload.training_period.teacher })
      end

      it "does not move any mentor declarations or training periods" do
        expect { merge! }.not_to(change { mentor_declaration.reload.training_period.teacher })
      end

      it "does not record a TeacherIdChange" do
        expect { merge! }.not_to change(TeacherIdChange, :count)
      end

      it "does not remove any metadata" do
        expect { merge! }.not_to(change { teacher.reload.lead_provider_metadata.count })
      end

      it "does not destroy the source teacher" do
        expect { merge! }.not_to(change { Teacher.exists?(teacher.id) })
      end

      it "does not change any eligibility dates or other attributes of the teacher" do
        expect { merge! }.not_to(change { teacher.reload.attributes })
      end

      it "does not record a merge event" do
        merge!

        expect(Event.where(event_type: "teacher_merged")).to be_empty
      end

      it "does not enqueue a `Teachers::TRN::TRSSyncJob`" do
        expect { merge! }.not_to have_enqueued_job(Teachers::TRN::TRSSyncJob)
      end
    end

    context "when merging an overlapping period fails" do
      let!(:overlapping_mentor_period) do
        FactoryBot.create(
          :mentor_at_school_period,
          teacher:,
          school:,
          started_on: overlapping_period_started_on,
          finished_on: overlapping_period_finished_on
        )
      end

      let!(:overlapping_training_period) do
        FactoryBot.create(
          :training_period,
          :for_mentor,
          mentor_at_school_period: overlapping_mentor_period,
          school_partnership:,
          started_on: overlapping_period_started_on,
          finished_on: overlapping_period_finished_on
        )
      end

      before do
        allow(Teachers::TRN::TrainingPeriods::Merge)
          .to receive(:call)
          .and_raise(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods)
      end

      it "does not change the teacher's record" do
        original_attributes = ect_at_school_period.attributes.slice("started_on", "finished_on", "teacher_id")

        expect { merge! }.to raise_error(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods)

        expect(ect_at_school_period.reload.attributes.slice(*original_attributes.keys))
          .to eq(original_attributes)
      end

      it "does not destroy the source teacher or any related data" do
        expect { merge! }.to raise_error(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods)

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
        expect { merge! }.to raise_error(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods)

        expect(Event.where(event_type: "teacher_merged")).to be_empty
      end

      it "does not enqueue a `Teachers::TRN::TRSSyncJob`" do
        expect { merge! }
        .to raise_error(Teachers::TRN::TrainingPeriods::Merge::CannotMergePeriods)
        .and not_have_enqueued_job(Teachers::TRN::TRSSyncJob)
      end
    end
  end
end
