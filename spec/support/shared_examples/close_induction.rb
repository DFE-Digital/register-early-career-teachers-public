RSpec.shared_context "it closes an induction" do
  subject(:service) do
    described_class.new(teacher:, appropriate_body:, author:)
  end

  include_context "test TRS API returns a teacher"

  let(:author) do
    FactoryBot.create(:appropriate_body_user,
                      dfe_sign_in_organisation_id: appropriate_body.dfe_sign_in_organisation_id)
  end

  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:teacher) { FactoryBot.create(:teacher) }

  let(:service_call) do
    service.call(finished_on: 1.day.ago.to_date, number_of_terms: 6)
  end

  let!(:induction_period) do
    FactoryBot.create(:induction_period, :ongoing,
                      appropriate_body:,
                      teacher:)
  end

  let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, :with_training_period, teacher:) }

  it "deletes the pending induction submission after a day" do
    freeze_time do
      service_call
      expect(PendingInductionSubmission.count).to be(1)
      expect(PendingInductionSubmission.last.delete_at).to eql(24.hours.from_now)
    end
  end

  it "does not log events for a teacher leaving school" do
    expect(Events::Record).not_to receive(:record_teacher_left_school_as_ect!)
    expect(Events::Record).not_to receive(:record_teacher_finishes_training_period_event!)
    expect(Events::Record).not_to receive(:record_teacher_finishes_mentoring_event!)
    expect(Events::Record).not_to receive(:record_teacher_finishes_being_mentored_event!)

    service_call
  end

  context "without an ongoing induction period" do
    let!(:induction_period) {}

    it do
      expect { service_call }.to raise_error(AppropriateBodies::CloseInduction::TeacherHasNoOngoingInductionPeriod)
    end
  end

  context "with invalid values" do
    let(:service_call) do
      service.call(finished_on: 1.day.from_now.to_date, number_of_terms: 16.99)
    end

    it "does not update the induction period" do
      expect { service_call }.to(raise_error do |error|
        expect(error).to be_a(ActiveRecord::RecordInvalid).or be_a(ActiveModel::ValidationError)
      end)

      expect(service.errors.size).not_to be_zero
    end
  end

  context "with an ongoing ECT period" do
    let(:school) { ect_at_school_period.school }
    let(:mentor_teacher) { FactoryBot.create(:teacher) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: mentor_teacher, school:) }
    let!(:mentorship_period) { FactoryBot.create(:mentorship_period, :ongoing, mentor: mentor_at_school_period, mentee: ect_at_school_period) }
    let(:ect_service) { ECTAtSchoolPeriods::Finish }

    before do
      allow(ect_service).to receive(:new).and_call_original
    end

    it "calls ECT finish service which finishes ongoing ECT and mentorship periods" do
      service_call

      expect(ect_service).to have_received(:new).with(ect_at_school_period:, finished_on: 1.day.ago.to_date, author:, record_event: false).once
      expect(ect_at_school_period.reload.finished_on).to eql(1.day.ago.to_date)
      expect(mentorship_period.reload.finished_on).to eql(1.day.ago.to_date)
    end
  end
end
