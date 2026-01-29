RSpec.describe Sessions::Users::Builder do
  describe "#session_user" do
    subject(:session_user) { described_class.new(omniauth_payload:).session_user }

    let(:email) { Faker::Internet.email }
    let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
    let(:school) { FactoryBot.create(:school) }

    let(:omniauth_payload) do
      OmniAuth::AuthHash.new(
        provider:,
        uid:,
        info: {
          email:,
          first_name: Faker::Name.first_name,
          last_name: Faker::Name.last_name,
          name: Faker::Name.name,
          appropriate_body_id:,
          school_urn:,
          dfe_staff:
        },
        extra: {
          raw_info: {
            organisation: {
              id: organisation_id,
              urn: organisation_urn
            }
          }
        }
      )
    end

    context "when the provider is DfE Sign In" do
      let(:provider) { "dfe_sign_in" }
      let(:uid) { Faker::Internet.uuid }
      let(:appropriate_body_id) { nil }
      let(:school_urn) { nil }
      let(:dfe_staff) { nil }
      let(:dfe_sign_in_roles) { [] }

      before do
        allow_any_instance_of(Organisation::Access).to receive(:roles).and_return(dfe_sign_in_roles)
      end

      context "when the AppropriateBody exists and the user has the AppropriateBodyUser role" do
        let(:organisation_id) { appropriate_body.dfe_sign_in_organisation_id }
        let(:organisation_urn) { nil }
        let(:dfe_sign_in_roles) { %w[AppropriateBodyUser] }

        it "returns an appropriate body user session" do
          expect(session_user).to be_a(Sessions::Users::AppropriateBodyUser)
        end
      end

      context "when the School exists and the user has the SchoolUser role" do
        let(:organisation_id) { Faker::Internet.uuid }
        let(:organisation_urn) { school.urn }
        let(:dfe_sign_in_roles) { %w[SchoolUser] }

        it "returns a school user session" do
          expect(session_user).to be_a(Sessions::Users::SchoolUser)
        end
      end

      context "when the school has not been linked but the gias school exists and the user has the SchoolUser role" do
        let(:organisation_id) { Faker::Internet.uuid }
        let(:gias_school) { FactoryBot.create(:gias_school, :open) }
        let(:organisation_urn) { gias_school.urn }
        let(:dfe_sign_in_roles) { %w[SchoolUser] }

        it "returns a school user session" do
          expect(session_user).to be_a(Sessions::Users::SchoolUser)
          expect(session_user.school).to be_nil
          expect(session_user.gias_school).to eq(gias_school)
        end
      end

      context "when both the AppropriateBody and School exist and the user has both roles" do
        let(:organisation_id) { appropriate_body.dfe_sign_in_organisation_id }
        let(:organisation_urn) { school.urn }
        let(:dfe_sign_in_roles) { %w[SchoolUser AppropriateBodyUser] }

        it "defaults to a school user session" do
          expect(session_user).to be_a(Sessions::Users::SchoolUser)
        end
      end

      context "when neither the AppropriateBody or School exist" do
        let(:organisation_id) { "c399f5a7-44e4-4c86-bb4a-e3e2dbe69421" }
        let(:organisation_urn) { nil }

        it do
          expect { session_user }.to raise_error(described_class::UnknownOrganisation,
                                                 '#<OmniAuth::AuthHash id="c399f5a7-44e4-4c86-bb4a-e3e2dbe69421" urn=nil>')
        end
      end
    end

    context "when the provider is a persona" do
      let(:provider) { "persona" }

      context "and personas are not enabled" do
        let(:uid) { email }
        let(:appropriate_body_id) { nil }
        let(:school_urn) { nil }
        let(:dfe_staff) { "true" }
        let(:organisation_id) { nil }
        let(:organisation_urn) { nil }
        let!(:user) { FactoryBot.create(:user, email:) }

        before do
          allow(Rails.application.config).to receive(:enable_personas).and_return(false)
        end

        it do
          expect { session_user }.to raise_error(described_class::UnknownProvider, provider)
        end
      end

      context "and personas are enabled" do
        before do
          allow(Rails.application.config).to receive(:enable_personas).and_return(true)
        end

        context "when dfe_staff is truthy" do
          let(:uid) { email }
          let(:appropriate_body_id) { nil }
          let(:school_urn) { nil }
          let(:dfe_staff) { "true" }
          let(:organisation_id) { nil }
          let(:organisation_urn) { nil }
          let!(:user) { FactoryBot.create(:user, email:) }

          it "returns a dfe persona" do
            expect(session_user).to be_a(Sessions::Users::DfEPersona)
          end
        end

        context "when the school_urn is present" do
          let(:uid) { email }
          let(:appropriate_body_id) { nil }
          let(:school_urn) { school.urn }
          let(:dfe_staff) { "false" }
          let(:organisation_id) { nil }
          let(:organisation_urn) { nil }

          it "returns a school persona" do
            expect(session_user).to be_a(Sessions::Users::SchoolPersona)
          end
        end

        context "when the appropriate_body_id is present" do
          let(:uid) { email }
          let(:appropriate_body_id) { appropriate_body.id }
          let(:school_urn) { nil }
          let(:dfe_staff) { "false" }
          let(:organisation_id) { nil }
          let(:organisation_urn) { nil }

          it "returns an appropriate body persona" do
            expect(session_user).to be_a(Sessions::Users::AppropriateBodyPersona)
          end
        end

        context "when no dfe_staff or school_urn or appropriate_body_id present" do
          let(:uid) { email }
          let(:appropriate_body_id) { nil }
          let(:school_urn) { nil }
          let(:dfe_staff) { "false" }
          let(:organisation_id) { nil }
          let(:organisation_urn) { nil }

          it do
            expect { session_user }.to raise_error(described_class::UnknownPersonaType)
          end
        end
      end
    end

    context "with an unknown provider" do
      let(:provider) { "any_other_provider" }
      let(:uid) { email }
      let(:appropriate_body_id) { nil }
      let(:school_urn) { nil }
      let(:dfe_staff) { "true" }
      let(:organisation_id) { nil }
      let(:organisation_urn) { nil }
      let!(:user) { FactoryBot.create(:user, email:) }

      it do
        expect { session_user }.to raise_error(described_class::UnknownProvider, provider)
      end
    end
  end
end
