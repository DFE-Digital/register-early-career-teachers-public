RSpec.describe Admin::Teachers::ChangeTRNWizard::Wizard do
  describe "#merge_trn!" do
    subject(:merge) { wizard.merge_trn! }

    let(:store) { FactoryBot.build(:session_repository) }
    let(:wizard) { described_class.new(teacher_id: teacher.id, author:, store:, current_step: :confirm_merge) }

    let(:teacher) do
      FactoryBot.create(:teacher, :deactivated_in_trs)
    end

    let(:destination) { FactoryBot.create(:teacher, trs_response: "ok") }
    let(:author) { FactoryBot.create(:dfe_user, role: "user_manager") }

    before do
      store.trn = destination.trn
      store.destination_teacher_id = destination.id
    end

    it "merges the deactivated teacher into the supplied destination" do
      source_id = teacher.id
      destination_id = destination.id

      merge

      expect(Teacher.exists?(source_id)).to be(false)
      expect(Teacher.exists?(destination_id)).to be(true)
    end

    it "records the merge with the supplied admin author" do
      merge

      event = destination.events.where(event_type: "teacher_merged").sole
      expected_author = author.event_author_params.merge(
        author_type: "dfe_staff_user"
      )

      expect(event).to have_attributes(expected_author)
    end

    it "preserves the source teacher’s timeline events on the destination" do
      Events::Record.record_teacher_trn_replaced_event!(
        teacher:,
        author:,
        old_trn: "1234567",
        new_trn: teacher.trn
      )

      event = teacher.events.where(event_type: "teacher_trn_replaced").sole

      merge

      expect(event.reload.teacher_id).to eq(destination.id)
    end

    context "when the source teacher is not deactivated" do
      let(:teacher) { FactoryBot.create(:teacher, trs_response: "ok") }

      it "rejects the merge without deleting either teacher" do
        source_id = teacher.id
        destination_id = destination.id

        expect { merge }
          .to raise_error(described_class::TeacherNotDeactivatedError)

        expect(Teacher.exists?(source_id)).to be(true)
        expect(Teacher.exists?(destination_id)).to be(true)
        expect(TeacherIdChange.where(teacher_id: destination_id)).to be_empty
        expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when the records are ineligible for merging" do
      before do
        FactoryBot.create(:induction_period, teacher:)
        FactoryBot.create(:induction_period, teacher: destination)
      end

      it "rejects the merge without storing success details" do
        expect { merge }.to raise_error(described_class::IneligibleForMergeError)

        expect(Teacher.exists?(teacher.id)).to be(true)
        expect(store.old_trn).to be_nil
        expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when the destination changes after it was loaded" do
      before do
        wizard.destination
        destination.update!(trn: "3456789")
      end

      it "rechecks the reviewed TRN under the lock" do
        expect { merge }.to raise_error(described_class::MergeDestinationChangedError)

        expect(Teacher.exists?(teacher.id)).to be(true)
        expect(store.old_trn).to be_nil
        expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when the destination is the source teacher" do
      let(:destination) { teacher }

      it "rejects the merge without deleting the teacher" do
        source_id = teacher.id

        expect { merge }
          .to raise_error(described_class::MergeDestinationChangedError)

        expect(Teacher.exists?(source_id)).to be(true)
        expect(TeacherIdChange.where(teacher_id: source_id)).to be_empty
        expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when ECT periods overlap at different schools" do
      let!(:source_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          school: FactoryBot.create(:school),
          started_on: Date.new(2025, 9, 1),
          finished_on: Date.new(2026, 4, 1)
        )
      end

      let!(:destination_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher: destination,
          school: FactoryBot.create(:school),
          started_on: Date.new(2026, 1, 1),
          finished_on: nil
        )
      end

      it "rejects the merge without changing either record or their school periods" do
        source_id = teacher.id
        destination_id = destination.id
        original_source = teacher.attributes
        original_destination = destination.attributes
        original_source_period = source_period.attributes
        original_destination_period = destination_period.attributes

        expect { merge }
          .to raise_error(described_class::IneligibleForMergeError)

        expect(Teacher.exists?(source_id)).to be(true)
        expect(Teacher.exists?(destination_id)).to be(true)
        expect(teacher.reload.attributes).to eq(original_source)
        expect(destination.reload.attributes).to eq(original_destination)
        expect(source_period.reload.attributes).to eq(original_source_period)
        expect(destination_period.reload.attributes).to eq(original_destination_period)
        expect(destination.events.where(event_type: "teacher_merged")).to be_empty
        expect(TeacherIdChange.where(teacher_id: destination_id)).to be_empty
        expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when the destination TRN changes after it was reviewed" do
      it "rejects the merge without deleting either record or recording a merge" do
        source_id = teacher.id
        wizard.destination

        destination.update!(trn: "3456789")

        expect { merge }.to raise_error(described_class::MergeDestinationChangedError)

        expect(Teacher.exists?(source_id)).to be(true)
        expect(destination.reload.trn).to eq("3456789")
        expect(destination.events.where(event_type: "teacher_merged")).to be_empty
        expect(TeacherIdChange.where(teacher_id: destination.id)).to be_empty
        expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
      end
    end
  end
end
