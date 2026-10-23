RSpec.describe Teachers::MergeTRN do
  describe "#merge_deactivated!" do
    subject(:merge) do
      described_class.new(teacher:).merge_deactivated!(
        destination:,
        author:,
        expected_trn: destination.trn
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
        expect(described_class::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when the destination is the source teacher" do
      let(:destination) { teacher }

      it "rejects the merge without deleting the teacher" do
        source_id = teacher.id

        expect { merge }
          .to raise_error(described_class::IneligibleForMergeError)

        expect(Teacher.exists?(source_id)).to be(true)
        expect(TeacherIdChange.where(teacher_id: source_id)).to be_empty
        expect(described_class::TRSSyncJob).not_to have_been_enqueued
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
        expect(described_class::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when the destination TRN changes after it was reviewed" do
      it "rejects the merge without deleting either record or recording a merge" do
        source_id = teacher.id
        reviewed_trn = destination.trn
        stale_destination = Teacher.find(destination.id)

        destination.update!(trn: "3456789")

        expect {
          described_class.new(teacher:).merge_deactivated!(
            destination: stale_destination,
            author:,
            expected_trn: reviewed_trn
          )
        }.to raise_error(described_class::MergeProposalChangedError)

        expect(Teacher.exists?(source_id)).to be(true)
        expect(destination.reload.trn).to eq("3456789")
        expect(destination.events.where(event_type: "teacher_merged")).to be_empty
        expect(TeacherIdChange.where(teacher_id: destination.id)).to be_empty
        expect(described_class::TRSSyncJob).not_to have_been_enqueued
      end
    end
  end
end
