RSpec.describe EROMentorChecker do
  subject(:checker) { described_class.new(participant_profile: profile) }

  let(:profile) { FactoryBot.create(:migration_participant_profile, :mentor) }

  describe "#ero_mentor?" do
    context "when the participant is a mentor" do
      context "when they were not part of ERO" do
        it "returns false" do
          expect(checker).not_to be_ero_mentor
        end
      end

      context "when they were part of ERO" do
        before do
          FactoryBot.create(:migration_ecf_ineligible_participant, trn: profile.teacher_profile.trn)
        end

        it "returns true" do
          expect(checker).to be_ero_mentor
        end
      end
    end

    context "when the participant is not a mentor" do
      let(:profile) { FactoryBot.create(:migration_participant_profile, :ect) }

      it "returns false" do
        expect(checker).not_to be_ero_mentor
      end
    end
  end

  describe "#relevant_declarations" do
    context "when they had a paid declaration" do
      let!(:declaration) { FactoryBot.create(:migration_participant_declaration, participant_profile: profile, state: :paid) }

      it "returns the declaration" do
        expect(checker.relevant_declarations).to eq [declaration]
      end
    end

    context "when they had a clawed_back declaration" do
      let!(:declaration) { FactoryBot.create(:migration_participant_declaration, participant_profile: profile, state: :clawed_back) }

      it "returns the declaration" do
        expect(checker.relevant_declarations).to eq [declaration]
      end
    end

    context "when they had a declaration that wasn't paid or clawed_back" do
      let!(:declaration) { FactoryBot.create(:migration_participant_declaration, participant_profile: profile, state: :clawed_back) }

      %i[submitted eligible payable voided ineligible awaiting_clawback].each do |state|
        it "does not return those declarations" do
          FactoryBot.create(:migration_participant_declaration, participant_profile: profile, state:)
          expect(checker.relevant_declarations).to eq [declaration]
        end
      end
    end
  end
end
