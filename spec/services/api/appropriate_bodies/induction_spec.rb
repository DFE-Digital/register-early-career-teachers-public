RSpec.describe API::AppropriateBodies::Induction do
  subject(:induction) { described_class.new(appropriate_body:, client:) }

  include_context "test TRS API returns a teacher"

  let(:appropriate_body) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:client) { FactoryBot.create(:api_oauth_client) }
  let(:started_on) { 1.month.ago.to_date }
  let(:claim_params) { { trn: "1234567", date_of_birth: "2001-05-13", started_on:, training_programme: "school_led" } }

  describe "#claim!" do
    it "registers the ECT with the appropriate body and returns the claim" do
      claim = induction.claim!(**claim_params)
      teacher = Teacher.find_by!(trn: "1234567")

      expect(claim.symbolize_keys).to eq(trn: "1234567", full_name: "Kirk Van Houten", started_on:, training_programme: "school_led")
      expect(teacher.ongoing_induction_period.appropriate_body_period).to eq(appropriate_body)
      expect(Event.where(teacher:)).to be_present.and all(have_attributes(oauth_client: client))
    end

    it "schedules the pending submission for deletion whether or not the claim succeeds" do
      another_appropriate_body = FactoryBot.create(:appropriate_body_period, name: "Canvas Teaching School Hub")

      induction.claim!(**claim_params)
      expect { described_class.new(appropriate_body: another_appropriate_body, client:).claim!(**claim_params) }
        .to raise_error(described_class::AlreadyClaimed)

      expect(PendingInductionSubmission.ready_for_deletion.map(&:appropriate_body_period))
        .to contain_exactly(appropriate_body, another_appropriate_body)
    end

    it "raises a validation error when the claim is invalid" do
      expect { induction.claim!(**claim_params, date_of_birth: nil) }
        .to raise_error(described_class::Invalid, /Enter a date of birth/)
    end
  end

  describe "#pass!" do
    let(:teacher) { FactoryBot.create(:teacher, :with_name) }
    let!(:induction_period) { FactoryBot.create(:induction_period, :unfinished, teacher:, appropriate_body_period: appropriate_body) }
    let(:finished_on) { 1.day.ago.to_date }

    it "records the pass and returns the outcome" do
      outcome = induction.pass!(trn: teacher.trn, finished_on:, number_of_terms: 3)

      expect(outcome.symbolize_keys).to eq(trn: teacher.trn, full_name: "John Keating", finished_on:, number_of_terms: 3.0, outcome: "pass")
      expect(induction_period.reload).to be_pass_outcome
      expect(Event.where(teacher:, event_type: "teacher_passes_induction").sole).to have_attributes(oauth_client: client)
    end

    it "raises not found when the teacher has no ongoing induction with the appropriate body" do
      another_appropriate_body = FactoryBot.create(:appropriate_body_period, name: "Canvas Teaching School Hub")

      expect { described_class.new(appropriate_body: another_appropriate_body, client:).pass!(trn: teacher.trn, finished_on:, number_of_terms: 3) }
        .to raise_error(described_class::TeacherNotFound)
    end

    it "raises a validation error when the pass is invalid" do
      expect { induction.pass!(trn: teacher.trn, finished_on:) }
        .to raise_error(described_class::Invalid, /Enter a number of terms/)
    end
  end

  describe "#release!" do
    let(:teacher) { FactoryBot.create(:teacher, :with_name) }
    let!(:induction_period) { FactoryBot.create(:induction_period, :unfinished, teacher:, appropriate_body_period: appropriate_body) }
    let(:finished_on) { 1.day.ago.to_date }

    it "records the release and returns the released induction" do
      release = induction.release!(trn: teacher.trn, finished_on:, number_of_terms: 3)

      expect(release.symbolize_keys).to eq(trn: teacher.trn, full_name: "John Keating", finished_on:, number_of_terms: 3.0)
      expect(induction_period.reload).to have_attributes(finished_on:, outcome: nil)
      expect(Event.where(teacher:, event_type: "induction_period_closed").sole).to have_attributes(oauth_client: client)
    end

    it "raises not found when the teacher has no ongoing induction with the appropriate body" do
      another_appropriate_body = FactoryBot.create(:appropriate_body_period, name: "Canvas Teaching School Hub")

      expect { described_class.new(appropriate_body: another_appropriate_body, client:).release!(trn: teacher.trn, finished_on:, number_of_terms: 3) }
        .to raise_error(described_class::TeacherNotFound)
    end

    it "raises a validation error when the release is invalid" do
      expect { induction.release!(trn: teacher.trn, finished_on:) }
        .to raise_error(described_class::Invalid, /Enter a number of terms/)
    end
  end
end
