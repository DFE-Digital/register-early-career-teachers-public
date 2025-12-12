describe TeacherPeriodsExtractor do
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

  describe "#teacher_periods" do
    it "extracts teacher periods from the induction_records" do
      periods = service.teacher_periods

      expect(periods.count).to eq 2
    end

    it "sets the correct values in the periods" do
      periods = service.teacher_periods

      expect(periods[0]).to be_a Migration::SchoolPeriod
      expect(periods[0].urn).to eq school_1.urn
      expect(periods[0].start_date).to eq induction_record_1.start_date
      expect(periods[0].end_date).to eq induction_record_1.end_date
      expect(periods[0].start_source_id).to eq induction_record_1.id
      expect(periods[0].end_source_id).to eq induction_record_1.id

      training_period = periods[0].training_periods[0]
      expect(training_period).to be_a Migration::TrainingPeriodData
      expect(training_period.training_programme).to eq "provider_led"
      expect(training_period.school_urn).to eq school_1.urn
      expect(training_period.start_date).to eq induction_record_1.start_date
      expect(training_period.end_date).to eq induction_record_1.end_date
      expect(training_period.lead_provider).to eq lead_provider_1
      expect(training_period.delivery_partner).to eq delivery_partner_1
      expect(training_period.cohort_year).to eq induction_record_1.schedule.cohort.start_year
      expect(training_period.start_source_id).to eq induction_record_1.id
      expect(training_period.end_source_id).to eq induction_record_1.id

      expect(periods[1].urn).to eq school_2.urn
      expect(periods[1].start_date).to eq induction_record_2.start_date
      expect(periods[1].end_date).to eq induction_record_2.end_date
      expect(periods[1].start_source_id).to eq induction_record_2.id
      expect(periods[1].end_source_id).to eq induction_record_2.id

      training_period = periods[1].training_periods[0]
      expect(training_period).to be_a Migration::TrainingPeriodData
      expect(training_period.training_programme).to eq "provider_led"
      expect(training_period.school_urn).to eq school_2.urn
      expect(training_period.start_date).to eq induction_record_2.start_date
      expect(training_period.end_date).to eq induction_record_2.end_date
      expect(training_period.lead_provider).to eq lead_provider_2
      expect(training_period.delivery_partner).to eq delivery_partner_2
      expect(training_period.cohort_year).to eq induction_record_2.schedule.cohort.start_year
      expect(training_period.start_source_id).to eq induction_record_2.id
      expect(training_period.end_source_id).to eq induction_record_2.id
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
        periods = service.teacher_periods

        expect(periods[0].start_date).to eq induction_record_1.created_at
      end

      it "does not adjust subsequent periods" do
        periods = service.teacher_periods

        expect(periods[1].start_date).to eq induction_record_2.start_date
      end
    end

    context "when the last created induction record is 'leaving' and with flipped dates" do
      before do
        induction_record_2.update!(induction_status: :leaving,
                                   updated_at: 1.month.ago,
                                   start_date: 1.month.ago,
                                   end_date: 2.months.ago)
      end

      it "adjusts the last school period end date to be the updated_at" do
        periods = service.teacher_periods

        expect(periods[1].end_date).to eq induction_record_2.updated_at
      end

      it "adjusts the last school period last training period end date to be the updated_at" do
        periods = service.teacher_periods
        training_period = periods[1].training_periods[0]

        expect(training_period.end_date).to eq induction_record_2.updated_at
      end
    end

    context "when the participant has two induction records and last created induction record is 'completed'" do
      before do
        induction_record_2.update!(induction_status: :completed)
      end

      it "adjusts the last school period end date to be the updated_at of the first induction record" do
        periods = service.teacher_periods

        expect(periods[1].end_date).to eq induction_record_1.updated_at
      end

      it "adjusts the last school period last training period end date to be the updated_at of the first IR" do
        periods = service.teacher_periods
        training_period = periods[1].training_periods[0]

        expect(training_period.end_date).to eq induction_record_1.updated_at
      end
    end

    context "when the participant has two induction records at the same school and LP and only last created induction record is 'deferred'" do
      let!(:participant_profile_state) { FactoryBot.create(:migration_participant_profile_state, :deferred, participant_profile:) }

      before do
        induction_record_1.update!(end_date: Time.current)
        induction_record_2.update!(training_status: :deferred, induction_programme: induction_programme_1)
      end

      it "adjusts the last training period end date to be the end date of the first induction record" do
        periods = service.teacher_periods
        training_period = periods[0].training_periods[0]

        expect(training_period.end_date).to eq induction_record_1.end_date
      end

      it "adjusts the last training period deferral data from the associated participant profile state" do
        periods = service.teacher_periods
        training_period = periods[0].training_periods[0]

        expect(training_period.deferred_at).to eq participant_profile_state.created_at
      end
    end

    context "when the participant is an ECT with more than two induction records and induction completion date" do
      let!(:induction_record_2) do
        FactoryBot.create(:migration_induction_record,
                          participant_profile:,
                          induction_programme: induction_programme_2,
                          start_date: induction_record_1.end_date,
                          end_date: Date.current)
      end

      let!(:induction_record_3) do
        FactoryBot.create(:migration_induction_record,
                          participant_profile:,
                          induction_programme: induction_programme_2,
                          start_date: induction_record_2.end_date,
                          end_date: induction_record_2.end_date + 1.week)
      end

      context "when the completion date is before the end_date of the last induction records" do
        let(:induction_completion_date) { induction_record_2.end_date - 1.day }

        before do
          induction_records << induction_record_3
          participant_profile.update!(induction_completion_date:)
        end

        it "adjusts the last training period end date to be the completion date" do
          periods = service.teacher_periods
          training_period = periods[1].training_periods[0]

          expect(training_period.end_date).to eq induction_completion_date
        end
      end

      context "when the completion date is before the end_date of the last induction record" do
        let(:induction_completion_date) { induction_record_3.end_date - 1.day }

        before do
          induction_records << induction_record_3
          participant_profile.update!(induction_completion_date:)
        end

        it "adjusts the last training period end date to be the completion date" do
          periods = service.teacher_periods
          training_period = periods[1].training_periods[0]

          expect(training_period.end_date).to eq induction_completion_date
        end
      end

      context "when the completion date is after the end_date of the last induction record" do
        let(:induction_completion_date) { induction_record_3.end_date + 1.day }

        before do
          induction_records << induction_record_3
          participant_profile.update!(induction_completion_date:)
        end

        it "adjusts the last training period end date to be the completion date" do
          periods = service.teacher_periods
          training_period = periods[1].training_periods[0]

          expect(training_period.end_date).to eq induction_completion_date
        end
      end
    end
  end
end
