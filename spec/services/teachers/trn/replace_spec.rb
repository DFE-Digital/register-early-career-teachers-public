RSpec.describe Teachers::TRN::Replace do
  describe "#initialize" do
    let(:teacher) { FactoryBot.build(:teacher) }

    ["", "   "].each do |new_trn|
      it "rejects a blank TRN supplied as #{new_trn.inspect}" do
        expect { described_class.new(teacher:, new_trn:) }
          .to raise_error(ArgumentError, "new_trn must not be blank when supplied")
      end
    end
  end

  describe "#replace!" do
    subject(:replace) { described_class.new(teacher:, new_trn:, author:).replace! }

    let(:old_trn) { "654321" }
    let(:replacement_trn) { "123456" }
    let(:new_trn) { nil }
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

      it "does not repeat a replacement through a stale teacher instance" do
        stale_teacher = teacher

        described_class.new(teacher: Teacher.find(teacher.id), new_trn:).replace!
        described_class.new(teacher: stale_teacher, new_trn: "8888888").replace!

        expect(teacher.reload).to have_attributes(
          trn: replacement_trn,
          trs_response: "ok",
          trs_redirected_to: nil
        )
        expect(teacher.events.where(event_type: "teacher_trn_replaced").count).to eq(1)
        expect(Teachers::SyncTeacherWithTRSJob).to have_been_enqueued.exactly(:once)
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

    context "when replacement is ineligible" do
      let(:teacher) { FactoryBot.create(:teacher, :deactivated_in_trs, trn: old_trn) }
      let(:new_trn) { replacement_trn }
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

    context "when the teacher has a TRS permanent redirect" do
      let(:teacher) do
        FactoryBot.create(:teacher, :merged_in_trs, trn: old_trn, trs_redirected_to: replacement_trn)
      end

      include_examples "a TRN replacement"
    end

    context "when the teacher is deactivated" do
      let(:teacher) { FactoryBot.create(:teacher, :deactivated_in_trs, trn: old_trn) }
      let(:new_trn) { replacement_trn }

      include_examples "a TRN replacement"
    end
  end
end
