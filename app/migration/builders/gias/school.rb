module Builders
  module GIAS
    class School
      attr_reader :ecf_school, :error

      def initialize(ecf_school)
        @ecf_school = ecf_school
      end

      def build
        ActiveRecord::Base.transaction do
          ::GIAS::School.create!(
            address_line1: ecf_school.address_line1,
            address_line2: ecf_school.address_line2,
            address_line3: ecf_school.address_line3,
            administrative_district_name: ecf_school.administrative_district_name,
            api_id: ecf_school.id,
            establishment_number: ecf_school.urn,
            funding_eligibility: ecf_school.funding_eligibility,
            induction_eligibility: ecf_school.induction_eligibility,
            in_england: ecf_school.in_england?,
            local_authority_code: ecf_school.local_authority_code,
            name: ecf_school.name,
            phase_name: ecf_school.school_phase_name,
            postcode: ecf_school.postcode,
            primary_contact_email: ecf_school.primary_contact_email,
            secondary_contact_email: ecf_school.secondary_contact_email,
            section_41_approved: ecf_school.section_41_approved?,
            status: ecf_school.status,
            type_name: ecf_school.school_type_name,
            ukprn: ecf_school.ukprn,
            urn: ecf_school.urn,
            website: ecf_school.school_website
          ).tap(&:create_school!)
        end
      rescue ActiveRecord::ActiveRecordError => e
        @error = e.message
        nil
      end
    end
  end
end
