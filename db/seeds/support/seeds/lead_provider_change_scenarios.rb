module Seeds
  class LeadProviderChangeScenarios
    SCHOOL_URN = 1_759_427
    SCHEDULE_IDENTIFIER = "ecf-standard-september"

    CURRENT_LEAD_PROVIDER_NAME = "Lead provider change – current provider"
    NEW_LEAD_PROVIDER_NAME = "Lead provider change – alternative provider"

    CURRENT_DELIVERY_PARTNER_NAME = "Lead provider change – current delivery partner"
    NEW_DELIVERY_PARTNER_NAME = "Lead provider change – alternative delivery partner"

    def call
      ensure_reference_data!
      ensure_school_partnerships!
      seed_ect_with_future_training_period_and_billable_declaration!
    end

  private

    def school
      @school ||= School.find_by!(urn: SCHOOL_URN)
    end

    def contract_period
      @contract_period ||= ContractPeriod.current
    end

    def schedule
      @schedule ||= Schedule.find_by!(
        contract_period:,
        identifier: SCHEDULE_IDENTIFIER
      )
    end

    def current_lead_provider
      @current_lead_provider ||= LeadProvider.find_or_create_by!(
        name: CURRENT_LEAD_PROVIDER_NAME
      )
    end

    def new_lead_provider
      @new_lead_provider ||= LeadProvider.find_or_create_by!(
        name: NEW_LEAD_PROVIDER_NAME
      )
    end

    def current_delivery_partner
      @current_delivery_partner ||= DeliveryPartner.find_or_create_by!(
        name: CURRENT_DELIVERY_PARTNER_NAME
      )
    end

    def new_delivery_partner
      @new_delivery_partner ||= DeliveryPartner.find_or_create_by!(
        name: NEW_DELIVERY_PARTNER_NAME
      )
    end

    def ensure_reference_data!
      current_lead_provider
      new_lead_provider
      current_delivery_partner
      new_delivery_partner
    end

    def ensure_school_partnerships!
      current_school_partnership
      alternative_school_partnership
    end

    def current_school_partnership
      @current_school_partnership ||= ensure_school_partnership!(
        lead_provider: current_lead_provider,
        delivery_partner: current_delivery_partner
      )
    end

    def alternative_school_partnership
      @alternative_school_partnership ||= ensure_school_partnership!(
        lead_provider: new_lead_provider,
        delivery_partner: new_delivery_partner
      )
    end

    def ensure_school_partnership!(lead_provider:, delivery_partner:)
      framework_agreement = FrameworkAgreement.find_or_create_by!(
        lead_provider:,
        contract_period:
      )

      lead_provider_delivery_partnership =
        LeadProviderDeliveryPartnership.find_or_create_by!(
          framework_agreement:,
          delivery_partner:
        )

      SchoolPartnership.find_or_create_by!(
        school:,
        lead_provider_delivery_partnership:
      )
    end

    def seed_ect_with_future_training_period_and_billable_declaration!
      teacher = ensure_teacher!

      ect_at_school_period = ECTAtSchoolPeriod.find_or_create_by!(
        teacher:,
        school:
      ) do |period|
        period.started_on = Date.current
        period.finished_on = nil
        period.email = "billable.declaration@example.com"
        period.working_pattern = "full_time"
        period.school_reported_appropriate_body = AppropriateBodyPeriod.first
      end

      ect_at_school_period.update!(
        email: "billable.declaration@example.com",
        working_pattern: "full_time"
      )

      training_period = TrainingPeriod.find_or_create_by!(
        ect_at_school_period:,
        started_on: 1.month.from_now.to_date
      ) do |period|
        period.training_programme = "provider_led"
        period.schedule = schedule
        period.school_partnership = current_school_partnership
        period.expression_of_interest = nil
        period.finished_on = nil
      end

      unless training_period.declarations.billable.exists?
        FactoryBot.create(
          :declaration,
          :paid,
          training_period:
        )
      end
    end

    def ensure_teacher!
      teacher = Teacher.find_or_initialize_by(trn: "9100200")

      teacher.trs_first_name = "Billable"
      teacher.trs_last_name = "Declaration"
      teacher.trs_qts_awarded_on ||= Date.new(2021, 1, 1)
      teacher.ect_first_became_eligible_for_training_at ||= Date.current

      teacher.save!
      teacher
    end
  end
end
