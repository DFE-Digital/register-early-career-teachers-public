module AppropriateBodySeeds
  module DateRange
    OPEN = /\A\s*\z/

    # @param text [String] "2021-09-01 -> 2024-08-31" or "2021-09-01 ->"
    # @return [Array<Date, nil>]
    def self.parse(text)
      from, to = text.split("->", 2).map(&:strip)
      raise ArgumentError, "a period needs a start date: #{text.inspect}" if from.blank?

      [Date.parse(from), (Date.parse(to) unless to.blank? || to.match?(OPEN))]
    end
  end

  class Builder
    def self.national_body(name, **) = new(:national, name, **)
    def self.teaching_school_hub(name, **) = new(:teaching_school_hub, name, **)
    def self.local_authority(name, **) = new(:local_authority, name, **)
    def self.teaching_school(name, **) = new(:teaching_school, name, **)

    # @return [NationalBody, LocalAuthority, TeachingSchoolHub, School]
    attr_reader :parent

    def initialize(body_type, name, **attributes)
      @body_type = body_type
      @parent = find_or_create_parent_by_name(name, **attributes)
    end

    # @param dates [String]
    # @param name_override [nil, String]
    # @return [AppropriateBodyPeriod]
    def period(dates = nil, name_override: nil, provisioning_school: nil, dfe_sign_in: nil, &block)
      raise ArgumentError, "#{parent.name} needs the dates it ran between" if dates.blank?

      started_on, finished_on = DateRange.parse(dates)

      period = AppropriateBodyPeriod.find_or_initialize_by(
        started_on:,
        body_type:,
        name: name_override,
        **period_attributes
      )

      period.assign_attributes(finished_on:, **period_attributes(provisioning_school))
      period.save!

      # Some seeded appropriate body periods populate usable DfE Sign-In credentials.
      # Request access to test authentication on deployments.
      if dfe_sign_in.present?
        dfe_sign_in_organisation = sign_in_organisation(period, dfe_sign_in)
        period.update!(dfe_sign_in_organisation:)
      end

      @period = period
      instance_eval(&block) if block

      period
    end

  private

    attr_reader :body_type

    # @param provisioning_school [School, Integer, nil]
    # @return [Hash] the attributes this body type puts on its period
    def period_attributes(provisioning_school = nil)
      {
        national: { national_body: parent },
        local_authority: { local_authority: parent },
        teaching_school_hub: { teaching_school_hub: parent, provisioning_school: lookup_school(provisioning_school) },
        teaching_school: { provisioning_school: parent }
      }.fetch(body_type).compact
    end

    def find_or_create_parent_by_name(name)
      case body_type
      when :national            then NationalBody.find_or_create_by!(name:)
      when :local_authority     then LocalAuthority.find_or_create_by!(name:)
      when :teaching_school_hub then TeachingSchoolHub.find_or_create_by!(name:)
      when :teaching_school     then School.joins(:gias_school).find_by!(gias_school: { name: })
      end
    end

    def lookup_school(value)
      return if value.blank?
      return value if value.is_a?(School)

      School.find_by!(urn: value)
    end

    # UUIDs are unique per environment, the same organisation will have different UUIDs in test and pre-production
    def dfe_sign_in_env
      Rails.application.config.dfe_sign_in_issuer.include?("test") ? :test : :pp
    end

    # The organisation name of a RIAB teaching school hub period is the name of its provisioning school
    # The organisation name of a RIAB national body period is the name of the national body
    #
    # @param period [AppropriateBodyPeriod]
    # @param credentials [Hash] { test: "uuid", pp: "uuid" }
    # @return [DfESignInOrganisation]
    def sign_in_organisation(period, credentials)
      organisation = DfESignInOrganisation.find_or_initialize_by(uuid: credentials.fetch(dfe_sign_in_env))
      name = period.provisioning_school&.name || parent.name
      urn = period.provisioning_school&.urn
      organisation.update!(name:, urn:)
      organisation
    end

    # @param code [String]
    # @param districts [Array<String>]
    # @param lead_school [School, String]
    # @param deactivated_on [String, nil] "2024-08-31"
    # @param reason [String, nil]
    def region(code, districts:, lead_school:, deactivated_on: nil, reason: nil)
      raise ArgumentError, "a closed award needs a reason" if deactivated_on.present? && reason.blank?

      region = Region.create_with(districts:).find_or_create_by!(code:)
      award = Region::Award.find_or_initialize_by(appropriate_body_period: @period, region:)
      award.assign_attributes(
        school: lookup_school(lead_school),
        deactivated_at: deactivated_on && Date.parse(deactivated_on).end_of_day,
        deactivation_reason: reason || award.deactivation_reason
      )

      award.save!
    end
  end
end
