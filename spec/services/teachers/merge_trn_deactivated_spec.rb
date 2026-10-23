RSpec.describe Teachers::MergeTRN do
  describe "#merge_deactivated!" do
    subject(:merge) do
      described_class.new(teacher:).merge_deactivated!(
        destination:,
        author:
      )
    end

    let(:teacher) do
      FactoryBot.create(:teacher, :deactivated_in_trs)
    end

    let(:destination) { FactoryBot.create(:teacher, trs_response: "ok") }
    let(:author) { FactoryBot.create(:dfe_user, role: "user_manager") }

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
          .to raise_error(described_class::TeacherNotDeactivated)

        expect(Teacher.exists?(source_id)).to be(true)
        expect(Teacher.exists?(destination_id)).to be(true)
        expect(TeacherIdChange.where(teacher_id: destination_id)).to be_empty
        expect(described_class::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when the destination is the source teacher" do
      let(:destination) { teacher }

      it "rejects the merge without deleting the teacher" do
        source_id = teacher.id

        expect { merge }
          .to raise_error(described_class::IneligibleForMerge)

        expect(Teacher.exists?(source_id)).to be(true)
        expect(TeacherIdChange.where(teacher_id: source_id)).to be_empty
        expect(described_class::TRSSyncJob).not_to have_been_enqueued
      end
    end
  end
end
