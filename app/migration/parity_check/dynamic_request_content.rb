module ParityCheck
  class DynamicRequestContent
    include ActiveModel::Model
    include ActiveModel::Attributes

    class Error < RuntimeError; end
    class UnrecognizedIdentifierError < Error; end

    attribute :lead_provider

    def fetch(identifier)
      raise UnrecognizedIdentifierError, "Identifier not recognized: #{identifier}" unless respond_to?(identifier, true)

      @fetch ||= {}
      @fetch[identifier] ||= send(identifier)
    end

  private

    # Path ID methods

    def statement_id
      API::Statements::Query.new(lead_provider_id: lead_provider.id)
        .statements
        .distinct(false)
        .reorder("RANDOM()")
        .pick(:api_id)
    end

    def school_id
      contract_period_year = ContractPeriod.order("RANDOM()").pick(:year)
      API::Schools::Query.new(contract_period_year:)
        .schools
        .distinct(false)
        .reorder("RANDOM()")
        .pick(:api_id)
    end

    def delivery_partner_id
      API::DeliveryPartners::Query.new(lead_provider_id: lead_provider.id)
        .delivery_partners
        .distinct(false)
        .reorder("RANDOM()")
        .pick(:api_id)
    end

    def partnership_id
      API::SchoolPartnerships::Query.new(lead_provider_id: lead_provider.id)
        .school_partnerships
        .distinct(false)
        .reorder("RANDOM()")
        .pick(:api_id)
    end

    def teacher_api_id
      API::Teachers::Query.new(lead_provider_id: lead_provider.id)
        .teachers
        .distinct(false)
        .reorder("RANDOM()")
        .pick(:api_id)
    end

    def from_teacher_api_id
      TeacherIdChange
        .joins(teacher: { ect_at_school_periods: { training_periods: :lead_provider } })
        .where(lead_providers: { id: lead_provider.id })
        .distinct(false)
        .reorder("RANDOM()")
        .pick(:api_from_teacher_id)
    end

    def active_teacher_api_id_for_participant_action
      @active_teacher_api_id_for_participant_action ||= API::Teachers::Query.new(lead_provider_id: lead_provider.id, training_status: "active")
                                                        .teachers
                                                        .distinct(false)
                                                        .reorder("RANDOM()")
                                                        .pick(:api_id)
    end

    def withdrawn_teacher_api_id_for_participant_action
      @withdrawn_teacher_api_id_for_participant_action ||= API::Teachers::Query.new(lead_provider_id: lead_provider.id, training_status: "withdrawn")
                                                           .teachers
                                                           .distinct(false)
                                                           .reorder("RANDOM()")
                                                           .pick(:api_id)
    end

    def deferred_teacher_api_id_for_participant_action
      @deferred_teacher_api_id_for_participant_action ||= API::Teachers::Query.new(lead_provider_id: lead_provider.id, training_status: "deferred")
                                                           .teachers
                                                           .distinct(false)
                                                           .reorder("RANDOM()")
                                                           .pick(:api_id)
    end

    # Request body methods

    def partnership_create_body
      contract_period = random_contract_period(lead_provider:)
      return unless contract_period

      lead_provider_delivery_partnerships = lead_provider_delivery_partnerships(lead_provider:, contract_period:)
      return unless lead_provider_delivery_partnerships.any?

      school = random_other_eligible_school(lead_provider_delivery_partnerships:)
      return unless school

      delivery_partner = lead_provider_delivery_partnerships.map(&:delivery_partner).uniq.sample

      {
        data: {
          type: "partnerships",
          attributes: {
            cohort: contract_period.year,
            school_id: school.api_id,
            delivery_partner_id: delivery_partner.api_id,
          },
        },
      }
    end

    def partnership_update_body
      school_partnership = random_school_partnership(lead_provider:)
      return unless school_partnership

      contract_period = school_partnership.contract_period
      lead_provider_delivery_partnership = school_partnership.lead_provider_delivery_partnership
      lead_provider_delivery_partnerships = lead_provider_delivery_partnerships(lead_provider:, contract_period:).where.not(id: lead_provider_delivery_partnership.id)
      return unless lead_provider_delivery_partnerships.any?

      delivery_partner = lead_provider_delivery_partnerships.sample.delivery_partner

      {
        data: {
          type: "partnerships",
          attributes: {
            delivery_partner_id: delivery_partner.api_id,
          },
        },
      }
    end

    def participant_withdraw_payload(participant)
      {
        data: {
          type: "participant-withdraw",
          attributes: {
            reason: TrainingPeriod.withdrawal_reasons.values.map(&:dasherize).sample,
            course_identifier: participant.api_ect_training_record_id.present? ? "ecf-induction" : "ecf-mentor",
          },
        },
      }
    end

    def active_participant_withdraw_body
      participant = Teacher.find_by(api_id: active_teacher_api_id_for_participant_action)

      participant_withdraw_payload(participant)
    end

    def withdrawn_participant_withdraw_body
      participant = Teacher.find_by(api_id: withdrawn_teacher_api_id_for_participant_action)

      participant_withdraw_payload(participant)
    end

    def participant_defer_payload(participant)
      {
        data: {
          type: "participant-defer",
          attributes: {
            reason: TrainingPeriod.deferral_reasons.values.map(&:dasherize).sample,
            course_identifier: participant.api_ect_training_record_id.present? ? "ecf-induction" : "ecf-mentor",
          },
        },
      }
    end

    def active_participant_defer_body
      participant = Teacher.find_by(api_id: active_teacher_api_id_for_participant_action)

      participant_defer_payload(participant)
    end

    def deferred_participant_defer_body
      participant = Teacher.find_by(api_id: deferred_teacher_api_id_for_participant_action)

      participant_defer_payload(participant)
    end

    # Helpers

    def random_school_partnership(lead_provider:)
      SchoolPartnership
        .joins(lead_provider_delivery_partnership: :active_lead_provider)
        .where(active_lead_provider: { lead_provider: })
        .order("RANDOM()")
        .first
    end

    def random_contract_period(lead_provider:)
      lead_provider
        .lead_provider_delivery_partnerships
        .joins(:contract_period)
        .where(contract_period: { enabled: true })
        .order("RANDOM()")
        .first
        &.contract_period
    end

    def lead_provider_delivery_partnerships(lead_provider:, contract_period:)
      lead_provider
        .lead_provider_delivery_partnerships
        .joins(:active_lead_provider)
        .where(active_lead_provider: { contract_period: })
    end

    def random_other_eligible_school(lead_provider_delivery_partnerships:)
      existing_school_ids = lead_provider_delivery_partnerships
        .joins(school_partnerships: :school)
        .pluck(:school_id)
        .uniq

      School.where.not(id: existing_school_ids).eligible.not_cip_only.order("RANDOM()").first
    end
  end
end
