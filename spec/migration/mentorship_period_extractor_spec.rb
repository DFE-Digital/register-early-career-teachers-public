describe MentorshipPeriodExtractor do
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
                      :with_mentor,
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

  let(:ect_at_school_period_2) do
    FactoryBot.create(:ect_at_school_period,
                      start_date: induction_record_2.start_date)
  end

  let(:mentor_at_school_period_2) do
    FactoryBot.create(:mentor_at_school_period,
                      school: ect_at_school_period_2.school,
                      start_date: induction_record_2.start_date)
  end

  before do
    CacheManager.instance.clear_all_caches!

    ect_at_school_period_2.teacher.update!(api_ect_training_record_id: induction_record_2.participant_profile_id)
    mentor_at_school_period_2.teacher.update!(api_mentor_training_record_id: induction_record_2.mentor_profile_id)
  end

  describe "#mentorship_periods" do
    it "extracts mentorship periods from the induction_records" do
      periods = service.mentorship_periods

      expect(periods.count).to eq 1
    end

    it "sets the correct values in the periods" do
      period = service.mentorship_periods.first

      expect(period).to be_a Migration::MentorshipPeriodData
      expect(period.mentor_teacher).to eq mentor_at_school_period_2.teacher
      expect(period.start_date).to eq induction_record_2.start_date
      expect(period.end_date).to eq induction_record_2.end_date
      expect(period.start_source_id).to eq induction_record_2.id
      expect(period.end_source_id).to eq induction_record_2.id
    end

    context "when the last created induction record is 'leaving' and with flipped dates" do
      before do
        induction_record_2.update!(induction_status: :leaving,
                                   end_date: induction_record_2.start_date - 1.month)
      end

      it "adjusts the last mentorship period end date to be the updated_at" do
        period = service.mentorship_periods.last

        expect(period.end_date).to eq induction_record_2.updated_at
      end
    end

    context "when two induction records and last created induction record is 'completed'" do
      before do
        induction_record_2.update!(induction_status: :completed)
      end

      it "adjusts the last mentorship period end date to be the updated_at of the first IR" do
        period = service.mentorship_periods.last

        expect(period.end_date).to eq induction_record_1.updated_at
      end
    end
  end
end
