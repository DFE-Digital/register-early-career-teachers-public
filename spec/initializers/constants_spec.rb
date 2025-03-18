RSpec.describe "Constants" do
  describe "STATUTORY_INDUCTION_ROLLOUT_DATE" do
    it { expect(STATUTORY_INDUCTION_ROLLOUT_DATE).to eq(Date.new(1999, 9, 1)) }
  end

  describe "ECF_ROLLOUT_DATE" do
    it { expect(ECF_ROLLOUT_DATE).to eq(Date.new(2021, 9, 1)) }
  end

  describe "PROGRAMME_TYPES" do
    it { expect(PROGRAMME_TYPES).to eq({ provider_led: 'Provider-led', school_led: 'School-led' }) }
  end

  describe "INDUCTION_PROGRAMMES" do
    it { expect(INDUCTION_PROGRAMMES).to eq({ fip: 'Full induction programme', cip: 'Core induction programme', diy: 'School-based induction programme' }) }
  end

  describe "INDUCTION_OUTCOMES" do
    it { expect(INDUCTION_OUTCOMES).to eq({ pass: 'Passed', fail: 'Failed' }) }
  end

  describe "WORKING_PATTERNS" do
    it { expect(WORKING_PATTERNS).to eq({ part_time: 'Part-time', full_time: 'Full-time' }) }
  end
end
