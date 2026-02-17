RSpec.describe SchoolMentorsForECT do
  subject(:service) { described_class.new(induction_records:) }

  let(:ect_profile) { FactoryBot.create(:migration_participant_profile, :ect) }
  let(:school_cohort) { ect_profile.school_cohort }
  let(:induction_programme) { FactoryBot.create(:migration_induction_programme, :provider_led, school_cohort:) }

  let!(:induction_records) do
    FactoryBot.create_list(:migration_induction_record, 2, :with_mentor, participant_profile: ect_profile)
  end

  let!(:mentor_at_school_periods) do
    school = FactoryBot.create(:school, urn: school_cohort.school.urn.to_i)
    period_1 = FactoryBot.create(:mentor_at_school_period,
                                 api_mentor_training_record_id: induction_records.first.mentor_profile_id,
                                 school:)
    period_2 = FactoryBot.create(:mentor_at_school_period,
                                 api_mentor_training_record_id: induction_records.last.mentor_profile_id,
                                 school:)
    [period_1, period_2]
  end

  describe "#mentor_at_school_periods" do
    it "builds the right number" do
      expect(service.mentor_at_school_periods.count).to eq mentor_at_school_periods.count
    end

    it "populates the right attributes" do
      aggregate_failures "ECT mentor at school periods results" do
        mentor_at_school_periods.each do |mentor_at_school_period|
          historic_period = service.mentor_at_school_periods.find { |hp| hp.mentor_at_school_period_id == mentor_at_school_period.id }
          expect(historic_period.started_on).to eq(mentor_at_school_period.started_on)
          expect(historic_period.finished_on).to eq(mentor_at_school_period&.finished_on)
          expect(historic_period.created_at).to be_within(1.second).of(mentor_at_school_period.created_at)
          expect(historic_period.updated_at).to be_within(1.second).of(mentor_at_school_period.updated_at)
          expect(historic_period.school.urn).to eq(mentor_at_school_period.school.urn.to_s)
          expect(historic_period.teacher.trn).to eq(mentor_at_school_period.teacher.trn)
          expect(historic_period.teacher.api_mentor_training_record_id).to eq(mentor_at_school_period.teacher.api_mentor_training_record_id)
        end
      end
    end
  end
end
