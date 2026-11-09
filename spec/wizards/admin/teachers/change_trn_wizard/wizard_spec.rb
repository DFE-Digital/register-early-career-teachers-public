RSpec.describe Admin::Teachers::ChangeTRNWizard::Wizard do
  subject { wizard.update! }

  let(:teacher) { FactoryBot.create(:teacher, :deactivated_in_trs, trn: old_trn) }
  let(:old_trn) { "1234567" }
  let(:new_trn) { "7654321" }
  let(:destination) { FactoryBot.create(:teacher, trn: new_trn) }
  let(:author) { FactoryBot.create(:dfe_user, role: "user_manager") }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) do
    described_class.new(teacher_id: teacher.id, author:, store:, current_step: :confirm)
  end

  shared_examples "it does not change the TRN" do
    it "rejects replacement without storing success details" do
      old_trn = teacher.trn

      expect { subject }.to raise_error(expected_error)

      expect(store.records_processed).to be_nil
      expect(teacher.reload.trn).to eq(old_trn)
      expect(store.old_trn).to be_nil
      expect(store.source_teacher_name).to be_nil
      expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
    end
  end

  describe "#ineligible_for_merge?" do
    subject { wizard }

    before do
      store.trn = destination.trn
      store.destination_teacher_id = destination.id
    end

    context "when the records can be merged" do
      it { is_expected.not_to be_ineligible_for_merge }
    end

    context "when both teachers have induction periods" do
      before do
        FactoryBot.create(:induction_period, teacher:)
        FactoryBot.create(:induction_period, teacher: destination)
      end

      it { is_expected.to be_ineligible_for_merge }
    end

    context "when no merge is proposed" do
      before do
        store.destination_teacher_id = nil
        store.trn = new_trn
        FactoryBot.create(:induction_period, teacher:)
      end

      it { is_expected.not_to be_ineligible_for_merge }
    end
  end

  describe "#teacher_name" do
    before { store.source_teacher_name = "Previously stored name" }

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
    before do
      store.trn = new_trn
      store.destination_teacher_id = nil
    end

    it "replaces the TRN and stores the original TRN" do
      subject

      expect(teacher.reload.trn).to eq(store.trn)
      expect(store.old_trn).to eq(old_trn)
      expect(store.records_processed).to eq("replaced")
      expect(teacher.events.where(event_type: "teacher_trn_replaced").sole)
        .to have_attributes(author.event_author_params.merge(author_type: "dfe_staff_user"))
      expect(Teachers::SyncTeacherWithTRSJob).to have_been_enqueued
    end

    context "when the replacement is ineligible" do
      let(:expected_error) { described_class::IneligibleForReplacementError }

      context "when the replacement TRN is unchanged" do
        before { store.trn = teacher.trn }

        include_examples "it does not change the TRN"
      end

      context "when another teacher redirects to the replacement TRN" do
        before { FactoryBot.create(:teacher, :merged_in_trs, trs_redirected_to: store.trn) }

        include_examples "it does not change the TRN"
      end

      context "when the replacement TRN belongs to another teacher" do
        before { FactoryBot.create(:teacher, trn: store.trn) }

        include_examples "it does not change the TRN"
      end
    end

    context "when the replacement service fails" do
      before do
        service = instance_double(Teachers::TRN::Replace)
        allow(Teachers::TRN::Replace).to receive(:new)
          .with(teacher: wizard.teacher, new_trn: store.trn, author:).and_return(service)
        allow(service).to receive(:replace!).and_raise(ActiveRecord::RecordInvalid)
      end

      let(:expected_error) { ActiveRecord::RecordInvalid }

      include_examples "it does not change the TRN"
    end

    context "when eligibility raises a resolver error" do
      before do
        eligibility = instance_double(Teachers::TRN::Eligibility)
        allow(Teachers::TRN::Eligibility).to receive(:new)
          .with(teacher: wizard.teacher, new_trn: store.trn)
          .and_return(eligibility)
        allow(eligibility).to receive(:can_be_replaced?)
          .and_raise(Teachers::TRN::Resolver::ProposedTRNError)
      end

      let(:expected_error) { described_class::ProposedTRNChangedError }

      include_examples "it does not change the TRN"
    end

    context "when the source is reactivated after it was loaded" do
      let(:expected_error) { described_class::TeacherNotDeactivatedError }

      before do
        wizard.teacher
        teacher.update!(trs_response: "ok")
      end

      include_examples "it does not change the TRN"
    end

    context "when another request has already replaced the TRN" do
      let(:expected_error) { described_class::TeacherNotDeactivatedError }

      before do
        wizard.teacher
        Teachers::TRN::Replace.new(teacher:, new_trn: store.trn, author:).replace!
        clear_enqueued_jobs
      end

      include_examples "it does not change the TRN"
    end
  end

  describe "merge" do
    before do
      store.trn = destination.trn
      store.destination_teacher_id = destination.id
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

    context "when eligibility raises a resolver error" do
      before do
        eligibility = instance_double(Teachers::TRN::Eligibility)
        allow(Teachers::TRN::Eligibility).to receive(:new)
          .with(teacher: wizard.teacher, new_trn: store.trn)
          .and_return(eligibility)
        allow(eligibility).to receive(:can_be_merged?)
          .and_raise(Teachers::TRN::Resolver::ProposedTRNError)
      end

      let(:expected_error) { described_class::ProposedTRNChangedError }

      include_examples "it does not change the TRN"
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

    context "when the merge is ineligible" do
      let(:expected_error) { described_class::IneligibleForMergeError }

      context "when the TRN is unchanged" do
        let(:destination) { teacher }
        let(:expected_error) { described_class::MergeDestinationChangedError }

        before { store.trn = teacher.trn }

        include_examples "it does not change the TRN"
      end

      context "when both teachers have induction records" do
        before do
          FactoryBot.create(:induction_period, teacher:)
          FactoryBot.create(:induction_period, teacher: destination)
        end

        it_behaves_like "it does not change the TRN"
      end

      context "when eligibility changes before the destination is locked" do
        before do
          FactoryBot.create(:induction_period, teacher:)
          allow(wizard.destination).to receive(:lock!) do
            FactoryBot.create(:induction_period, teacher: destination)
            wizard.destination
          end
        end

        it "checks eligibility after acquiring the destination lock" do
          expect { subject }.to raise_error(described_class::IneligibleForMergeError)

          expect(Teacher.exists?(teacher.id)).to be(true)
          expect(store.records_processed).to be_nil
          expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
        end
      end
    end

    context "when the merge service fails" do
      before do
        service = instance_double(Teachers::TRN::Merge)
        allow(Teachers::TRN::Merge).to receive(:new)
          .with(teacher: wizard.teacher, new_trn: store.trn, author:).and_return(service)
        allow(service).to receive(:merge!).and_raise(ActiveRecord::RecordInvalid)
      end

      let(:expected_error) { ActiveRecord::RecordInvalid }

      include_examples "it does not change the TRN"
    end

    context "when the merge service raises after changing a record" do
      let(:service) { instance_double(Teachers::TRN::Merge) }
      let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }

      before do
        allow(Teachers::TRN::Merge).to receive(:new)
          .with(teacher: wizard.teacher, new_trn: store.trn, author:).and_return(service)
        allow(service).to receive(:merge!) do
          ect_at_school_period.update!(teacher: destination)
          raise ActiveRecord::InvalidForeignKey
        end
      end

      it "propagates the error and rolls back changes without storing success details" do
        expect { subject }.to raise_error(ActiveRecord::InvalidForeignKey)

        expect(ect_at_school_period.reload.teacher_id).to eq(teacher.id)
        expect(Teacher.exists?(teacher.id)).to be(true)
        expect(store.records_processed).to be_nil
        expect(store.old_trn).to be_nil
        expect(store.source_teacher_name).to be_nil
        expect(Teachers::TRN::TRSSyncJob).not_to have_been_enqueued
      end
    end

    context "when the destination changes after it was loaded" do
      let(:expected_error) { described_class::MergeProposalChangedError }

      before do
        wizard.destination
        destination.update!(trn: "3456789")
      end

      it_behaves_like "it does not change the TRN"
    end

    context "when the source is reactivated after it was loaded" do
      let(:expected_error) { described_class::TeacherNotDeactivatedError }

      before do
        wizard.teacher
        teacher.update!(trs_response: "ok")
      end

      it_behaves_like "it does not change the TRN"
    end
  end
end
