RSpec.describe Migration::Gantt do
  subject(:service) { described_class.new(induction_records, []) }

  let(:induction_record_1) { FactoryBot.create(:migration_induction_record) }
  let(:participant_profile) { induction_record_1.participant_profile }
  let!(:induction_record_2) { FactoryBot.create(:migration_induction_record, participant_profile:) }
  let(:induction_records) { Migration::InductionRecordExporter.new.where_participant_profile_id_is(participant_profile.id).rows }

  describe "#build" do
    it "returns a PLANTUML description" do
      puml = service.build
      expect(puml).to be_a String
      expect(puml).to match(/^@startgantt/)
      expect(puml).to match(/@endgantt$/)
    end
  end
end
