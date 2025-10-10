module TRS
  # Unpack API response and validate eligibility
  class Teacher
    PROHIBITED_FROM_TEACHING_CATEGORY_ID = 'b2b19019-b165-47a3-8745-3297ff152581'

    # Conditional Registration Order
    UNACCEPTABLE_CONDUCT_CATEGORY_ID = '5562a5b7-3e32-eb11-a814-000d3a23980a'

    # Induction Statuses
    INELIGIBLE_INDUCTION_STATUSES = %w[Passed Failed FailedInWales Exempt].freeze
    ELIGIBLE_INDUCTION_STATUSES = %w[None RequiredToComplete InProgress].freeze
    INDUCTION_STATUSES = (ELIGIBLE_INDUCTION_STATUSES + INELIGIBLE_INDUCTION_STATUSES).freeze

    attr_reader :trn,
                :date_of_birth,
                :trs_first_name,
                :trs_last_name,
                :trs_email_address,
                :trs_national_insurance_number,
                :trs_alerts,
                :trs_induction_start_date,
                :trs_induction_completed_date,
                :trs_induction_status,
                :trs_induction_status_description,
                :trs_qts_awarded_on,
                :trs_qts_status_description,
                :trs_initial_teacher_training_provider_name,
                :trs_initial_teacher_training_end_date

    # @param data [Hash{String=>Mixed}] TRS API response
    def initialize(data)
      @trn = data['trn']
      @date_of_birth = data['dateOfBirth']
      @trs_first_name = data['firstName']
      @trs_last_name = data['lastName']
      @trs_email_address = data['emailAddress']
      @trs_national_insurance_number = data['nationalInsuranceNumber']
      @trs_alerts = data.fetch('alerts', []).map { |a| a.dig(*%w[alertType alertCategory alertCategoryId]) }
      @trs_induction_start_date = data.dig('induction', 'startDate')
      @trs_induction_completed_date = data.dig('induction', 'completedDate')
      @trs_induction_status = data.dig('induction', 'status')
      @trs_induction_status_description = data.dig('induction', 'statusDescription')
      @trs_qts_awarded_on = data.dig('qts', 'awarded')
      @trs_qts_status_description = data.dig('qts', 'statusDescription')
      @trs_initial_teacher_training_provider_name = data.dig('initialTeacherTraining', -1, 'provider', 'name')
      @trs_initial_teacher_training_end_date = data.dig('initialTeacherTraining', -1, 'endDate')
    end

    # @return [Boolean]
    def prohibited_from_teaching?
      PROHIBITED_FROM_TEACHING_CATEGORY_ID.in?(trs_alerts)
    end

    # @return [Boolean]
    def no_qts?
      trs_qts_awarded_on.blank?
    end

    # @return [Boolean]
    def already_completed?
      INELIGIBLE_INDUCTION_STATUSES.include?(trs_induction_status)
    end

    # @return [Boolean]
    def has_alerts?
      trs_alerts.any?
    end

    # @raise [Errors::InductionAlreadyCompleted, Errors::ProhibitedFromTeaching, Errors::QTSNotAwarded]
    # @return [true]
    def check_eligibility!
      raise Errors::InductionAlreadyCompleted if already_completed?
      raise Errors::ProhibitedFromTeaching if prohibited_from_teaching?
      raise Errors::QTSNotAwarded if no_qts?

      true
    end

    # @return [Hash] saved to PendingInductionSubmission record
    def to_h
      {
        trn:,
        date_of_birth:,
        trs_first_name:,
        trs_last_name:,
        trs_email_address:,
        trs_induction_start_date:,
        trs_induction_completed_date:,
        trs_induction_status:,
        trs_induction_status_description:,
        trs_qts_awarded_on:,
        trs_qts_status_description:,
        trs_initial_teacher_training_provider_name:,
        trs_initial_teacher_training_end_date:,
        trs_alerts:,
        trs_prohibited_from_teaching: prohibited_from_teaching?,
      }
    end
  end
end
