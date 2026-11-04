RSpec.describe Teachers::TRN::Replace do
  describe "#replace!" do
    subject(:replace) { described_class.new(teacher:, author:).replace! }

    let(:old_trn) { "654321" }
    let(:replacement_trn) { "123456" }
    let(:author) { nil }

    shared_examples "a TRN replacement" do
      it "replaces the TRN and resets the TRS attributes" do
        replace

        expect(teacher.reload).to have_attributes(
          trn: replacement_trn,
          trs_response: "ok",
          trs_redirected_to: nil
        )
      end

      it "records a teacher_trn_replaced event" do
        replace

        event = teacher.events.where(event_type: "teacher_trn_replaced").sole

        expect(event).to have_attributes(Events::SystemAuthor.new.system_author_params)
        expect(event.metadata).to eq(
          "old_trn" => old_trn,
          "new_trn" => replacement_trn
        )
      end

      it "queues a TRS refresh" do
        expect { replace }
          .to have_enqueued_job(Teachers::SyncTeacherWithTRSJob).with(teacher:)
      end

      context "when an admin author is supplied" do
        let(:admin_user) { FactoryBot.create(:user, role: :user_manager) }
        let(:author) { Sessions::Users::DfEUser.new(email: admin_user.email) }

        it "records the replacement event with the supplied admin author" do
          replace

          event = teacher.events.where(event_type: "teacher_trn_replaced").sole

          expect(event).to have_attributes(author_id: admin_user.id, author_type: "dfe_staff_user")
          expect(event.metadata).to eq(
            "old_trn" => old_trn,
            "new_trn" => replacement_trn
          )
        end
      end

      context "when recording the timeline event fails" do
        before do
          allow(Events::Record)
            .to receive(:record_teacher_trn_replaced_event!)
            .and_raise(StandardError, "Event recording failed")
        end

        it "rolls back the replacement and does not queue a TRS refresh" do
          original_attributes = teacher.reload.attributes

          expect { replace }.to raise_error(StandardError, "Event recording failed")

          expect(teacher.reload.attributes).to eq(original_attributes)
          expect(teacher.events.where(event_type: "teacher_trn_replaced")).to be_empty
          expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
        end
      end

      context "when updating the teacher fails validation" do
        before do
          allow(teacher)
            .to receive(:update!)
            .and_raise(ActiveRecord::RecordInvalid.new(teacher))
        end

        it "rolls back the replacement and does not queue a TRS refresh" do
          original_attributes = teacher.reload.attributes

          expect { replace }.to raise_error(ActiveRecord::RecordInvalid)

          expect(teacher.reload.attributes).to eq(original_attributes)
          expect(teacher.events.where(event_type: "teacher_trn_replaced")).to be_empty
          expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
        end
      end

      context "when there is a teacher in the database with the replacement TRN" do
        before { FactoryBot.create(:teacher, trn: replacement_trn) }

        it "leaves the teacher unchanged without recording an event or scheduling a refresh" do
          original_attributes = teacher.reload.attributes

          replace

          expect(teacher.reload.attributes).to eq(original_attributes)
          expect(teacher.events.where(event_type: "teacher_trn_replaced")).to be_empty
          expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
        end
      end
    end

    context "when the teacher has a TRS permanent redirect" do
      let(:teacher) do
        FactoryBot.create(:teacher, :merged_in_trs, trn: old_trn, trs_redirected_to: replacement_trn)
      end

      include_examples "a TRN replacement"

      context "when a different explicit TRN is also supplied" do
        let(:new_trn) { "8888888" }

        it "uses the trs_redirected_to value for the update" do
          replace

          expect(teacher.reload.trn).to eq(replacement_trn)
          expect(teacher.events.where(event_type: "teacher_trn_replaced").sole.metadata)
            .to include("new_trn" => replacement_trn)
        end
      end

      context "when replacement is ineligible" do
        let(:eligibility) { instance_double(Teachers::TRN::Eligibility, can_be_replaced?: false) }

        before do
          allow(Teachers::TRN::Eligibility).to receive(:new)
            .with(teacher:).and_return(eligibility)
        end

        it "leaves the record untouched without recording an event or scheduling a refresh" do
          expect { replace }.not_to(change { teacher.reload.attributes })
          expect(teacher.events.where(event_type: "teacher_trn_replaced")).to be_empty
          expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
        end
      end
    end

    context "when the teacher is deactivated" do
      subject(:replace) { described_class.new(teacher:, new_trn:, author:).replace! }

      let(:teacher) { FactoryBot.create(:teacher, :deactivated_in_trs, trn: old_trn) }
      let(:new_trn) { replacement_trn }

      include_examples "a TRN replacement"

      context "when the teacher has a trs_redirected_to value" do
        let(:teacher) do
          FactoryBot.create(:teacher, :deactivated_in_trs, trn: old_trn, trs_redirected_to: "8888888")
        end

        let(:new_trn) { replacement_trn }

        it "uses the supplied value for the update" do
          replace

          expect(teacher.reload.trn).to eq(replacement_trn)
          expect(teacher.events.where(event_type: "teacher_trn_replaced").sole.metadata)
            .to include("new_trn" => replacement_trn)
        end
      end

      context "when replacement is ineligible" do
        let(:eligibility) { instance_double(Teachers::TRN::Eligibility, can_be_replaced?: false) }

        before do
          allow(Teachers::TRN::Eligibility).to receive(:new)
            .with(teacher:, new_trn:).and_return(eligibility)
        end

        it "leaves the record untouched without recording an event or scheduling a refresh" do
          expect { replace }.not_to(change { teacher.reload.attributes })
          expect(teacher.events.where(event_type: "teacher_trn_replaced")).to be_empty
          expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
        end
      end
    end
  end
end
