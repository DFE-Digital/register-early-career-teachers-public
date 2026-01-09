RSpec.shared_context "it closes an induction" do
  subject(:service) do
    described_class.new(teacher:, appropriate_body:, author:)
  end

  include_context "test trs api client"

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

  it "deletes the pending induction submission after a day" do
    freeze_time do
      service_call
      expect(PendingInductionSubmission.count).to be(1)
      expect(PendingInductionSubmission.last.delete_at).to eql(24.hours.from_now)
    end
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
end
