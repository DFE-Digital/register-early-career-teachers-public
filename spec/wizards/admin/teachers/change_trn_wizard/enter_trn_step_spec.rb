RSpec.describe Admin::Teachers::ChangeTRNWizard::EnterTRNStep do
  subject(:step) { described_class.new(trn:, wizard:) }

  let(:trn) { "12345" }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:wizard) { double("ChangeTRNWizard", store:) }
  let(:api_client) { instance_double(TRS::APIClient) }

  let(:trs_teacher) do
    TRS::Teacher.new(
      "trn" => "0012345",
      "firstName" => "Sarah",
      "lastName" => "Jones"
    )
  end

  before do
    allow(TRS::APIClient).to receive(:build).and_return(api_client)
    allow(api_client).to receive(:find_teacher)
      .with(trn: "0012345")
      .and_return(trs_teacher)
  end

  describe "#save!" do
    it "looks up the formatted TRN and stores the proposed details" do
      expect(step.save!).to be(true)

      expect(api_client).to have_received(:find_teacher)
        .with(trn: "0012345")

      expect(store.trn).to eq("0012345")
      expect(store.trs_first_name).to eq("Sarah")
      expect(store.trs_last_name).to eq("Jones")
    end

    context "when the TRN is too short" do
      let(:trn) { "1234" }

      it "returns an error without looking up the TRN" do
        expect(step.save!).to be(false)

        expect(step.errors[:trn]).to include(
          "Teacher reference number must include at least 5 digits"
        )
        expect(api_client).not_to have_received(:find_teacher)
        expect(store.trn).to be_nil
      end
    end

    context "when the TRN is too long" do
      let(:trn) { "12345678" }

      it "returns an error without looking up the TRN" do
        expect(step.save!).to be(false)

        expect(step.errors[:trn]).to include(
          "Teacher reference number cannot include more than 7 digits"
        )
        expect(api_client).not_to have_received(:find_teacher)
        expect(store.trn).to be_nil
      end
    end

    context "when the TRN is blank" do
      let(:trn) { "" }

      it "asks for a TRN without looking it up" do
        expect(step.save!).to be(false)

        expect(step.errors[:trn]).to include(
          "Enter the teacher reference number (TRN)"
        )
        expect(api_client).not_to have_received(:find_teacher)
        expect(store.trn).to be_nil
      end
    end

    context "when the TRN is not found in TRS" do
      before do
        allow(api_client).to receive(:find_teacher)
          .with(trn: "0012345")
          .and_raise(TRS::Errors::TeacherNotFound)
      end

      it "returns an error without storing the proposed details" do
        expect(step.save!).to be(false)

        expect(step.errors[:trn]).to include(
          "No teacher was found with this TRN"
        )
        expect(store.trn).to be_nil
        expect(store.trs_first_name).to be_nil
        expect(store.trs_last_name).to be_nil
      end
    end

    context "when the replacement TRN is deactivated in TRS" do
      before do
        allow(api_client).to receive(:find_teacher)
          .with(trn: "0012345")
          .and_raise(TRS::Errors::TeacherDeactivated)
      end

      it "returns an error without storing the proposed details" do
        expect(step.save!).to be(false)

        expect(step.errors[:trn]).to include(
          "This TRN has been deactivated"
        )
        expect(store.trn).to be_nil
        expect(store.trs_first_name).to be_nil
        expect(store.trs_last_name).to be_nil
      end
    end

    context "when an earlier lookup is stored and the new lookup fails" do
      before do
        store.trn = "7654321"
        store.trs_first_name = "Previous"
        store.trs_last_name = "Teacher"

        allow(api_client).to receive(:find_teacher)
          .with(trn: "0012345")
          .and_raise(TRS::Errors::TeacherNotFound)
      end

      it "clears the previous proposed details" do
        expect(step.save!).to be(false)

        expect(store.trn).to be_nil
        expect(store.trs_first_name).to be_nil
        expect(store.trs_last_name).to be_nil
      end
    end
  end
end
