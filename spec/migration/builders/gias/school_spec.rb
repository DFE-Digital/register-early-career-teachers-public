describe Builders::GIAS::School do
  subject { described_class.new(ecf_school) }

  let(:ecf_school) do
    FactoryBot.create(:ecf_migration_school,
                      school_status_code: 2,
                      school_type_code: 10,
                      school_status_name: 'closed',
                      school_type_name: 'Community school')
  end

  describe '#build' do
    it "creates a new GIAS::School with an associated School record" do
      expect { subject.build }.to
      change(GIAS::School, :count).by(1).and
      change(School, :count).by(1)
    end

    it "returns the created GIAS::School record" do
      expect(subject.build).to be_a(GIAS::School)
    end

    it "migrate fields" do
      gias_school = subject.build

      expect(gias_school.school).to be_present
      expect(gias_school.api_id).to eq(ecf_school.id)
      expect(gias_school.address_line1).to eq(ecf_school.address_line1)
      expect(gias_school.address_line2).to eq(ecf_school.address_line2)
      expect(gias_school.address_line3).to eq(ecf_school.address_line3)
      expect(gias_school.administrative_district_name).to eq(ecf_school.administrative_district_name)
      expect(gias_school.establishment_number.to_s).to eq(ecf_school.urn)
      expect(gias_school.funding_eligibility).to eq(ecf_school.funding_eligibility)
      expect(gias_school.induction_eligibility).to eq(ecf_school.induction_eligibility)
      expect(gias_school.in_england).to eq(ecf_school.in_england?)
      expect(gias_school.local_authority_code).to eq(ecf_school.local_authority_code)
      expect(gias_school.name).to eq(ecf_school.name)
      expect(gias_school.phase_name).to eq(ecf_school.school_phase_name)
      expect(gias_school.postcode).to eq(ecf_school.postcode)
      expect(gias_school.primary_contact_email).to eq(ecf_school.primary_contact_email)
      expect(gias_school.secondary_contact_email).to eq(ecf_school.secondary_contact_email)
      expect(gias_school.section_41_approved).to eq(ecf_school.section_41_approved?)
      expect(gias_school.status).to eq(ecf_school.status)
      expect(gias_school.type_name).to eq(ecf_school.school_type_name)
      expect(gias_school.ukprn.to_s).to eq(ecf_school.ukprn)
      expect(gias_school.urn.to_s).to eq(ecf_school.urn)
      expect(gias_school.website).to eq(ecf_school.school_website)
    end
  end
end
