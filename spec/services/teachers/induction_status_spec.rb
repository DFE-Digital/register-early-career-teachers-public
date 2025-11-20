RSpec.describe Teachers::InductionStatus do
  subject(:service) do
    described_class.new(trs_induction_status:, teacher:)
  end

  let(:teacher) { nil }
  let(:trs_induction_status) { nil }

  describe "RequiredToComplete" do
    let(:trs_induction_status) { "RequiredToComplete" }

    it "has a yellow 'Required to complete' status" do
      expect(service.induction_status).to eql("Required to complete")
      expect(service.induction_status_colour).to eql("yellow")
    end
  end

  describe "Exempt" do
    let(:trs_induction_status) { "Exempt" }

    it "has a green 'Exempt' status" do
      expect(service.induction_status).to eql("Exempt")
      expect(service.induction_status_colour).to eql("green")
    end
  end

  describe "Passed" do
    let(:trs_induction_status) { "Passed" }

    it "has a green 'Passed' status" do
      expect(service.induction_status).to eql("Passed")
      expect(service.induction_status_colour).to eql("green")
    end
  end

  describe "Failed" do
    let(:trs_induction_status) { "Failed" }

    it "has a red 'Failed' status" do
      expect(service.induction_status).to eql("Failed")
      expect(service.induction_status_colour).to eql("red")
    end
  end

  describe "FailedInWales" do
    let(:trs_induction_status) { "FailedInWales" }

    it "has a red 'Failed in Wales' status" do
      expect(service.induction_status).to eql("Failed in Wales")
      expect(service.induction_status_colour).to eql("red")
    end
  end

  describe "InProgress" do
    let(:trs_induction_status) { "InProgress" }

    context "without a teacher" do
      it "has a pink 'Induction paused' status" do
        expect(service.induction_status).to eql("Induction paused")
        expect(service.induction_status_colour).to eql("pink")
      end
    end

    context "with a teacher" do
      let(:teacher) { FactoryBot.create(:teacher) }

      context "with an ongoing induction period" do
        before do
          FactoryBot.create(:induction_period, :ongoing,
                            teacher:)
        end

        it "has a blue 'In progress' status" do
          expect(service.induction_status).to eql("In progress")
          expect(service.induction_status_colour).to eql("blue")
        end
      end

      context "without an ongoing induction period" do
        let(:teacher) { FactoryBot.create(:teacher) }

        before do
          FactoryBot.create(:induction_period,
                            teacher:,
                            started_on: 2.years.ago,
                            finished_on: 1.year.ago)
        end

        it "overrides with a pink 'Induction paused' status" do
          expect(service.induction_status).to eql("Induction paused")
          expect(service.induction_status_colour).to eql("pink")
        end
      end
    end
  end

  describe "None" do
    let(:trs_induction_status) { "None" }

    it "has a grey 'None' status" do
      expect(service.induction_status).to eql("None")
      expect(service.induction_status_colour).to eql("grey")
    end
  end

  describe "Other" do
    context "and a nil status" do
      it "has a grey 'Unknown' status" do
        expect(service.induction_status).to eql("Unknown")
        expect(service.induction_status_colour).to eql("grey")
      end
    end

    context "and an empty status" do
      let(:trs_induction_status) { "" }

      it "has a grey 'Unknown' status" do
        expect(service.induction_status).to eql("Unknown")
        expect(service.induction_status_colour).to eql("grey")
      end
    end

    context "and an unknown status" do
      let(:trs_induction_status) { "SomethingEntirelyDifferent" }

      it "has a grey 'Unknown' status" do
        expect(service.induction_status).to eql("Unknown")
        expect(service.induction_status_colour).to eql("grey")
      end
    end
  end
end
