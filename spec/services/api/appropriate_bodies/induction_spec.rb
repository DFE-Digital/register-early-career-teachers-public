RSpec.describe API::AppropriateBodies::Induction do
  subject(:induction) { described_class.new(appropriate_body:, client:) }

  include_context "test TRS API returns a teacher"

  let(:appropriate_body) { FactoryBot.create(:appropriate_body_period, name: "Golden Leaf Teaching School Hub") }
  let(:client) { FactoryBot.create(:api_oauth_client) }
  let(:claimed_from) { 1.month.ago.to_date }
  let(:claim_params) { { trn: "1234567", date_of_birth: "2001-05-13", claimed_from:, training_programme: "school_led" } }

  describe "#claim!" do
    it "registers the ECT with the appropriate body and returns the claim" do
      claim = induction.claim!(**claim_params)
      teacher = Teacher.find_by!(trn: "1234567")

      expect(claim.symbolize_keys).to eq(trn: "1234567", full_name: "Kirk Van Houten", claimed_from:, training_programme: "school_led")
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

    it "raises already claimed when the teacher has an ongoing induction" do
      another_appropriate_body = FactoryBot.create(:appropriate_body_period, name: "Canvas Teaching School Hub")
      induction.claim!(**claim_params)

      expect { induction.claim!(**claim_params) }
        .to raise_error(described_class::AlreadyClaimed, "The teacher already has an ongoing induction period with this appropriate body")
      expect { described_class.new(appropriate_body: another_appropriate_body, client:).claim!(**claim_params) }
        .to raise_error(described_class::AlreadyClaimed, "The teacher has an ongoing induction period with another appropriate body")
    end

    it "raises a validation error when the claim is invalid" do
      expect { induction.claim!(**claim_params, date_of_birth: nil) }
        .to raise_error(described_class::Invalid, /Enter a date of birth/)
    end

    it "only reports errors on the fields the caller sends" do
      training_programme_error = [[:training_programme, "Choose an induction training programme"]]

      expect { induction.claim!(**claim_params, training_programme: "bogus") }
        .to raise_error(described_class::Invalid) { expect(it.errors.map { [it.attribute, it.message] }).to eq(training_programme_error) }
      expect { induction.claim!(**claim_params.except(:training_programme)) }
        .to raise_error(described_class::Invalid) { expect(it.errors.map { [it.attribute, it.message] }).to eq(training_programme_error) }
    end

    context "when TRS cannot find the teacher" do
      include_context "test TRS API returns nothing"

      it "raises not found" do
        expect { induction.claim!(**claim_params) }
          .to raise_error(described_class::TeacherNotFound, "Nothing could be found for the provided details")
      end
    end

    context "when TRS is unavailable" do
      include_context "test TRS API is unavailable"

      it "raises TRS unavailable" do
        expect { induction.claim!(**claim_params) }
          .to raise_error(described_class::TRSUnavailable, "The Teaching Record System is unavailable. Try again later.")
      end
    end

    context "when TRS times out" do
      include_context "test TRS API times out"

      it "raises TRS unavailable" do
        expect { induction.claim!(**claim_params) }
          .to raise_error(described_class::TRSUnavailable, "The Teaching Record System is unavailable. Try again later.")
      end
    end

    context "when the teacher is prohibited from teaching" do
      include_context "test TRS API returns a teacher prohibited from teaching"

      it "raises not eligible" do
        expect { induction.claim!(**claim_params) }
          .to raise_error(described_class::NotEligible, "The teacher is prohibited from teaching")
      end
    end

    context "when the teacher is deactivated in TRS" do
      include_context "test TRS API returns a deactivated teacher"

      it "raises not found" do
        expect { induction.claim!(**claim_params) }
          .to raise_error(described_class::TeacherNotFound, "Nothing could be found for the provided details")
      end
    end

    context "when the teacher has been merged in TRS" do
      include_context "test TRS API returns a merged teacher"

      it "raises not found" do
        expect { induction.claim!(**claim_params) }
          .to raise_error(described_class::TeacherNotFound, "Nothing could be found for the provided details")
      end
    end

    context "when the teacher has already completed their induction" do
      include_context "test TRS API returns a teacher that has passed their induction"

      it "raises not eligible" do
        expect { induction.claim!(**claim_params) }
          .to raise_error(described_class::NotEligible, "The teacher has already completed their induction")
      end
    end

    context "when the teacher has not been awarded QTS" do
      include_context "test TRS API returns a teacher without QTS"

      it "raises not eligible" do
        expect { induction.claim!(**claim_params) }
          .to raise_error(described_class::NotEligible, "The teacher has not been awarded QTS")
      end
    end
  end

  describe "#pass!" do
    let(:teacher) { FactoryBot.create(:teacher, :with_name) }
    let!(:induction_period) { FactoryBot.create(:induction_period, :unfinished, teacher:, appropriate_body_period: appropriate_body) }
    let(:passed_on) { 1.day.ago.to_date }

    it "records the pass and returns it" do
      pass = induction.pass!(trn: teacher.trn, passed_on:, number_of_terms: 3)

      expect(pass.symbolize_keys).to eq(trn: teacher.trn, full_name: "John Keating", passed_on:, number_of_terms: 3.0)
      expect(induction_period.reload).to be_pass_outcome
      expect(Event.where(teacher:, event_type: "teacher_passes_induction").sole).to have_attributes(oauth_client: client)
    end

    it "raises not found when the teacher has no ongoing induction with the appropriate body" do
      another_appropriate_body = FactoryBot.create(:appropriate_body_period, name: "Canvas Teaching School Hub")
      passed_teacher = FactoryBot.create(:teacher)
      FactoryBot.create(:induction_period, :pass, teacher: passed_teacher, appropriate_body_period: appropriate_body)

      expect { described_class.new(appropriate_body: another_appropriate_body, client:).pass!(trn: teacher.trn, passed_on:, number_of_terms: 3) }
        .to raise_error(described_class::TeacherNotFound)
      expect { induction.pass!(trn: "0000000", passed_on:, number_of_terms: 3) }
        .to raise_error(described_class::TeacherNotFound)
      expect { induction.pass!(trn: passed_teacher.trn, passed_on:, number_of_terms: 3) }
        .to raise_error(described_class::TeacherNotFound)
      expect(induction_period.reload.outcome).to be_nil
    end

    it "raises a validation error when the pass is invalid" do
      expect { induction.pass!(trn: teacher.trn, passed_on:) }
        .to raise_error(described_class::Invalid, /Enter a number of terms/)
      expect { induction.pass!(trn: teacher.trn, passed_on: 1.day.from_now.to_date, number_of_terms: 3) }
        .to raise_error(described_class::Invalid, /End date cannot be in the future/)
      expect(induction_period.reload.outcome).to be_nil
    end
  end

  describe "#release!" do
    let(:teacher) { FactoryBot.create(:teacher, :with_name) }
    let!(:induction_period) { FactoryBot.create(:induction_period, :unfinished, teacher:, appropriate_body_period: appropriate_body) }
    let(:released_on) { 1.day.ago.to_date }

    it "records the release and returns the released induction" do
      release = induction.release!(trn: teacher.trn, released_on:, number_of_terms: 3)

      expect(release.symbolize_keys).to eq(trn: teacher.trn, full_name: "John Keating", released_on:, number_of_terms: 3.0)
      expect(induction_period.reload).to have_attributes(finished_on: released_on, outcome: nil)
      expect(Event.where(teacher:, event_type: "induction_period_closed").sole).to have_attributes(oauth_client: client)
    end

    it "raises not found when the teacher has no ongoing induction with the appropriate body" do
      another_appropriate_body = FactoryBot.create(:appropriate_body_period, name: "Canvas Teaching School Hub")
      released_teacher = FactoryBot.create(:teacher)
      FactoryBot.create(:induction_period, teacher: released_teacher, appropriate_body_period: appropriate_body)

      expect { described_class.new(appropriate_body: another_appropriate_body, client:).release!(trn: teacher.trn, released_on:, number_of_terms: 3) }
        .to raise_error(described_class::TeacherNotFound)
      expect { induction.release!(trn: "0000000", released_on:, number_of_terms: 3) }
        .to raise_error(described_class::TeacherNotFound)
      expect { induction.release!(trn: released_teacher.trn, released_on:, number_of_terms: 3) }
        .to raise_error(described_class::TeacherNotFound)
      expect(induction_period.reload.finished_on).to be_nil
    end

    it "raises a validation error when the release is invalid" do
      expect { induction.release!(trn: teacher.trn, released_on:) }
        .to raise_error(described_class::Invalid, /Enter a number of terms/)
      expect { induction.release!(trn: teacher.trn, released_on: 1.day.from_now.to_date, number_of_terms: 3) }
        .to raise_error(described_class::Invalid, /End date cannot be in the future/)
      expect(induction_period.reload.finished_on).to be_nil
    end
  end
end
