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
                :first_name,
                :last_name,
                :email_address,
                :national_insurance_number,
                :alerts,
                :induction_start_date,
                :induction_completed_date,
                :induction_status,
                :induction_status_description,
                :qts_awarded_on,
                :qts_status_description,
                :initial_teacher_training_provider_name,
                :initial_teacher_training_end_date

    # @param data [Hash{String=>Mixed}] TRS API response
    def initialize(data)
      @trn = data['trn']
      @date_of_birth = data['dateOfBirth']
      @first_name = data['firstName']
      @last_name = data['lastName']
      @email_address = data['emailAddress']
      @national_insurance_number = data['nationalInsuranceNumber']
      @alerts = data.fetch('alerts', []).map { |a| a.dig(*%w[alertType alertCategory alertCategoryId]) }
      @induction_start_date = data.dig('induction', 'startDate')
      @induction_completed_date = data.dig('induction', 'completedDate')
      @induction_status = data.dig('induction', 'status')
      @induction_status_description = data.dig('induction', 'statusDescription')
      @qts_awarded_on = data.dig('qts', 'awarded')
      @qts_status_description = data.dig('qts', 'statusDescription')
      @initial_teacher_training_provider_name = data.dig('initialTeacherTraining', -1, 'provider', 'name')
      @initial_teacher_training_end_date = data.dig('initialTeacherTraining', -1, 'endDate')
    end

    # @return [Boolean]
    def prohibited_from_teaching?
      PROHIBITED_FROM_TEACHING_CATEGORY_ID.in?(alerts)
    end

    # @return [Boolean]
    def no_qts?
      qts_awarded_on.blank?
    end

    # @return [Boolean]
    def already_completed?
      INELIGIBLE_INDUCTION_STATUSES.include?(induction_status)
    end

    # @return [Boolean]
    def has_alerts?
      alerts.any?
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
        trs_first_name: first_name,
        trs_last_name: last_name,
        trs_email_address: email_address,
        trs_national_insurance_number: national_insurance_number,
        trs_alerts: alerts,
        trs_induction_start_date: induction_start_date,
        trs_induction_completed_date: induction_completed_date,
        trs_induction_status: induction_status,
        trs_induction_status_description: induction_status_description,
        trs_qts_awarded_on: qts_awarded_on,
        trs_qts_status_description: qts_status_description,
        trs_initial_teacher_training_provider_name: initial_teacher_training_provider_name,
        trs_initial_teacher_training_end_date: initial_teacher_training_end_date,
        trs_prohibited_from_teaching: prohibited_from_teaching?,
      }
    end
  end
end
