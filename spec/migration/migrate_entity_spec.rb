RSpec.describe MigrateEntity do
  subject(:service) { described_class.new }

  describe "#school_partnership" do
    let(:ecf_lead_provider) { FactoryBot.create(:migration_lead_provider, :active) }
    let(:ecf_cohort) { ecf_lead_provider.cohorts.first }
    let(:ecf_delivery_partner) { FactoryBot.create(:migration_delivery_partner) }
    let!(:ecf_provider_relationship) do
      FactoryBot.create(:migration_provider_relationship,
        lead_provider: ecf_lead_provider,
        delivery_partner: ecf_delivery_partner,
        cohort: ecf_cohort)
    end
    let!(:ecf_partnership) { FactoryBot.create(:migration_partnership, lead_provider: ecf_lead_provider, delivery_partner: ecf_delivery_partner, cohort: ecf_cohort) }
    let!(:school) { FactoryBot.create(:school, :eligible, urn: ecf_partnership.school.urn) }

    it "creates a school_partnership from the ECF partnership" do
      expect {
        service.school_partnership(ecf_partnership:)
      }.to change(SchoolPartnership, :count).by(1).and \
        change(LeadProviderDeliveryPartnership, :count).by(1).and \
          change(DeliveryPartner, :count).by(1).and \
            change(ActiveLeadProvider, :count).by(1).and \
              change(LeadProvider, :count).by(1)
    end

    it "migrates the correct school_partnership values" do
      school_partnership = service.school_partnership(ecf_partnership:)
      expect(school_partnership.lead_provider_delivery_partnership.lead_provider.name).to eq ecf_lead_provider.name
      expect(school_partnership.lead_provider_delivery_partnership.delivery_partner.name).to eq ecf_delivery_partner.name
      expect(school_partnership.lead_provider_delivery_partnership.contract_period.year).to eq ecf_cohort.start_year
      expect(school_partnership.school).to eq school
    end
  end

  describe "#active_lead_provider" do
    let(:ecf_lead_provider) { FactoryBot.create(:migration_lead_provider) }

    before do
      3.times { ecf_lead_provider.cohorts << FactoryBot.create(:migration_cohort, :with_sequential_start_year) }
    end

    it "creates active_lead_provider records from the ECF lead_provider and active cohorts" do
      expect {
        service.active_lead_provider(ecf_lead_provider:)
      }.to change(ActiveLeadProvider, :count).by(3).and \
        change(LeadProvider, :count).by(1).and \
          change(ContractPeriod, :count).by(3)
    end

    it "migrates the correct values" do
      service.active_lead_provider(ecf_lead_provider:)

      lead_provider = LeadProvider.find_by!(name: ecf_lead_provider.name)
      expect(lead_provider.name).to eq ecf_lead_provider.name

      ecf_lead_provider.cohorts.each do |cohort|
        expect(ActiveLeadProvider).to exist(lead_provider:, contract_period: ContractPeriod.find(cohort.start_year))
      end
    end
  end

  describe "#teacher" do
    let(:ect_profile) { FactoryBot.create(:migration_participant_profile, :ect) }
    let(:trn) { ect_profile.teacher_profile.trn }
    let(:school_cohort) { ect_profile.school_cohort }
    let(:cohort) { school_cohort.cohort }
    let(:ecf_school) { school_cohort.school }
    let(:mentor_profile) { FactoryBot.create(:migration_participant_profile, :mentor, school_cohort:) }
    let!(:ect_induction_record) { FactoryBot.create(:migration_induction_record, participant_profile: ect_profile, mentor_profile:) }
    let!(:mentor_induction_record) { FactoryBot.create(:migration_induction_record, participant_profile: mentor_profile) }
    let(:lead_provider) { FactoryBot.create(:migration_lead_provider) }
    let(:delivery_partner) { FactoryBot.create(:migration_delivery_partner) }
    let!(:provider_relationship) { FactoryBot.create(:migration_provider_relationship, lead_provider:, delivery_partner:, cohort:) }
    let!(:ecf_partnership) { FactoryBot.create(:migration_partnership, lead_provider:, delivery_partner:, cohort:, school: ecf_school) }
    let!(:school) { FactoryBot.create(:school, :eligible, urn: ecf_school.urn) }

    before do
      lead_provider.cohorts << cohort
      school_cohort.default_induction_programme.update!(partnership: ecf_partnership)
    end

    it "creates a teacher record and dependencies from the matching ECF TRN" do
      expect {
        service.teacher(trn:)
      }.to change(Teacher, :count).by(2).and \
        change(ECTAtSchoolPeriod, :count).by(1).and \
          change(MentorAtSchoolPeriod, :count).by(1).and \
            change(MentorshipPeriod, :count).by(1).and \
              change(TrainingPeriod, :count).by(2).and \
                change(SchoolPartnership, :count).by(1).and \
                  change(LeadProviderDeliveryPartnership, :count).by(1).and \
                    change(DeliveryPartner, :count).by(1).and \
                      change(ActiveLeadProvider, :count).by(1).and \
                        change(LeadProvider, :count).by(1).and \
                          change(ContractPeriod, :count).by(1)
    end

    it "migrates the correct values" do
      teacher = service.teacher(trn:)

      parser = Teachers::FullNameParser.new(full_name: ect_profile.teacher_profile.user.full_name)
      expect(Teachers::Name.new(teacher).full_name).to eq [parser.first_name, parser.last_name].join(" ")

      expect(teacher.ect_at_school_periods.first.mentors.first.teacher).to eq Teacher.find_by(trn: mentor_profile.teacher_profile.trn)
      expect(teacher.ect_at_school_periods.first.training_periods.first.lead_provider.name).to eq lead_provider.name
    end
  end
end
