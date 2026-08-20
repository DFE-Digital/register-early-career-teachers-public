module DataCorrections
  class ECTContractPeriodCorrection
    class InvalidCorrection < StandardError; end

    def initialize(
      training_period:,
      teacher_id:,
      current_contract_period_year:,
      replacement_contract_period_year:,
      replacement_schedule: nil,
      replacement_school_partnership: nil,
      replacement_expression_of_interest: nil,
      allow_finished_training_period: false
    )
      @training_period = training_period
      @teacher_id = teacher_id
      @current_contract_period_year = current_contract_period_year
      @replacement_contract_period_year =
        replacement_contract_period_year
      @replacement_schedule = replacement_schedule
      @replacement_school_partnership =
        replacement_school_partnership
      @replacement_expression_of_interest =
        replacement_expression_of_interest
      @allow_finished_training_period =
        allow_finished_training_period
    end

    def preview
      validate!

      {
        contract_period: replacement_contract_period,
        schedule: replacement_schedule,
        school_partnership: replacement_school_partnership,
        expression_of_interest: replacement_expression_of_interest
      }
    end

    def call
      preview

      ApplicationRecord.transaction do
        training_period.update!(
          schedule: replacement_schedule,
          school_partnership: replacement_school_partnership,
          expression_of_interest: replacement_expression_of_interest
        )
      end

      training_period.reload
    end

  private

    attr_reader :training_period,
                :teacher_id,
                :current_contract_period_year,
                :replacement_contract_period_year,
                :allow_finished_training_period

    def validate!
      validate_training_period!
      validate_contract_period_change!
      validate_current_partnership_or_expression_of_interest!
      validate_replacement_schedule!
      validate_replacement_partnership_or_expression_of_interest!
      validate_replacement_school_partnership!
      validate_replacement_expression_of_interest!
    end

    def validate_training_period!
      unless training_period.ect_at_school_period
        raise InvalidCorrection,
              "Training period must be for an ECT"
      end

      unless teacher.id == teacher_id
        raise InvalidCorrection,
              "Training period belongs to a different teacher"
      end

      unless training_period.provider_led_training_programme?
        raise InvalidCorrection,
              "Training period must be provider-led"
      end

      if training_period.finished_on.present? &&
          !allow_finished_training_period
        raise InvalidCorrection,
              "Training period must be ongoing"
      end

      unless training_period_contract_period&.year ==
          current_contract_period_year
        raise InvalidCorrection,
              "Training period uses a different current contract period"
      end

      unless training_period.schedule
        raise InvalidCorrection,
              "Training period has no schedule"
      end
    end

    def validate_contract_period_change!
      if replacement_contract_period == training_period_contract_period
        raise InvalidCorrection,
              "Replacement contract period is the current contract period"
      end
    end

    def validate_current_partnership_or_expression_of_interest!
      return if training_period.school_partnership.present? ||
        training_period.expression_of_interest.present?

      raise InvalidCorrection,
            "Training period must have a school partnership or expression of interest"
    end

    def validate_replacement_schedule!
      unless replacement_schedule.contract_period_year ==
          replacement_contract_period_year
        raise InvalidCorrection,
              "Replacement schedule uses the wrong contract period"
      end

      unless replacement_schedule.identifier ==
          training_period.schedule.identifier
        raise InvalidCorrection,
              "Replacement schedule uses a different identifier"
      end
    end

    def validate_replacement_partnership_or_expression_of_interest!
      return if replacement_school_partnership.present? ||
        replacement_expression_of_interest.present?

      raise InvalidCorrection,
            "Could not identify a replacement school partnership or expression of interest"
    end

    def validate_replacement_school_partnership!
      return unless replacement_school_partnership

      unless replacement_school_partnership.school == school
        raise InvalidCorrection,
              "Partnership belongs to the wrong school"
      end

      unless replacement_school_partnership.lead_provider ==
          lead_provider
        raise InvalidCorrection,
              "Partnership changes the lead provider"
      end

      unless replacement_school_partnership.contract_period ==
          replacement_contract_period
        raise InvalidCorrection,
              "Partnership uses the wrong contract period"
      end
    end

    def validate_replacement_expression_of_interest!
      return unless replacement_expression_of_interest

      unless replacement_expression_of_interest.lead_provider ==
          lead_provider
        raise InvalidCorrection,
              "Expression of interest changes the lead provider"
      end

      unless replacement_expression_of_interest.contract_period ==
          replacement_contract_period
        raise InvalidCorrection,
              "Expression of interest uses the wrong contract period"
      end
    end

    def replacement_contract_period
      @replacement_contract_period ||=
        find_single!(
          ContractPeriod.where(
            year: replacement_contract_period_year
          ),
          "replacement contract period"
        )
    end

    def replacement_schedule
      @replacement_schedule ||=
        find_single!(
          Schedule.where(
            contract_period_year: replacement_contract_period_year,
            identifier: training_period.schedule.identifier
          ),
          "replacement schedule"
        )
    end

    def replacement_school_partnership
      return unless training_period.school_partnership

      @replacement_school_partnership ||=
        find_single!(
          SchoolPartnership
            .joins(lead_provider_delivery_partnership: :framework_agreement)
            .where(
              school:,
              framework_agreements: {
                id: replacement_framework_agreement.id
              }
            ),
          "replacement school partnership"
        )
    end

    def replacement_framework_agreement
      @replacement_framework_agreement ||=
        find_single!(
          FrameworkAgreement.where(
            lead_provider:,
            contract_period: replacement_contract_period
          ),
          "replacement lead provider framework agreement"
        )
    end

    def replacement_expression_of_interest
      return unless training_period.expression_of_interest

      @replacement_expression_of_interest ||=
        find_single!(
          FrameworkAgreement.where(
            lead_provider:,
            contract_period: replacement_contract_period
          ),
          "replacement expression of interest"
        )
    end

    def find_single!(relation, description)
      records = relation.limit(2).to_a

      if records.empty?
        raise InvalidCorrection,
              "No matching #{description} found"
      end

      if records.many?
        raise InvalidCorrection,
              "More than one matching #{description} found; supply its ID explicitly"
      end

      records.first
    end

    def training_period_contract_period
      training_period.school_partnership&.contract_period ||
        training_period.expression_of_interest_contract_period ||
        training_period.schedule&.contract_period
    end

    def teacher
      training_period.ect_at_school_period.teacher
    end

    def school
      training_period.ect_at_school_period.school
    end

    def lead_provider
      training_period.school_partnership&.lead_provider ||
        training_period.expression_of_interest&.lead_provider
    end
  end
end
