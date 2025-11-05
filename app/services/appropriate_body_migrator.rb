class AppropriateBodyMigrator
  attr_reader :organisation, :authenticated_at

  # @param organisation [OmniAuth::AuthHash]
  def initialize(organisation)
    @organisation = organisation
    @authenticated_at = Time.zone.now
  end

  delegate :name, :dqt_id, to: :appropriate_body_period
  delegate :school, to: :dfe_sign_in_organisation, prefix: :lead

  def call
    ActiveRecord::Base.transaction do
      dfe_sign_in_organisation
      legacy_appropriate_body

      if appropriate_body_period.teaching_school_hub?
        appropriate_body_period.update!(teaching_school_hub:) if appropriate_body_period.teaching_school_hub.blank?
        appropriate_body_period.update!(lead_school:) if appropriate_body_period.lead_school.blank?
      elsif appropriate_body_period.national?
        appropriate_body_period.update!(national_body:) if appropriate_body_period.national_body.blank?
      end

      dfe_sign_in_organisation.update!(last_authenticated_at: authenticated_at)
    end
  end

private

  # @return [AppropriateBodyPeriod]
  def appropriate_body_period
    @appropriate_body_period ||=
      AppropriateBodyPeriod.find_by(dfe_sign_in_organisation_id: organisation.id)
  end

  # @return [LegacyAppropriateBody]
  def legacy_appropriate_body
    @legacy_appropriate_body ||=
      LegacyAppropriateBody.create_with(dqt_id:, appropriate_body_period:)
        .find_or_create_by(name:)
  end

  # @return [DfESignInOrganisation]
  def dfe_sign_in_organisation
    @dfe_sign_in_organisation ||=
      DfESignInOrganisation.create_with(dfe_sign_in_data)
        .find_or_create_by!(uuid: organisation.id)
  end

  # @return [TeachingSchoolHub]
  def teaching_school_hub
    @teaching_school_hub ||=
      TeachingSchoolHub.create_with(dfe_sign_in_organisation:, lead_school:)
        .find_or_create_by(name:)
  end

  # @return [NationalBody]
  def national_body
    @national_body ||=
      NationalBody.create_with(dfe_sign_in_organisation:)
        .find_or_create_by(name:)
  end

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
