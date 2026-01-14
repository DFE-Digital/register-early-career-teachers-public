describe Migration::PreMigrationGantt do
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

    context "when records at the same school are not consecutive by date" do
      let(:school_a) { FactoryBot.create(:ecf_migration_school, urn: "100001") }
      let(:school_b) { FactoryBot.create(:ecf_migration_school, urn: "100002") }
      let(:school_cohort_a) { FactoryBot.create(:migration_school_cohort, school: school_a) }
      let(:school_cohort_b) { FactoryBot.create(:migration_school_cohort, school: school_b) }
      let(:induction_programme_a) { FactoryBot.create(:migration_induction_programme, school_cohort: school_cohort_a) }
      let(:induction_programme_b) { FactoryBot.create(:migration_induction_programme, school_cohort: school_cohort_b) }

      let(:induction_record_1) do
        FactoryBot.create(:migration_induction_record, induction_programme: induction_programme_a, start_date: Date.new(2022, 9, 1), end_date: Date.new(2023, 8, 31))
      end

      let!(:induction_record_2) do
        FactoryBot.create(:migration_induction_record, participant_profile:, induction_programme: induction_programme_b, start_date: Date.new(2023, 9, 1), end_date: Date.new(2024, 8, 31))
      end

      let!(:induction_record_3) do
        FactoryBot.create(:migration_induction_record, participant_profile:, induction_programme: induction_programme_a, start_date: Date.new(2024, 9, 1), end_date: nil)
      end

      it "groups records by URN rather than date order" do
        puml = service.build

        # Each URN should appear exactly once as a swimlane header
        expect(puml.scan(/-- 100001 --/).count).to eq(1)
        expect(puml.scan(/-- 100002 --/).count).to eq(1)
      end
    end
  end
end
