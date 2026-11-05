RSpec.describe Admin::Teachers::ChangeTRNWizard::Wizard do
  subject(:replace_trn) { wizard.replace_trn! }

  let(:teacher) { FactoryBot.create(:teacher, :deactivated_in_trs) }
  let(:author) { FactoryBot.create(:dfe_user, role: "user_manager") }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) { described_class.new(teacher_id: teacher.id, author:, store:, current_step: :confirm) }

  before { store.trn = "2345678" }

  shared_examples "it does not replace the TRN" do
    it "rejects replacement without storing success details" do
      old_trn = teacher.trn

      expect { replace_trn }.to raise_error(expected_error)

      expect(teacher.reload.trn).to eq(old_trn)
      expect(store.old_trn).to be_nil
      expect(Teachers::SyncTeacherWithTRSJob).not_to have_been_enqueued
    end
  end

  it "replaces the TRN and stores the original TRN" do
    old_trn = teacher.trn

    replace_trn

    expect(teacher.reload.trn).to eq(store.trn)
    expect(store.old_trn).to eq(old_trn)
    expect(teacher.events.where(event_type: "teacher_trn_replaced").sole)
      .to have_attributes(author.event_author_params.merge(author_type: "dfe_staff_user"))
    expect(Teachers::SyncTeacherWithTRSJob).to have_been_enqueued
  end

  context "when the source is reactivated after it was loaded" do
    before do
      wizard.teacher
      teacher.update!(trs_response: "ok")
    end

    let(:expected_error) { described_class::TeacherNotDeactivatedError }

    include_examples "it does not replace the TRN"
  end

  context "when the replacement is ineligible" do
    let(:expected_error) { described_class::IneligibleForReplacementError }

    context "when the replacement TRN is unchanged" do
      before { store.trn = teacher.trn }

      include_examples "it does not replace the TRN"
    end

    context "when another teacher redirects to the replacement TRN" do
      before { FactoryBot.create(:teacher, :merged_in_trs, trs_redirected_to: store.trn) }

      include_examples "it does not replace the TRN"
    end

    context "when the replacement TRN belongs to another teacher" do
      before { FactoryBot.create(:teacher, trn: store.trn) }

      include_examples "it does not replace the TRN"
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

    include_examples "it does not replace the TRN"
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

    include_examples "it does not replace the TRN"
  end
end
