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
      expect(Events::Record)
        .to receive(:record_teacher_trn_merged_event!)
        .with(author:, source: teacher, destination:)
        .and_call_original

      merge
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
  end
end
