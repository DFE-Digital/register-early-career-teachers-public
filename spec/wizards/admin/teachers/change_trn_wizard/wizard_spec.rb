RSpec.describe Admin::Teachers::ChangeTRNWizard::Wizard do
  subject { wizard.update! }

  let(:teacher) { FactoryBot.create(:teacher, :deactivated_in_trs) }
  let(:destination) { FactoryBot.create(:teacher, trs_response: "ok") }
  let(:author) { FactoryBot.create(:dfe_user, role: "user_manager") }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) do
    described_class.new(teacher_id: teacher.id, author:, store:, current_step: :confirm)
  end

  before do
    store.trn = destination.trn
    store.destination_teacher_id = destination.id
  end

  describe "#teacher_name" do
    before { store.source_teacher_name = "Previously stored name" }

    it "uses the current teacher name before processing" do
      expect(wizard.teacher_name).to eq(Teachers::Name.new(teacher).full_name)
    end

    context "when records have been replaced" do
      before { store.records_processed = "replaced" }

      it "uses the current teacher name" do
        expect(wizard.teacher_name).to eq(Teachers::Name.new(teacher).full_name)
      end
    end

    context "when records have been merged" do
      before do
        store.records_processed = "merged"
        teacher.destroy!
      end

      it "uses the stored name without loading the deleted teacher" do
        expect(wizard.teacher_name).to eq("Previously stored name")
      end
    end
  end

  describe "replacement" do
    before { store.destination_teacher_id = nil }

    it "replaces the TRN and stores the original TRN" do
      old_trn = teacher.trn
      source_name = Teachers::Name.new(teacher).full_name
      destination.destroy!

      subject

      expect(teacher.reload.trn).to eq(store.trn)
      expect(store.old_trn).to eq(old_trn)
      expect(store.records_processed).to eq("replaced")
      expect(store.source_teacher_name).to eq(source_name)
      expect(wizard.teacher_name).to eq(source_name)
      expect(Teachers::SyncTeacherWithTRSJob).to have_been_enqueued
    end

    context "when the replacement service fails" do
      let(:service) { instance_double(Teachers::TRN::Replace) }

      before do
        destination.destroy!
        allow(Teachers::TRN::Replace).to receive(:new)
          .with(teacher: wizard.teacher, new_trn: store.trn, author:).and_return(service)
        allow(service).to receive(:replace!).and_raise(described_class::TeacherNotDeactivatedError)
      end

      it "does not store success details" do
        expect { subject }.to raise_error(described_class::TeacherNotDeactivatedError)

        expect(store.records_processed).to be_nil
        expect(store.old_trn).to be_nil
        expect(store.source_teacher_name).to be_nil
      end
    end

    context "when the source is reactivated after it was loaded" do
      before do
        wizard.teacher
        teacher.update!(trs_response: "ok")
      end

      it "rejects replacement after refreshing the source under the lock" do
        expect { subject }.to raise_error(described_class::TeacherNotDeactivatedError)

        expect(store.old_trn).to be_nil
        expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
      end
    end

    context "when the replacement TRN matches the current TRN" do
      before { store.trn = teacher.trn }

      it "rejects replacement without recording success" do
        expect { subject }.to raise_error(described_class::IneligibleForReplacementError)

        expect(store.old_trn).to be_nil
        expect(teacher.reload.trs_response).to eq("gone")
        expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
      end
    end

    context "when another teacher redirects to the replacement TRN" do
      before do
        FactoryBot.create(:teacher, :merged_in_trs, trs_redirected_to: store.trn)
      end

      it "rejects replacement without recording success" do
        expect { subject }.to raise_error(described_class::IneligibleForReplacementError)

        expect(store.old_trn).to be_nil
        expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
      end
    end

    context "when another request has already replaced the TRN" do
      it "rejects a second replacement through a stale teacher instance" do
        destination.destroy!
        stale_teacher = wizard.teacher
        Teachers::TRN::Replace.new(teacher:, new_trn: store.trn, author:).replace!

        expect { subject }.to raise_error(described_class::TeacherNotDeactivatedError)

        expect(stale_teacher.trn).to eq(store.trn)
        expect(store.old_trn).to be_nil
        expect(Teachers::SyncTeacherWithTRSJob).to have_been_enqueued.exactly(:once)
      end
    end
  end

  describe "merge" do
    it "preserves the source teacher’s timeline events on the destination" do
      Events::Record.record_teacher_trn_replaced_event!(
        teacher:,
        author:,
        old_trn: "1234567",
        new_trn: teacher.trn
      )

      event = teacher.events.where(event_type: "teacher_trn_replaced").sole

      subject

      expect(event.reload.teacher_id).to eq(destination.id)
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

        expect { subject }
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

    it "merges the records and records the admin author" do
      source_name = Teachers::Name.new(teacher).full_name
      old_trn = teacher.trn

      subject

      expect(Teacher.exists?(teacher.id)).to be(false)
      expect(destination.events.where(event_type: "teacher_merged").sole)
        .to have_attributes(author.event_author_params.merge(author_type: "dfe_staff_user"))
      expect(store.old_trn).to eq(old_trn)
      expect(store.source_teacher_name).to eq(source_name)
      expect(store.records_processed).to eq("merged")
      expect(Teachers::TRN::TRSSyncJob).to have_been_enqueued
    end

    context "when the merge service fails" do
      let(:service) { instance_double(Teachers::TRN::Merge) }

      before do
        allow(Teachers::TRN::Merge).to receive(:new)
          .with(teacher: wizard.teacher, new_trn: store.trn, author:).and_return(service)
        allow(service).to receive(:merge!).and_raise(described_class::IneligibleForMergeError)
      end

      it "does not store success details" do
        expect { subject }.to raise_error(described_class::IneligibleForMergeError)

        expect(store.records_processed).to be_nil
        expect(store.old_trn).to be_nil
        expect(store.source_teacher_name).to be_nil
      end
    end

    context "when the teachers are ineligible for merging" do
      before do
        FactoryBot.create(:induction_period, teacher:)
        FactoryBot.create(:induction_period, teacher: destination)
      end

      it "raises without merging or storing success details" do
        expect { subject }.to raise_error(described_class::IneligibleForMergeError)

        expect(Teacher.exists?(teacher.id)).to be(true)
        expect(store.old_trn).to be_nil
        expect(store.source_teacher_name).to be_nil
        expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when eligibility changes before the destination is locked" do
      before do
        FactoryBot.create(:induction_period, teacher:)
        allow(wizard.destination).to receive(:with_lock).and_wrap_original do |with_lock, &block|
          FactoryBot.create(:induction_period, teacher: destination)
          with_lock.call(&block)
        end
      end

      it "checks eligibility after acquiring the destination lock" do
        expect { subject }.to raise_error(described_class::IneligibleForMergeError)

        expect(Teacher.exists?(teacher.id)).to be(true)
        expect(store.records_processed).to be_nil
        expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when the destination changes after it was loaded" do
      before do
        wizard.destination
        destination.update!(trn: "3456789")
      end

      it "rechecks the reviewed TRN under the lock" do
        expect { subject }.to raise_error(described_class::MergeProposalChangedError)

        expect(Teacher.exists?(teacher.id)).to be(true)
        expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when the source is reactivated after it was loaded" do
      before do
        wizard.teacher
        teacher.update!(trs_response: "ok")
      end

      it "rejects the merge after refreshing the source under the lock" do
        expect { subject }.to raise_error(described_class::TeacherNotDeactivatedError)

        expect(Teacher.exists?(teacher.id)).to be(true)
        expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
      end
    end
  end
end
