module Migrators
  class School < Migrators::Base
    FIELDS_MAPPING = {
      administrative_district_name: :administrative_district_name,
      funding_eligibility: :funding_eligibility,
      induction_eligibility: :induction_eligibility,
      in_england: :in_england?,
      name: :name,
      phase_name: :school_phase_name,
      section_41_approved: :section_41_approved,
      status: :status,
      type_name: :school_type_name,
      ukprn: :ukprn_to_i
    }.freeze

    MISMATCH_FIELD_MESSAGE = ->(school, field, gias_value, ecf_value) { ":#{field} - School #{school.urn} (#{school.name}) mismatch value on field named '#{field}': '#{ecf_value}' on ECF whilst '#{gias_value}' expected on RECT!" }
    MISSING_SCHOOL_MESSAGE = ->(urn, name) { ":school_missing - School #{urn} (#{name}) missing on RECT!" }

    def self.dependencies = []

    def self.model = :school

    def self.record_count = schools.count

    def self.reset! = nil

    def self.schools
      ::Migration::School.with(eligible_or_cip_or_with_irs:
                                 [
                                   ::Migration::School.includes(:local_authority).eligible_or_cip_only_except_welsh.distinct,
                                   ::Migration::School.not_open.with_induction_records.distinct
                                 ])
                         .from("eligible_or_cip_or_with_irs AS schools")
    end

    def migrate!
      schools_with_associations = self.class.schools.preload(:partnerships, :induction_records)

      migrate(schools_with_associations) do |ecf_school|
        gias_school = find_gias_school_by_urn(ecf_school.urn.to_i) || migrate_school!(ecf_school)
        if check_gias_school(gias_school:, ecf_school:)
          [
            compare_fields(gias_school:, ecf_school:),
            update_school!(school: gias_school.school, ecf_school:),
          ].all?
        end
      end
    end

  private

    def check_gias_school(gias_school:, ecf_school:)
      return true if gias_school

      failure_manager.record_failure(ecf_school, MISSING_SCHOOL_MESSAGE.call(ecf_school.urn, ecf_school.name))

      false
    end

    def compare_fields(gias_school:, ecf_school:)
      FIELDS_MAPPING.map { |gias_field, ecf_field|
        gias_value = gias_school.send(gias_field)
        ecf_value = ecf_school.send(ecf_field)
        next true if gias_value.presence == ecf_value.presence

        field_mismatch(gias_school, gias_field, gias_value, ecf_value)
      }.all?
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
      Builders::GIAS::School.new(ecf_school).build if migratable_school?(ecf_school)
    end

    def migratable_school?(ecf_school)
      return ecf_school.partnerships.any? if ecf_school.open?

      ecf_school.induction_records.any?
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
