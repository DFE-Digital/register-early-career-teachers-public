RSpec.describe Teachers::ReplaceTRN do
  describe "#replace!" do
    subject { described_class.new(teacher:).replace! }

    let(:teacher) do
      FactoryBot.create(
        :teacher,
        :merged_in_trs,
        trn: old_trn,
        trs_redirected_to: new_trn
      )
    end

    let(:old_trn) { "654321" }
    let(:new_trn) { "123456" }

    context "when the teacher has a TRS permanent redirect" do
      it "replaces the teacher's TRN with the redirected TRN and resets the TRS attributes" do
        subject

        expect(teacher.reload.trn).to eq(new_trn)
        expect(teacher.trs_response).to eq("ok")
        expect(teacher.trs_redirected_to).to be_nil
      end

      it "records a teacher_trn_replaced event" do
        subject

        event = teacher.events.where(event_type: "teacher_trn_replaced").sole

        expect(event).to have_attributes(
          Events::SystemAuthor.new.system_author_params
        )
        expect(event.metadata).to eq(
          "old_trn" => old_trn,
          "new_trn" => new_trn
        )
      end

      it "calls the SyncTeacherWithTRSJob to refresh the teacher's TRS attributes" do
        expect(Teachers::SyncTeacherWithTRSJob)
          .to receive(:perform_later).with(teacher:)

        subject
      end

      it "does not repeat a replacement through a stale teacher instance" do
        stale_teacher = teacher

        described_class.new(
          teacher: Teacher.find(teacher.id)
        ).replace!

        described_class.new(teacher: stale_teacher).replace!

        expect(teacher.reload).to have_attributes(
          trn: new_trn,
          trs_response: "ok",
          trs_redirected_to: nil
        )
        expect(teacher.events.where(event_type: "teacher_trn_replaced").count)
          .to eq(1)
        expect(Teachers::SyncTeacherWithTRSJob)
          .to have_been_enqueued.exactly(:once)
      end

      context "when there is a teacher in the database with the replacement TRN" do
        before do
          FactoryBot.create(:teacher, trn: new_trn)
        end

        it "does not change the teacher's TRN, response or redirected_to attribute" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)

          expect(teacher.reload.trn).to eq(old_trn)
          expect(teacher.trs_redirected_to).to eq(new_trn)
          expect(teacher.trs_response).to eq("permanent_redirect")
        end

        it "does not enqueue the SyncTeacherWithTRSJob" do
          expect(Teachers::SyncTeacherWithTRSJob)
            .not_to receive(:perform_later).with(teacher:)

          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
        end

        it "does not record a teacher_trn_replaced event" do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)

          expect(Event.where(event_type: "teacher_trn_replaced")).to be_empty
        end
      end

      context "when there are several teachers with the same redirected TRN" do
        before do
          FactoryBot.create(
            :teacher,
            :merged_in_trs,
            trs_redirected_to: teacher.trs_redirected_to
          )
        end

        it "does not change the teacher's TRN, response or redirected_to attribute" do
          subject

          expect(teacher.reload.trn).to eq(old_trn)
          expect(teacher.trs_redirected_to).to eq(new_trn)
          expect(teacher.trs_response).to eq("permanent_redirect")
        end

        it "does not enqueue the SyncTeacherWithTRSJob" do
          expect(Teachers::SyncTeacherWithTRSJob)
            .not_to receive(:perform_later).with(teacher:)

          subject
        end

        it "does not record a teacher_trn_replaced event" do
          subject

          expect(Event.where(event_type: "teacher_trn_replaced")).to be_empty
        end
      end
    end

    context "when the teacher does not have TRS permanent redirect status" do
      let!(:teacher) do
        FactoryBot.create(
          :teacher,
          trn: old_trn,
          trs_redirected_to: new_trn
        )
      end

      it "does not change the teacher's TRN, response or redirected_to attribute" do
        subject

        expect(teacher.reload.trn).to eq(old_trn)
        expect(teacher.trs_redirected_to).to eq(new_trn)
        expect(teacher.trs_response).to be_nil
      end

      it "does not enqueue the SyncTeacherWithTRSJob" do
        expect(Teachers::SyncTeacherWithTRSJob)
          .not_to receive(:perform_later).with(teacher:)

        subject
      end

      it "does not record a teacher_trn_replaced event" do
        subject

        expect(Event.where(event_type: "teacher_trn_replaced")).to be_empty
      end
    end

    context "when the teacher does not have a redirected TRN" do
      let!(:teacher) do
        FactoryBot.create(
          :teacher,
          trs_response: "permanent_redirect",
          trn: old_trn
        )
      end

      it "does not change the teacher's TRN, response or redirected_to attribute" do
        subject

        expect(teacher.reload.trn).to eq(old_trn)
        expect(teacher.trs_redirected_to).to be_nil
        expect(teacher.trs_response).to eq("permanent_redirect")
      end

      it "does not enqueue the SyncTeacherWithTRSJob" do
        expect(Teachers::SyncTeacherWithTRSJob)
          .not_to receive(:perform_later).with(teacher:)

        subject
      end

      it "does not record a teacher_trn_replaced event" do
        subject

        expect(Event.where(event_type: "teacher_trn_replaced")).to be_empty
      end
    end
  end

  describe "#replace_deactivated!" do
    subject(:replace_trn) do
      described_class.new(teacher:, author:).replace_deactivated!(
        new_trn:
      )
    end

    let(:teacher) do
      FactoryBot.create(
        :teacher,
        :deactivated_in_trs,
        trn: old_trn
      )
    end

    let(:old_trn) { "7654321" }
    let(:new_trn) { "2345678" }
    let(:author) { Events::SystemAuthor.new }

    it "replaces a deactivated TRN with the supplied TRN" do
      replace_trn

      expect(teacher.reload).to have_attributes(
        trn: new_trn,
        trs_response: "ok",
        trs_redirected_to: nil
      )
    end

    it "queues a TRS refresh" do
      expect { replace_trn }
        .to have_enqueued_job(Teachers::SyncTeacherWithTRSJob)
        .with(teacher:)
    end

    context "when an admin author is supplied" do
      let(:admin_user) { FactoryBot.create(:user, role: :user_manager) }
      let(:author) { Sessions::Users::DfEUser.new(email: admin_user.email) }

      it "records the replacement event with the supplied admin author" do
        replace_trn

        event = teacher.events.where(event_type: "teacher_trn_replaced").sole

        expect(event).to have_attributes(
          author_id: admin_user.id,
          author_type: "dfe_staff_user"
        )
        expect(event.metadata).to eq(
          "old_trn" => old_trn,
          "new_trn" => new_trn
        )
      end
    end

    context "when the teacher is not deactivated" do
      let(:teacher) { FactoryBot.create(:teacher, trn: old_trn) }

      it "rejects the replacement without changing the teacher" do
        expect { replace_trn }
          .to raise_error(described_class::TeacherNotDeactivatedError)

        expect(teacher.reload.trn).to eq(old_trn)
        expect(Event.where(event_type: "teacher_trn_replaced")).to be_empty
        expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
      end
    end

    context "when the replacement TRN matches the current TRN" do
      let(:new_trn) { old_trn }

      it "rejects the replacement without making changes" do
        expect { replace_trn }
          .to raise_error(described_class::TRNUnchangedError)

        expect(teacher.reload).to have_attributes(
          trn: old_trn,
          trs_response: "gone",
          trs_redirected_to: nil
        )
        expect(teacher.events.where(event_type: "teacher_trn_replaced")).to be_empty
        expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
      end
    end

    context "when the replacement TRN already exists" do
      before { FactoryBot.create(:teacher, trn: new_trn) }

      it "rejects the replacement without changing the teacher" do
        expect { replace_trn }
          .to raise_error(ActiveRecord::RecordInvalid)

        expect(teacher.reload).to have_attributes(
          trn: old_trn,
          trs_response: "gone"
        )
        expect(Event.where(event_type: "teacher_trn_replaced")).to be_empty
        expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
      end
    end

    context "when another teacher redirects to the replacement TRN" do
      before do
        FactoryBot.create(
          :teacher,
          :merged_in_trs,
          trs_redirected_to: new_trn
        )
      end

      it "rejects the replacement without making changes" do
        expect { replace_trn }
          .to raise_error(described_class::RedirectedTeacherExistsError)

        expect(teacher.reload).to have_attributes(
          trn: old_trn,
          trs_response: "gone",
          trs_redirected_to: nil
        )
        expect(teacher.events.where(event_type: "teacher_trn_replaced")).to be_empty
        expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
      end
    end

    context "when another request has already replaced the TRN" do
      it "rejects replacement through a stale teacher instance" do
        stale_teacher = Teacher.find(teacher.id)

        replace_trn

        expect {
          described_class.new(
            teacher: stale_teacher,
            author:
          ).replace_deactivated!(new_trn: "3456789")
        }.to raise_error(described_class::TeacherNotDeactivatedError)

        expect(teacher.reload.trn).to eq(new_trn)
        expect(teacher.events.where(event_type: "teacher_trn_replaced").count)
          .to eq(1)
        expect(Teachers::SyncTeacherWithTRSJob)
          .to have_been_enqueued.exactly(:once)
      end
    end

    context "when recording the timeline event fails" do
      before do
        allow(Events::Record)
          .to receive(:record_teacher_trn_replaced_event!)
          .and_raise(StandardError, "Event recording failed")
      end

      it "rolls back the replacement and does not queue a TRS refresh" do
        expect { replace_trn }
          .to raise_error(StandardError, "Event recording failed")

        expect(teacher.reload).to have_attributes(
          trn: old_trn,
          trs_response: "gone",
          trs_redirected_to: nil
        )
        expect(teacher.events.where(event_type: "teacher_trn_replaced")).to be_empty
        expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
      end
    end
  end
end
