RSpec.describe Teachers::TRN::Resolver do
  describe ".new_trn" do
    subject { described_class.new(teacher:, proposed_trn:).new_trn }

    let(:proposed_trn) { "7654321" }

    context "when the teacher is deactivated and no proposed TRN is supplied" do
      let(:teacher) { FactoryBot.create(:teacher, :deactivated_in_trs) }
      let(:proposed_trn) { nil }

      it "raises a ProposedTRNError" do
        expect { subject }
          .to raise_error(Teachers::TRN::Resolver::ProposedTRNError)
      end
    end

    context "when the teacher is redirected and trs_redirected_to is missing" do
      let(:teacher) do
        FactoryBot.create(:teacher, :merged_in_trs, trs_redirected_to: nil)
      end

      it "raises a ProposedTRNError" do
        expect { subject }
          .to raise_error(Teachers::TRN::Resolver::ProposedTRNError)
      end
    end

    context "when the teacher is redirected and a proposed TRN is supplied" do
      let(:teacher) do
        FactoryBot.create(:teacher, :merged_in_trs, trs_redirected_to: "1234567")
      end

      it "returns the redirected TRN" do
        expect(subject).to eq("1234567")
      end
    end

    context "when the teacher is deactivated and proposed TRN is supplied" do
      let(:teacher) { FactoryBot.create(:teacher, :deactivated_in_trs) }

      it "returns the proposed TRN" do
        expect(subject).to eq("7654321")
      end
    end
  end
end
