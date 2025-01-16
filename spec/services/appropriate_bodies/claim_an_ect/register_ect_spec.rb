RSpec.describe AppropriateBodies::ClaimAnECT::RegisterECT do
  include ActiveJob::TestHelper
  include_context 'fake trs api client'

  before { allow(Events::Record).to receive(:new).and_call_original }

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }
  let(:author) do
    Sessions::Users::AppropriateBodyUser.new(
      name: 'A user',
      email: 'ab_user@something.org',
      dfe_sign_in_user_id: SecureRandom.uuid,
      dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id
    )
  end

  before do
    allow(author).to receive(:is_a?).with(Sessions::User).and_return(true)
    allow(author).to receive(:is_a?).with(any_args).and_call_original
  end

  subject { described_class.new(appropriate_body:, pending_induction_submission:, author:) }

  describe "#initialize" do
    it "assigns the provided appropriate body and pending induction submission" do
      expect(subject.appropriate_body).to eq(appropriate_body)
      expect(subject.pending_induction_submission).to eq(pending_induction_submission)
    end
  end

  describe "#register" do
    let(:trs_qts_awarded_on) { Date.new(2023, 5, 2) }
    let(:pending_induction_submission_params) do
      {
        induction_programme: "fip",
        started_on: Date.new(2023, 5, 2),
        trn: "1234567",
        trs_first_name: "John",
        trs_last_name: "Doe",
        trs_qts_awarded_on:
      }
    end

    context "with started_on before trs_qts_awarded" do
      let(:trs_qts_awarded_on) { Date.new(2023, 5, 3) }

      it "fails because invalid" do
        expect(subject.register(pending_induction_submission_params)).to be_falsey
        expect(subject.pending_induction_submission.errors[:started_on]).to include(
          "Induction start date cannot be earlier than QTS award date (3 May 2023)"
        )
      end
    end

    context "when registering a new teacher" do
      it "creates a new teacher and induction period", :aggregate_failures do
        expect {
          subject.register(pending_induction_submission_params)
        }.to change(Teacher, :count).by(1)
          .and change(InductionPeriod, :count).by(1)

        teacher = Teacher.last
        expect(teacher.trs_first_name).to eq("John")
        expect(teacher.trs_last_name).to eq("Doe")
        expect(teacher.trn).to eq("1234567")

        induction_period = InductionPeriod.last
        expect(induction_period.teacher).to eq(teacher)
        expect(induction_period.started_on).to eq(Date.new(2023, 5, 2))
        expect(induction_period.appropriate_body).to eq(appropriate_body)
        expect(induction_period.induction_programme).to eq("fip")
      end

      it "enqueues BeginECTInductionJob" do
        expect {
          subject.register(pending_induction_submission_params)
        }.to have_enqueued_job(BeginECTInductionJob)
          .with(hash_including(trn: "1234567", start_date: "2023-05-02"))
      end

      it "records an appropriate_body_claims_teacher event" do
        subject.register(pending_induction_submission_params)

        expect(Events::Record).to have_received(:new).with(
          hash_including(
            author:,
            event_type: :appropriate_body_claims_teacher,
            appropriate_body:,
            heading: "John Doe was claimed by #{appropriate_body.name}"
          )
        )
        perform_enqueued_jobs

        expect(Event.last.event_type).to eq("appropriate_body_claims_teacher")
      end
    end

    context 'when registering an existing teacher' do
      context "when the teacher has no induction period" do
        let!(:existing_teacher) { FactoryBot.create(:teacher, trn: "1234567") }

        it "updates the existing teacher and creates a new induction period" do
          expect {
            subject.register(pending_induction_submission_params)
          }.to change(Teacher, :count).by(0)
            .and change(InductionPeriod, :count).by(1)

          existing_teacher.reload
          expect(existing_teacher.trs_first_name).to eq("John")
          expect(existing_teacher.trs_last_name).to eq("Doe")

          induction_period = InductionPeriod.last
          expect(induction_period.teacher).to eq(existing_teacher)
        end
      end

      context "when the teacher's name changes" do
        let!(:existing_teacher) { FactoryBot.create(:teacher, trn: "1234567", trs_first_name: "Jonathan", trs_last_name: "Dole") }

        before do
          subject.register(pending_induction_submission_params)
          existing_teacher.reload
        end

        it 'records the name change' do
          expect(existing_teacher.trs_first_name).to eql(pending_induction_submission_params[:trs_first_name])
          expect(existing_teacher.trs_last_name).to eql(pending_induction_submission_params[:trs_last_name])
          expect(Events::Record).to have_received(:new).with(
            hash_including(
              author:,
              event_type: :teacher_name_updated_by_trs,
              appropriate_body:,
              teacher: existing_teacher,
              heading: "Name changed from Jonathan Dole to John Doe"
            )
          )

          perform_enqueued_jobs

          expect(Event.all.map(&:event_type)).to match_array(%w[teacher_name_updated_by_trs appropriate_body_claims_teacher])
        end

        it 'saves the pending_induction_submission' do
          induction_period = InductionPeriod.last
          expect(induction_period.teacher).to eq(existing_teacher)
          expect(induction_period.started_on).to eq(Date.new(2023, 5, 2))
          expect(induction_period.appropriate_body).to eq(appropriate_body)
          expect(induction_period.induction_programme).to eq("fip")
        end
      end
    end

    xcontext "when the teacher already has an induction period" do
      let!(:existing_teacher) { FactoryBot.create(:teacher, trn: "1234567") }
      let!(:existing_induction_period) { FactoryBot.create(:induction_period, teacher: existing_teacher) }

      it "raises TeacherAlreadyClaimedError" do
        expect {
          subject.register(pending_induction_submission_params)
        }.to raise_error(AppropriateBodies::Errors::TeacherAlreadyClaimedError, "Teacher already claimed")
      end
    end

    it "assigns provided params to the pending_induction_submission" do
      subject.register(pending_induction_submission_params)

      expect(subject.pending_induction_submission.induction_programme).to eq("fip")
      expect(subject.pending_induction_submission.started_on).to eq(Date.new(2023, 5, 2))
    end
  end
end
