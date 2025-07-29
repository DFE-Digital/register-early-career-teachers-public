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
      migrate(self.class.schools) do |ecf_school|
        gias_school = find_gias_school(urn: ecf_school.urn.to_i) || migrate_school!(ecf_school)
        if check_gias_school(gias_school:, ecf_school:)
          [compare_fields(gias_school:, ecf_school:),
           update_gias_school!(gias_school:, api_id: ecf_school.id)].all?
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

    def find_gias_school(urn:) = gias_schools.find { |school| school.urn == urn }

    def gias_schools = @gias_schools ||= ::GIAS::School.where(urn: self.class.schools.pluck(:urn).sort)

    def migrate_school!(ecf_school)
      Builders::GIAS::School.new(ecf_school).build if migrateable_school?(ecf_school)
    end

    def migrateable_school?(ecf_school) = open_school_with_partnerships?(ecf_school) || not_open_school_with_induction_records?(ecf_school)

    def not_open_school_with_induction_records?(ecf_school) = !ecf_school.open? && ecf_school.induction_records.exists?

    def open_school_with_partnerships?(ecf_school) = ecf_school.open? && ecf_school.partnerships.exists?

    def update_gias_school!(gias_school:, api_id:) = gias_school.update!(api_id:)
  end
end
