RSpec.describe Admin::ImportECT::RegisterECT do
  include ActiveJob::TestHelper

  subject { described_class.new(pending_induction_submission:, author:) }

  include_context 'test trs api client'

  before do
    allow(Events::Record).to receive(:new).and_call_original
    allow(author).to receive(:is_a?).with(Sessions::User).and_return(true)
    allow(author).to receive(:is_a?).with(any_args).and_call_original
  end

  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission, appropriate_body: nil) }
  let(:admin_user) { FactoryBot.create(:user, :admin) }
  let(:author) do
    Sessions::Users::DfEUser.new(
      email: admin_user.email
    )
  end

  describe "#initialize" do
    it "assigns the provided pending induction submission and author" do
      expect(subject.pending_induction_submission).to eq(pending_induction_submission)
      expect(subject.author).to eq(author)
    end
  end

  describe "#register" do
    context "when registering a new teacher" do
      it "creates a teacher without any induction periods" do
        expect {
          subject.register
        }.to change(Teacher, :count).by(1)
          .and not_change(InductionPeriod, :count)
      end

      it "returns the created teacher" do
        result = subject.register
        expect(result).to be_a(Teacher)
        expect(result.trn).to eq(pending_induction_submission.trn)
      end
    end

    context "when teacher already exists during registration" do
      let!(:existing_teacher) { FactoryBot.create(:teacher, trn: pending_induction_submission.trn) }

      it "raises TeacherAlreadyExists error" do
        teacher_name = ::Teachers::Name.new(existing_teacher).full_name

        expect { subject.register }.to raise_error do |error|
          expect(error).to be_a(Admin::Errors::TeacherAlreadyExists)
          expect(error.message).to eq(teacher_name)
        end
      end
    end

    context "when Teachers::Manage service raises an error" do
      before do
        allow(::Teachers::Manage).to receive(:find_or_initialize_by).and_raise(StandardError, "Database error")
      end

      it "does not create any records" do
        expect {
          expect { subject.register }.to raise_error(StandardError, "Database error")
        }.not_to change(Teacher, :count)
      end
    end
  end
end
