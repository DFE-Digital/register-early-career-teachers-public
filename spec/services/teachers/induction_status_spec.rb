require "rails_helper"

RSpec.describe Teachers::InductionStatus do
  subject { Teachers::InductionStatus.new(teacher:, induction_periods:, trs_induction_status:) }

  context 'when the teacher record exists in our database' do
    let(:trs_induction_status) { nil }

    context 'when the ECT has an open induction period' do
      let(:teacher) { FactoryBot.create(:teacher) }
      let(:induction_periods) do
        [
          FactoryBot.create(:induction_period),
          FactoryBot.create(:induction_period, :active)
        ]
      end

      it "has a status of 'In progress'" do
        expect(subject.induction_status).to eql('In progress')
      end
    end

    context 'when the ECT has no open induction period' do
      let(:teacher) { FactoryBot.create(:teacher) }

      context 'when there is no induction outcome' do
        let(:induction_periods) { FactoryBot.create_list(:induction_period, 2) }

        it "has a status of 'Paused'" do
          expect(subject.induction_status).to eql('Induction paused')
        end
      end

      context 'when there is a :pass outcome' do
        let(:induction_periods) do
          [
            FactoryBot.create(:induction_period),
            FactoryBot.create(:induction_period, :pass)
          ]
        end

        it "has a status of 'Passed'" do
          expect(subject.induction_status).to eql('Passed')
        end
      end

      context 'when there is a :fail outcome' do
        let(:induction_periods) do
          [
            FactoryBot.create(:induction_period),
            FactoryBot.create(:induction_period, :fail)
          ]
        end

        it "has a status of 'Failed'" do
          expect(subject.induction_status).to eql('Failed')
        end
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
        "PassedInWales" => "Passed in Wales",
        "None" => "None",
      }.each do |trs_induction_status, our_description|
        context "when the trs_induction_status is #{trs_induction_status}" do
          let(:our_description) { our_description }
          let(:trs_induction_status) { trs_induction_status }

          it "has a status of '#{our_description}'" do
            expect(subject.induction_status).to eql(our_description)
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
      expect(subject.induction_status).to eql('Unknown')
    end
  end

  describe "#completed?" do
    let(:teacher) { nil }
    let(:induction_periods) { [] }

    %w[
      Exempt
      Passed
      Failed
      PassedInWales
      FailedInWales
    ].each do |status|
      context "with complete TRS status (#{status})" do
        let(:trs_induction_status) { status }

        it "returns true" do
          expect(subject).to be_completed
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
          expect(subject).not_to be_completed
        end
      end
    end
  end
end
