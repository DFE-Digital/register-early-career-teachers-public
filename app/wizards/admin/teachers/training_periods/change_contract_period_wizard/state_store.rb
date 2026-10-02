module Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard
  class StateStore
    include DfE::Wizard::StateStore

    PartnershipOption = Data.define(:id, :name)

    attr_reader :training_period

    def initialize(training_period:, **)
      super(**)
      @training_period = training_period
    end

    delegate :teacher, :school, to: :training_period

    def teacher_name = ::Teachers::Name.new(teacher).full_name

    def training_period_eoi_only? = training_period.only_expression_of_interest?
    def no_school_partnerships? = !school_partnerships.exists?
    def multiple_school_partnerships? = school_partnerships.many?

    def contract_periods
      ::Admin::Teachers::TrainingPeriods::ChangeContractPeriod::AvailableContractPeriods
        .new(training_period:)
        .contract_periods
    end

    def existing_contract_period
      training_period.contract_period || training_period.expression_of_interest_contract_period
    end

    def selected_contract_period
      return if contract_period_year.blank?

      contract_periods.find_by(year: contract_period_year)
    end

    def school_partnerships
      return SchoolPartnership.none unless selected_contract_period

      if future_period_with_current_active_period?
        return SchoolPartnership.none unless same_partnership_as_current_active_period?

        school_partnership_search(
          lead_provider: current_active_period.lead_provider,
          delivery_partner: current_active_period.delivery_partner
        )
      else
        school_partnership_search
      end
    end

    def selected_school_partnership
      return only_school_partnership if only_school_partnership
      return if school_partnership_id.blank?

      school_partnerships.find_by(id: school_partnership_id)
    end

    def partnership_options
      school_partnerships.map do |partnership|
        PartnershipOption.new(id: partnership.id, name: partnership_name(partnership))
      end
    end

    def selected_partnership_name
      partnership_name(selected_school_partnership) if selected_school_partnership
    end

    def selected_lead_provider_name
      training_period.expression_of_interest_lead_provider.name
    end

  private

    def partnership_name(partnership)
      "#{partnership.lead_provider.name} & #{partnership.delivery_partner.name}"
    end

    def school_partnership_search(lead_provider: :ignore, delivery_partner: :ignore)
      SchoolPartnerships::Search
        .new(
          school:,
          contract_period: selected_contract_period,
          lead_provider:,
          delivery_partner:
        )
        .school_partnerships
        .includes(:lead_provider, :delivery_partner)
    end

    def same_partnership_as_current_active_period?
      current_active_period.lead_provider_delivery_partnership == training_period.lead_provider_delivery_partnership
    end

    def future_period_with_current_active_period?
      current_active_period.present? && training_period.started_on > Time.zone.today
    end

    def current_active_period
      @current_active_period ||= ::TrainingPeriods::RelatedPeriods.new(training_period:).current_active_period
    end

    def only_school_partnership
      partnerships = school_partnerships.limit(2).to_a
      partnerships.first if partnerships.one?
    end
  end
end
