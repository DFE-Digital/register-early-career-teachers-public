describe TrainingPeriodExtractor do
  subject(:service) { described_class.new(induction_records:) }

  let(:induction_programme_1) { FactoryBot.create(:migration_induction_programme, :provider_led) }
  let(:induction_programme_2) { FactoryBot.create(:migration_induction_programme, :provider_led) }

  let(:induction_record_1) do
    FactoryBot.create(:migration_induction_record,
                      induction_programme: induction_programme_1,
                      end_date: 1.week.ago)
  end
  let(:induction_record_2) do
    FactoryBot.create(:migration_induction_record,
                      participant_profile:,
                      induction_programme: induction_programme_2)
  end
  let(:participant_profile) { induction_record_1.participant_profile }
  let(:induction_records) { [induction_record_1, induction_record_2] }

  let(:school_1) { induction_programme_1.school_cohort.school }
  let(:school_2) { induction_programme_2.school_cohort.school }

  let(:lead_provider_1) { induction_programme_1.partnership.lead_provider.name }
  let(:delivery_partner_1) { induction_programme_1.partnership.delivery_partner.name }

  let(:lead_provider_2) { induction_programme_2.partnership.lead_provider.name }
  let(:delivery_partner_2) { induction_programme_2.partnership.delivery_partner.name }

  before do
    CacheManager.instance.clear_all_caches!
  end

  describe "#training_periods" do
    it "extracts training periods from the induction_records" do
      periods = service.training_periods

      expect(periods.count).to eq 2
    end

    it "sets the correct values in the periods" do
      periods = service.training_periods

      expect(periods[0].school_urn).to eq school_1.urn
      expect(periods[0].start_date).to eq induction_record_1.start_date
      expect(periods[0].end_date).to eq induction_record_1.end_date
      expect(periods[0].training_programme).to eq "provider_led"
      expect(periods[0].lead_provider).to eq lead_provider_1
      expect(periods[0].delivery_partner).to eq delivery_partner_1
      expect(periods[0].cohort_year).to eq induction_record_1.schedule.cohort.start_year
      expect(periods[0].start_source_id).to eq induction_record_1.id
      expect(periods[0].end_source_id).to eq induction_record_1.id

      expect(periods[1].school_urn).to eq school_2.urn
      expect(periods[1].start_date).to eq induction_record_2.start_date
      expect(periods[1].end_date).to eq induction_record_2.end_date
      expect(periods[1].training_programme).to eq "provider_led"
      expect(periods[1].lead_provider).to eq lead_provider_2
      expect(periods[1].delivery_partner).to eq delivery_partner_2
      expect(periods[1].cohort_year).to eq induction_record_2.schedule.cohort.start_year
      expect(periods[1].start_source_id).to eq induction_record_2.id
      expect(periods[1].end_source_id).to eq induction_record_2.id
    end

    context "when the first induction record created_at is earlier than the start_date" do
      let(:induction_record_1) do
        FactoryBot.create(:migration_induction_record,
                          induction_programme: induction_programme_1,
                          created_at: 6.months.ago,
                          start_date: 1.month.ago,
                          end_date: 1.week.ago)
      end

      it "adjusts the first period start to be the created_at" do
        periods = service.training_periods

        expect(periods[0].start_date).to eq induction_record_1.created_at
      end

      it "does not adjust subsequent periods" do
        periods = service.training_periods

        expect(periods[1].start_date).to eq induction_record_2.start_date
      end
    end
  end
end
