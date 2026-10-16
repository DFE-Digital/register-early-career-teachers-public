module Sessions
  module Users
    class DfESignInAuthenticationRecorder
      attr_reader :organisation, :authenticated_at

      # @param organisation [OmniAuth::AuthHash]
      def initialize(organisation)
        @organisation = organisation
        @authenticated_at = Time.zone.now
      end

      def call
        ActiveRecord::Base.transaction do
          DfESignInOrganisation.create_with(dfe_sign_in_data)
                               .find_or_create_by!(uuid: organisation.id)
                               .update!(last_authenticated_at: authenticated_at)
        end
      end

    private

      # @return [Hash<Symbol => String, nil>]
      def dfe_sign_in_data
        {
          name: organisation.name,
          uuid: organisation.id,
          urn: organisation.urn,
          address: organisation.address,
          company_registration_number: organisation.companyRegistrationNumber,
          category: organisation&.category&.name,
          organisation_type: organisation&.type&.name,
          status: organisation&.status&.name,
          first_authenticated_at: authenticated_at
        }
      end
    end
  end
end
