module TRS
  class Teacher
    PROHIBITED_FROM_TEACHING_CATEGORY_ID = 'b2b19019-b165-47a3-8745-3297ff152581'.freeze

    attr_reader :trn,
                :first_name,
                :last_name,
                :date_of_birth,
                :induction_status,
                :national_insurance_number,
                :qts_awarded_on,
                :qts_status_description,
                :initial_teacher_training_provider_name,
                :initial_teacher_training_end_date

    def initialize(data)
      @trn = data['trn']
      @first_name = data['firstName']
      @last_name = data['lastName']
      @date_of_birth = data['dateOfBirth']
      @email_address = data['emailAddress']
      @national_insurance_number = data['nationalInsuranceNumber']

      @alerts = data['alerts']
      @induction_start_date = data.dig('induction', 'startDate')
      @induction_status = data.dig('induction', 'status')

      @qts_awarded_on = data.dig('qts', 'awarded')
      @qts_status_description = data.dig('qts', 'statusDescription')

      @induction_status_description = data.dig('induction', 'statusDescription')

      @initial_teacher_training_provider_name = data.dig('initialTeacherTraining', -1, 'provider', 'name')
      @initial_teacher_training_end_date = data.dig('initialTeacherTraining', -1, 'endDate')
    end

    def present
      {
        trn: @trn,
        date_of_birth: @date_of_birth,
        trs_national_insurance_number: @national_insurance_number,
        trs_first_name: @first_name,
        trs_last_name: @last_name,
        trs_email_address: @email_address,
        trs_alerts: @alerts,
        trs_induction_start_date: @induction_start_date,
        trs_induction_status: @induction_status,
        trs_induction_status_description: @induction_status_description,
        trs_initial_teacher_training_provider_name: @initial_teacher_training_provider_name,
        trs_initial_teacher_training_end_date: @initial_teacher_training_end_date,
        trs_qts_awarded_on: @qts_awarded_on,
        trs_qts_status_description: @qts_status_description,
      }
    end

    def check_eligibility!
      raise TRS::Errors::QTSNotAwarded unless qts_awarded?
      raise TRS::Errors::ProhibitedFromTeaching if prohibited_from_teaching?
      raise TRS::Errors::InductionAlreadyCompleted if induction_completed?

      true
    end

    def prohibited_from_teaching?
      PROHIBITED_FROM_TEACHING_CATEGORY_ID.in?(alert_codes)
    end

    def has_alerts?
      alert_codes.any?
    end

    def qts_awarded?
      @qts_awarded_on.present?
    end

    def induction_completed?
      %w[Passed Failed Exempt].include?(@induction_status)
    end

  private

    def api_client
      @api_client ||= TRS::APIClient.build
    end

    def alert_codes
      return [] if @alerts.blank?

      @alerts.map { |a| a.dig(*%w[alertType alertCategory alertCategoryId]) }
    end
  end
end
