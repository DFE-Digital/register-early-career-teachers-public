RSpec.describe AppropriateBodyMigrator do
  let(:dfe_sign_in_organisation) do
    DfESignInOrganisation.find_by(uuid: organisation.id)
  end

  let(:appropriate_body) do
    AppropriateBody.find_by(dfe_sign_in_organisation_id: dfe_sign_in_organisation.id)
  end

  let(:organisation) do
    OpenStruct.new(
      id: appropriate_body_period.dfe_sign_in_organisation_id,
      name:,
      urn:,
      address: "Some address"
    )
  end

  # AppropriateBodyMigrator is called after a successful AB login by Sessions::Users::Builder#appropriate_body_user?
  # and is used to populate DfESignInOrganisation and the NEW AB role records as needed.
  describe "#call" do
    # Auth hash for TSH ABs has URN and uses the name of the Lead School
    #
    context "with Appropriate Body (teaching school hub)" do
      let!(:lead_school) do
        FactoryBot.create(:gias_school, :with_school, :eligible_type, :in_england,
                          name:,
                          urn:).school
      end

      # TODO: AB is being converted to a period
      let!(:appropriate_body_period) { FactoryBot.create(:appropriate_body, :teaching_school_hub) }
      let(:urn) { "1234567" }
      let(:name)  { "Lead School for TSH" }

      it "creates a DfESignInOrganisation and TeachingSchoolHub linked to AB" do
        # First call creates the records
        expect {
          described_class.new(organisation).call
        }.to change(DfESignInOrganisation, :count).by(1)
        .and change(AppropriateBody, :count).by(1)

        # Ignores irrelevant National Body
        # expect(NationalBody.count).to eq(0)

        # creates DfE Sign-In Organisation using school name, URN and UUID
        expect(dfe_sign_in_organisation).to have_attributes(
          uuid: appropriate_body_period.dfe_sign_in_organisation_id,
          name: lead_school.name,
          urn:,
          address: "Some address"
        )

        # creates TSH using AB name
        expect(appropriate_body).to have_attributes(
          name: appropriate_body_period.name,
          dfe_sign_in_organisation_id: dfe_sign_in_organisation.id
        )

        # Captures first login time
        expect(dfe_sign_in_organisation.first_authenticated_at).to eq(dfe_sign_in_organisation.last_authenticated_at)

        # DSI links AB to School
        expect(dfe_sign_in_organisation.appropriate_body_period).to eq(appropriate_body_period)
        expect(dfe_sign_in_organisation.school).to eq(lead_school)

        # AB links to Lead School/TSH (not National Body)
        appropriate_body_period.reload
        expect(appropriate_body_period.appropriate_body).to eq(appropriate_body)
        # expect(appropriate_body_period.lead_school).to eq(lead_school)
        # expect(appropriate_body_period.national_body).to be_nil
        # expect(teaching_school_hub.lead_school).to eq(lead_school)

        # Further calls are no-ops
        expect { described_class.new(organisation).call }.not_to change(DfESignInOrganisation, :count)
        expect { described_class.new(organisation).call }.not_to change(AppropriateBody, :count)

        # Updates last login time
        travel_to(1.day.from_now) do
          described_class.new(organisation).call
          dfe_sign_in_organisation.reload
          expect(dfe_sign_in_organisation.first_authenticated_at).not_to eq(dfe_sign_in_organisation.last_authenticated_at)
        end
      end
    end

    # Auth hash for National ABs has no URN and uses the name of the AB
    #
    context "with Appropriate Body (national)" do
      # TODO: AB is being converted to a period
      let!(:appropriate_body_period) { FactoryBot.create(:appropriate_body, :national) }
      let(:name)  { appropriate_body_period.name }
      let(:urn) { nil }

      it "creates a DfESignInOrganisation and NationalBody linked to AB" do
        # First call creates the records
        expect {
          described_class.new(organisation).call
        }.to change(DfESignInOrganisation, :count).by(1)
        .and change(AppropriateBody, :count).by(1)

        # Ignores irrelevant TSH
        # expect(TeachingSchoolHub.count).to eq(0)

        # creates DfE Sign-In Organisation using AB name and UUID
        expect(dfe_sign_in_organisation).to have_attributes(
          uuid: appropriate_body_period.dfe_sign_in_organisation_id,
          name: appropriate_body_period.name,
          urn:,
          address: "Some address"
        )

        # creates NB using AB name
        expect(appropriate_body).to have_attributes(
          name: appropriate_body_period.name,
          dfe_sign_in_organisation_id: dfe_sign_in_organisation.id
        )

        # Captures first login time
        expect(dfe_sign_in_organisation.first_authenticated_at).to eq(dfe_sign_in_organisation.last_authenticated_at)

        # DSI only links to AB
        expect(dfe_sign_in_organisation.appropriate_body_period).to eq(appropriate_body_period)
        expect(dfe_sign_in_organisation.school).to be_nil

        # AB links to National Body (not Lead School)
        appropriate_body_period.reload
        expect(appropriate_body_period.appropriate_body).to eq(appropriate_body)
        # expect(appropriate_body_period.teaching_school_hub).to be_nil
        # expect(appropriate_body_period.lead_school).to be_nil

        # Further calls are no-ops
        expect { described_class.new(organisation).call }.not_to change(DfESignInOrganisation, :count)
        expect { described_class.new(organisation).call }.not_to change(AppropriateBody, :count)

        # Updates last login time
        travel_to(1.day.from_now) do
          described_class.new(organisation).call
          dfe_sign_in_organisation.reload
          expect(dfe_sign_in_organisation.first_authenticated_at).not_to eq(dfe_sign_in_organisation.last_authenticated_at)
        end
      end
    end
  end
end
