# frozen_string_literal: true

module API::SchoolPartnerships
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :registration_year
    attribute :school_ecf_id
    attribute :lead_provider_ecf_id
    attribute :delivery_partner_ecf_id

    validates :registration_year, :school_ecf_id, :lead_provider_ecf_id, :delivery_partner_ecf_id, presence: true
    validate :registration_period_exists
    validate :lead_provider_exists
    validate :school_exists
    validate :school_is_not_cip_only
    validate :school_is_eligible
    validate :delivery_partner_exists
    validate :lead_provider_delivery_partnership_exists
    validate :school_partnership_does_not_already_exists
    validate :school_training_period_exists # NOTE: disable before running partnership migration script

    def create
      return false unless valid?

      SchoolPartnership.create!(
        school:,
        lead_provider_delivery_partnership:
      ).tap { |school_partnership| accept_expressions_of_interest(school_partnership) }
    end

  private

    def accept_expressions_of_interest(school_partnership)
      expressions_of_interest = school_partnership.lead_provider_active_period.expressions_of_interest.pending
      expressions_of_interest.for_school(school).each do |expression_of_interest|
        expression_of_interest.update!(school_partnership:)
      end
    end

    def registration_period
      @registration_period ||= RegistrationPeriod.find_by(year: registration_year) if registration_year
    end

    def lead_provider
      @lead_provider ||= LeadProvider.find_by(ecf_id: lead_provider_ecf_id) if lead_provider_ecf_id
    end

    def school
      @school ||= School.find_by(ecf_id: school_ecf_id) if school_ecf_id
    end

    def delivery_partner
      @delivery_partner ||= DeliveryPartner.find_by(ecf_id: delivery_partner_ecf_id) if delivery_partner_ecf_id
    end

    def registration_period_exists
      errors.add(:registration_year, "Registration year does not exist") unless registration_period
    end

    def lead_provider_exists
      errors.add(:lead_provider_ecf_id, "Lead provider does not exist") unless lead_provider
    end

    def school_exists
      errors.add(:school_ecf_id, "School does not exist") unless school
    end

    def school_is_not_cip_only
      errors.add(:school_ecf_id, "School is CIP only") if school&.cip_only?
    end

    def school_is_eligible
      return unless school

      errors.add(:school_ecf_id, "School is not eligible") unless school&.eligible?
    end

    def school_partnership_does_not_already_exists
      return unless school && lead_provider_delivery_partnership

      existing_school_partnership = school.school_partnerships.exists?(lead_provider_delivery_partnership:)

      errors.add(:school_ecf_id, "School partnership already exists for the lead provider, delivery partner and registration year") if existing_school_partnership
    end

    def school_training_period_exists
      return unless school

      training_periods = TrainingPeriod.for_school(school)

      errors.add(:school_ecf_id, "School does not have any FIP participants") unless training_periods.exists?
    end

    def delivery_partner_exists
      errors.add(:delivery_partner_ecf_id, "Delivery partner does not exist") unless delivery_partner
    end

    def lead_provider_active_period
      return unless lead_provider && registration_period

      @lead_provider_active_period ||= lead_provider.active_periods.find_by(registration_period:)
    end

    def lead_provider_delivery_partnership
      return unless lead_provider_active_period && delivery_partner

      @lead_provider_delivery_partnership ||= delivery_partner.lead_provider_delivery_partnerships.find_by(lead_provider_active_period:, delivery_partner:)
    end

    def lead_provider_delivery_partnership_exists
      return unless lead_provider && delivery_partner

      errors.add(:delivery_partner_ecf_id, "Lead provider and delivery partner do not have a partnership") unless lead_provider_delivery_partnership
    end
  end
end
