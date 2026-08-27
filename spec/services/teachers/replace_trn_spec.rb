RSpec.describe Teachers::ReplaceTRN do
  describe "#replace!" do
    subject { described_class.new(teacher:).replace! }

    context "when the teacher has a TRS permanent redirect" do
      let!(:teacher) { FactoryBot.create(:teacher, :merged_in_trs) }
      let!(:old_trn) { teacher.trn }
      let!(:new_trn) { teacher.trs_redirected_to }

      it "replaces the teacher's TRN with the redirected TRN" do
        subject

        expect(teacher.reload.trn).to eq(new_trn)
        expect(teacher.trn).not_to eq(old_trn)
        expect(teacher.trs_redirected_to).to be_nil
        expect(teacher.trs_response).to be_nil
      end

      it "updates the trs_redirected_to attribute to nil" do
        subject

        expect(teacher.reload.trs_redirected_to).to be_nil
      end

      it "records a teacher_trn_replaced event" do
        expect(Events::Record).to receive(:record_teacher_trn_replaced_event!).with(
          author: an_instance_of(Events::SystemAuthor),
          teacher:,
          old_trn:,
          new_trn:
        )

        subject
      end

      it "calls the SyncTeacherWithTRSJob to refresh the teacher's TRS attributes" do
        expect(Teachers::SyncTeacherWithTRSJob).to receive(:perform_later).with(teacher:)

        subject
      end

      context "when there is a circular redirect" do
        let!(:replacement_teacher) { FactoryBot.create(:teacher, :merged_in_trs, trn: new_trn, trs_redirected_to: old_trn) }

        it "raises a CircularRedirectError" do
          expect { subject }.to raise_error(Teachers::ReplaceTRN::CircularRedirectError)
        end
      end

      context "when there is a teacher in the database with the replacement TRN" do
        before do
          FactoryBot.create(:teacher, trn: new_trn)
        end

        it "does not enqueue the SyncTeacherWithTRSJob" do
          expect(Teachers::SyncTeacherWithTRSJob).not_to receive(:perform_later).with(teacher:)

          subject
        end

        it "does not record a teacher_trn_replaced event" do
          expect(Events::Record).not_to receive(:record_teacher_trn_replaced_event!)

          subject
        end
      end

      context "when there are several teachers with the same redirected TRN" do
        before do
          FactoryBot.create(:teacher, :merged_in_trs, trs_redirected_to: teacher.trs_redirected_to)
        end

        it "does not enqueue the SyncTeacherWithTRSJob" do
          expect(Teachers::SyncTeacherWithTRSJob).not_to receive(:perform_later).with(teacher:)

          subject
        end

        it "does not record a teacher_trn_replaced event" do
          expect(Events::Record).not_to receive(:record_teacher_trn_replaced_event!)

          subject
        end
      end

      context "when the teacher is invalid" do
        let(:teacher) { FactoryBot.create(:teacher, :merged_in_trs, trs_redirected_to: "654321") }

        before do
          allow(teacher).to receive(:valid?).and_return(false)
        end

        it "does not enqueue the SyncTeacherWithTRSJob" do
          expect(Teachers::SyncTeacherWithTRSJob).not_to receive(:perform_later).with(teacher:)

          subject
        end

        it "does not record a teacher_trn_replaced event" do
          expect(Events::Record).not_to receive(:record_teacher_trn_replaced_event!)

          subject
        end
      end
    end

    context "when the teacher does not have TRS permanent redirect status" do
      let(:teacher) { FactoryBot.create(:teacher, trs_redirected_to: "654321") }

      it { is_expected.to be_falsey }

      it "does not enqueue the SyncTeacherWithTRSJob" do
        expect(Teachers::SyncTeacherWithTRSJob).not_to receive(:perform_later).with(teacher:)

        subject
      end

      it "does not record a teacher_trn_replaced event" do
        expect(Events::Record).not_to receive(:record_teacher_trn_replaced_event!)

        subject
      end
    end

    context "when the teacher does not have a redirected TRN" do
      let(:teacher) { FactoryBot.create(:teacher, trs_response: "permanent_redirect") }

      it { is_expected.to be_falsey }

      it "does not enqueue the SyncTeacherWithTRSJob" do
        expect(Teachers::SyncTeacherWithTRSJob).not_to receive(:perform_later).with(teacher:)

        subject
      end

      it "does not record a teacher_trn_replaced event" do
        expect(Events::Record).not_to receive(:record_teacher_trn_replaced_event!)

        subject
      end
    end
  end
end
