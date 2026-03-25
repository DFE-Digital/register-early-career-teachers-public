module Migrators
  class School < Migrators::Base
    FIELDS_MAPPING = {
      administrative_district_name: :administrative_district_name,
      eligible: :eligible_for_fip?,
      in_england: :in_england?,
      phase_name: :school_phase_name,
      section_41_approved: :section_41_approved,
      status: :status,
      type_name: :school_type_name,
      ukprn: :ukprn_to_i
    }.freeze

    MISMATCH_FIELD_MESSAGE = ->(school, field, gias_value, ecf_value) { ":#{field} - School #{school.urn} (#{school.name}) mismatch value on field named '#{field}': '#{ecf_value}' on ECF whilst '#{gias_value}' expected on RECT!" }

    def self.dependencies = %i[gias_import gias_childrens_centres]

    def self.model = :school

    def self.record_count = schools.count

    def self.reset!
      if Rails.application.config.enable_migration_testing
        ::School.connection.execute("TRUNCATE #{::School.table_name} RESTART IDENTITY CASCADE")
      end
    end

    def self.schools
      # All RECT schools
      rect_school_urns = ::School.pluck(:urn)

      # All ECF schools that are returned by the API
      ecf_schools_with_partnerships = ::Migration::School
          .where.not(partnerships: { id: nil })
          .where(partnerships: {
            challenged_at: nil,
            challenge_reason: nil,
            relationship: false,
          })
      ecf_api_school_urns = ::Migration::School
        .eligible
        .not_cip_only
        .or(ecf_schools_with_partnerships)
        .includes(:partnerships)
        .pluck(:urn)

      # All ECF schools that have induction records
      ecf_induction_record_school_urns = ::Migration::School
          .with_induction_records
          .pluck(:urn)

      urns = (rect_school_urns + ecf_api_school_urns + ecf_induction_record_school_urns).uniq

      ::Migration::School.where(urn: urns)
    end

    def migrate!
      schools_with_associations = self.class.schools.preload(:partnerships, :induction_records)

      migrate(schools_with_associations) do |ecf_school|
        gias_school = find_gias_school_by_urn(ecf_school.urn.to_i) || migrate_school!(ecf_school)
        next unless gias_school

        [
          compare_fields(gias_school:, ecf_school:),
          update_school!(school: gias_school.school, ecf_school:),
        ].all?
      end
    end

  private

    def compare_fields(gias_school:, ecf_school:)
      FIELDS_MAPPING.map { |gias_field, ecf_field|
        gias_value = gias_school.send(gias_field)
        ecf_value = ecf_school.send(ecf_field)
        next true if gias_value.presence == ecf_value.presence
        next true if skip_missing_field?(gias_school:, field_name: gias_field, gias_value:, ecf_value:)

        field_mismatch(ecf_school, gias_field, gias_value, ecf_value)
      }.all?
    end

    # administrative_district_name is not in the split out GIAS export for Children's Centres
    # statuses open and proposed_to_close are considered the same status
    # statuses closed and proposed_to_open are considered the same status
    def skip_missing_field?(gias_school:, field_name:, gias_value:, ecf_value:)
      return true if field_name.to_s == "administrative_district_name" && gias_school.type_name.in?(GIAS::Types::CHILDRENS_CENTRE_TYPES)
      return true if field_name.to_s == "status" && ([gias_value, ecf_value] - %w[open proposed_to_close]).empty?

      field_name.to_s == "status" && ([gias_value, ecf_value] - %w[closed proposed_to_open]).empty?
    end

    def failed_to_build_school(ecf_school, error_message)
      failure_manager.record_failure(ecf_school, "Failed to find or build a GIAS school for school with urn #{ecf_school.urn} (#{ecf_school.name}): #{error_message}")
    end

    def field_mismatch(school, field, gias_value, ecf_value)
      failure_manager.record_failure(school, MISMATCH_FIELD_MESSAGE.call(school, field, gias_value, ecf_value))

      false
    end

    def find_gias_school_by_urn(urn) = gias_schools_by_urn[urn.to_i]

    def gias_schools_by_urn
      @gias_schools_by_urn ||= ::GIAS::School.where(urn: self.class.schools.pluck(:urn)).index_by(&:urn)
    end

    def migrate_school!(ecf_school)
      builder = Builders::GIAS::School.new(ecf_school)
      builder.build.tap do |gias_school|
        failed_to_build_school(ecf_school, builder.error) unless gias_school
      end
    end

    def update_school!(school:, ecf_school:)
      induction_coordinator = ecf_school.induction_coordinators.first

      attrs = {
        api_id: ecf_school.id,
        induction_tutor_name: induction_coordinator&.full_name,
        induction_tutor_email: induction_coordinator&.email,
        created_at: ecf_school.created_at,
        api_updated_at: ecf_school.updated_at
      }
      school.update_columns(attrs)
    end
  end
end
