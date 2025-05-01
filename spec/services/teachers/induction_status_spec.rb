RSpec.describe Teachers::InductionStatus do
  subject(:service) { described_class.new(teacher:, induction_periods:, trs_induction_status:) }

  context 'when the teacher record exists in our database' do
    let(:trs_induction_status) { nil }

    context 'when the ECT has no induction periods' do
      let(:teacher) { FactoryBot.create(:teacher) }
      let(:induction_periods) { [] }
      let(:trs_induction_status) { 'Exempt' }

      it "returns the TRS induction status" do
        expect(service.induction_status).to eql('Exempt')
      end
    end
  end

  context 'when the teacher record does not exist in our database' do
    let(:teacher) { nil }
    let(:induction_periods) { [] }

    context 'when there is no induction outcome' do
      {
        "Exempt" => "Exempt",
        "RequiredToComplete" => "Required to complete",
        "InProgress" => "In progress",
        "Failed" => "Failed",
        "Passed" => "Passed",
        "FailedInWales" => "Failed in Wales",
        "None" => "None",
      }.each do |trs_induction_status, our_description|
        context "when the trs_induction_status is #{trs_induction_status}" do
          let(:our_description) { our_description }
          let(:trs_induction_status) { trs_induction_status }

          it "has a status of '#{our_description}'" do
            expect(service.induction_status).to eql(our_description)
          end
        end
      end
    end
  end

  context 'when no conditions are matched' do
    let(:teacher) { nil }
    let(:induction_periods) { [] }
    let(:trs_induction_status) { 'SomethingEntirelyDifferent' }

    it "has a status of 'Unknown'" do
      expect(service.induction_status).to eql('Unknown')
    end
  end

  describe "#completed?" do
    let(:teacher) { nil }
    let(:induction_periods) { [] }

    %w[
      Exempt
      Passed
      Failed
      FailedInWales
    ].each do |status|
      context "with complete TRS status (#{status})" do
        let(:trs_induction_status) { status }

        it "returns true" do
          expect(service).to be_completed
        end
      end
    end

    %w[
      InProgress
      RequiredToComplete
      None
      Paused
    ].each do |status|
      context "with incomplete TRS status (#{status})" do
        let(:trs_induction_status) { status }

        it "returns false" do
          expect(service).not_to be_completed
        end
      end
    end
  end
end
