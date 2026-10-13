RSpec.describe Sessions::Users::DfESignInAuthenticationRecorder do
  let(:dfe_sign_in_organisation) do
    DfESignInOrganisation.find_by(uuid: organisation.id)
  end

  let(:organisation) do
    OpenStruct.new(
      id: appropriate_body_period.dfe_sign_in_organisation_id,
      name:,
      urn:,
      address: "Some address"
    )
  end

  # Sessions::Users::DfESignInAuthenticationRecorder is called after a successful AB login by Sessions::Users::Builder
  # and records the organisation and its most recent sign in.
  describe "#call" do
    # Auth hash for TSH ABs has URN and uses the name of the Lead School
    #
    context "with DfE Sign In organisation for an Appropriate Body (teaching school hub)" do
      let!(:lead_school) do
        FactoryBot.create(:gias_school, :with_school, :eligible_type, :in_england,
                          name:,
                          urn:).school
      end

      let!(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }
      let(:urn) { "1234567" }
      let(:name)  { "Lead School for TSH" }

      it "creates a DfESignInOrganisation and records the first sign in" do
        # First call creates the record
        expect {
          described_class.new(organisation).call
        }.to change(DfESignInOrganisation, :count).by(1)

        # creates DfE Sign-In Organisation using school name, URN and UUID
        expect(dfe_sign_in_organisation).to have_attributes(
          uuid: appropriate_body_period.dfe_sign_in_organisation_id,
          name: lead_school.name,
          urn:,
          address: "Some address"
        )

        # Captures first login time
        expect(dfe_sign_in_organisation.first_authenticated_at).to eq(dfe_sign_in_organisation.last_authenticated_at)

        # DSI links AB to School
        expect(dfe_sign_in_organisation.appropriate_body_period).to eq(appropriate_body_period)
        expect(dfe_sign_in_organisation.school).to eq(lead_school)

        # Further calls do not create more records
        expect { described_class.new(organisation).call }.not_to change(DfESignInOrganisation, :count)

        # Updates last login time
        travel_to(1.day.from_now) do
          described_class.new(organisation).call
          dfe_sign_in_organisation.reload
          expect(dfe_sign_in_organisation.last_authenticated_at).to be > dfe_sign_in_organisation.first_authenticated_at
        end
      end
    end

    # Auth hash for National ABs has no URN and uses the name of the AB
    #
    context "with DfE Sign In organisation for an Appropriate Body (national)" do
      let!(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :national) }
      let(:name)  { appropriate_body_period.name }
      let(:urn) { nil }

      it "creates a DfESignInOrganisation and records the first sign in" do
        # First call creates the record
        expect {
          described_class.new(organisation).call
        }.to change(DfESignInOrganisation, :count).by(1)

        # creates DfE Sign-In Organisation using AB name and UUID
        expect(dfe_sign_in_organisation).to have_attributes(
          uuid: appropriate_body_period.dfe_sign_in_organisation_id,
          name: appropriate_body_period.name,
          urn:,
          address: "Some address"
        )

        # Captures first login time
        expect(dfe_sign_in_organisation.first_authenticated_at).to eq(dfe_sign_in_organisation.last_authenticated_at)

        # DSI only links to AB
        expect(dfe_sign_in_organisation.appropriate_body_period).to eq(appropriate_body_period)
        expect(dfe_sign_in_organisation.school).to be_nil

        # Further calls do not create more records
        expect { described_class.new(organisation).call }.not_to change(DfESignInOrganisation, :count)

        # Updates last login time
        travel_to(1.day.from_now) do
          described_class.new(organisation).call
          dfe_sign_in_organisation.reload
          expect(dfe_sign_in_organisation.last_authenticated_at).to be > dfe_sign_in_organisation.first_authenticated_at
        end
      end
    end
  end
end
