RSpec.describe Admin::TeacherPresenter do
  subject(:presenter) { described_class.new(teacher) }

  let(:teacher) { FactoryBot.create(:teacher, api_id: SecureRandom.uuid, corrected_name: "Corrected Name") }
  let(:school) { FactoryBot.create(:school) }

  describe "#most_recent_email" do
    context "when there are ECT and mentor periods" do
      before do
        FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:, email: "ect@example.com", started_on: 2.months.ago)
        FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school:, email: "mentor@example.com", started_on: 1.month.ago)
      end

      it "returns the email from the most recent period" do
        expect(presenter.most_recent_email).to eq("mentor@example.com")
      end
    end

    context "when no period email is present" do
      it "falls back to the no email message" do
        expect(presenter.most_recent_email).to eq("No email recorded")
      end
    end
  end

  describe "#current_schools" do
    context "when the teacher has ongoing ECT periods" do
      before { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:) }

      it "includes the school from the ongoing period" do
        expect(presenter.current_schools).to include(school)
      end
    end

    context "when there are no ongoing periods" do
      it "is empty" do
        expect(presenter.current_schools).to be_empty
      end
    end
  end

  describe "#induction_status" do
    context "when the teacher is an Early Career Teacher" do
      let(:teacher) do
        FactoryBot.create(:teacher, api_id: SecureRandom.uuid, trs_induction_status: "InProgress").tap do |t|
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher: t, school:)
          FactoryBot.create(:induction_period, :ongoing, teacher: t)
        end
      end

      it "returns the human readable status" do
        expect(presenter.induction_status).to eq("In progress")
      end
    end

    context "when the teacher is not an Early Career Teacher" do
      it "returns nil" do
        expect(presenter.induction_status).to be_nil
      end
    end
  end

  describe "#api_participant_id" do
    it "returns the teachers api id when present" do
      expect(presenter.api_participant_id).to eq(teacher.api_id)
    end

    it "returns a fallback when api id is missing" do
      allow(teacher).to receive(:api_id).and_return(nil)
      expect(presenter.api_participant_id).to eq("Not available")
    end
  end
end
