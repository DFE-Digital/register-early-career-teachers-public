describe ECF2TeacherHistory::MentorshipPeriod do
  subject(:mentorship_period) do
    described_class.new(
      started_on:,
      finished_on:,
      ecf_start_induction_record_id:,
      ecf_end_induction_record_id:,
      mentor_at_school_period_id:,
      api_ect_training_record_id:,
      api_mentor_training_record_id:
    )
  end

  let(:started_on) { 1.year.ago }
  let(:finished_on) { 1.week.ago }
  let(:ecf_start_induction_record_id) { SecureRandom.uuid }
  let(:ecf_end_induction_record_id) { SecureRandom.uuid }
  let(:mentor_at_school_period_id) { SecureRandom.uuid }
  let(:api_ect_training_record_id) { SecureRandom.uuid }
  let(:api_mentor_training_record_id) { SecureRandom.uuid }

  describe ".initialize" do
    it "correctly stores params" do
      expect(mentorship_period.started_on).to eq started_on
      expect(mentorship_period.finished_on).to eq finished_on
      expect(mentorship_period.ecf_start_induction_record_id).to eq ecf_start_induction_record_id
      expect(mentorship_period.ecf_end_induction_record_id).to eq ecf_end_induction_record_id
      expect(mentorship_period.mentor_at_school_period_id).to eq mentor_at_school_period_id
      expect(mentorship_period.api_ect_training_record_id).to eq api_ect_training_record_id
      expect(mentorship_period.api_mentor_training_record_id).to eq api_mentor_training_record_id
    end
  end

  describe "attributes" do
    it "permits them to be updated" do
      mentorship_period.instance_variables.each do |var|
        getter = var.to_s.gsub(/@/, "")
        setter = "#{getter}="
        mentorship_period.send(setter.to_sym, "banana")
        expect(mentorship_period.send(getter.to_sym)).to eq "banana"
      end
    end
  end

  describe "#to_h" do
    let(:expected_value) do
      {
        started_on:,
        finished_on:,
        ecf_start_induction_record_id:,
        ecf_end_induction_record_id:,
        mentor_at_school_period_id:
      }
    end

    it "provides a hash of values" do
      expect(mentorship_period.to_h).to match(expected_value)
    end
  end
end
