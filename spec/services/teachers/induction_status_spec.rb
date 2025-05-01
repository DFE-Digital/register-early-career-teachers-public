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

      it "returns the correct status color" do
        expect(service.induction_status_colour).to eql('green')
      end
    end

    context 'when the ECT has induction periods' do
      let(:teacher) { FactoryBot.create(:teacher) }
      let(:trs_induction_status) { 'InProgress' }

      context 'with an ongoing induction period' do
        let(:induction_periods) do
          [
            FactoryBot.create(:induction_period, :active, teacher:)
          ]
        end

        it "has a status of 'Unknown'" do
          expect(service.induction_status).to eql('Unknown')
        end

        it "has a grey status color" do
          expect(service.induction_status_colour).to eql('grey')
        end
      end

      context 'with a completed induction period' do
        let(:induction_periods) do
          [
            FactoryBot.create(:induction_period, :pass, teacher:,
                                                        started_on: 2.years.ago,
                                                        finished_on: 1.year.ago)
          ]
        end

        it "has a status of 'Unknown'" do
          expect(service.induction_status).to eql('Unknown')
        end

        it "has a grey status color" do
          expect(service.induction_status_colour).to eql('grey')
        end
      end
    end
  end

  context 'when the teacher record does not exist in our database' do
    let(:teacher) { nil }
    let(:induction_periods) { [] }

    context 'when there is no induction outcome' do
      {
        "Exempt" => { text: "Exempt", colour: "green" },
        "RequiredToComplete" => { text: "Required to complete", colour: "yellow" },
        "Failed" => { text: "Failed", colour: "red" },
        "Passed" => { text: "Passed", colour: "green" },
        "FailedInWales" => { text: "Failed in Wales", colour: "red" },
        "None" => { text: "None", colour: "grey" },
      }.each do |trs_induction_status, expected|
        context "when the trs_induction_status is #{trs_induction_status}" do
          let(:trs_induction_status) { trs_induction_status }

          it "has a status of '#{expected[:text]}'" do
            expect(service.induction_status).to eql(expected[:text])
          end

          it "has a #{expected[:colour]} status color" do
            expect(service.induction_status_colour).to eql(expected[:colour])
          end
        end
      end

      context "when the trs_induction_status is InProgress" do
        let(:trs_induction_status) { "InProgress" }

        context "when there is no open induction period" do
          let(:induction_periods) do
            [
              FactoryBot.create(:induction_period,
                                started_on: 2.years.ago,
                                finished_on: 1.year.ago)
            ]
          end

          it "has a status of 'Induction paused'" do
            expect(service.induction_status).to eql("Induction paused")
          end

          it "has a pink status color" do
            expect(service.induction_status_colour).to eql("pink")
          end
        end

        context "when there is an open induction period" do
          let(:induction_periods) do
            [
              FactoryBot.create(:induction_period, :active)
            ]
          end

          it "has a status of 'In progress'" do
            expect(service.induction_status).to eql("In progress")
          end

          it "has a blue status color" do
            expect(service.induction_status_colour).to eql("blue")
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

    it "has a grey status color" do
      expect(service.induction_status_colour).to eql('grey')
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
