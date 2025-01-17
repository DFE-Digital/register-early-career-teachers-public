module TRS
  class APIClient
    def initialize
      @connection = Faraday.new(url: ENV['TRS_BASE_URL']) do |faraday|
        faraday.headers['Authorization'] = "Bearer #{ENV['TRS_API_KEY']}"
        faraday.headers['Accept'] = 'application/json'
        faraday.headers['X-Api-Version'] = 'Next'
        faraday.headers['Content-Type'] = 'application/json'
        faraday.adapter Faraday.default_adapter
        faraday.response :logger if Rails.env.development?
      end
    end

    # Included items:
    # * Induction
    # * Alerts
    # * InitialTeacherTraining
    # Other available items:
    # * NpqQualifications
    # * MandatoryQualifications
    # * PendingDetailChanges
    # * HigherEducationQualifications
    # * Sanctions
    # * PreviousNames
    # * AllowIdSignInWithProhibitions
    def find_teacher(trn:, date_of_birth: nil, national_insurance_number: nil, include: %w[Induction InitialTeacherTraining Alerts])
      params = { dateOfBirth: date_of_birth, nationalInsuranceNumber: national_insurance_number, include: include.join(",") }.compact
      response = @connection.get(persons_path(trn), params)

      if response.success?
        TRS::Teacher.new(JSON.parse(response.body))
      elsif response.status == 404
        raise TRS::Errors::TeacherNotFound
      else
        raise "API request failed: #{response.status} #{response.body}"
      end
    end

    def begin_induction!(trn:, start_date:, modified_at: Time.zone.now)
      update_induction_status(trn:, status: 'InProgress', start_date:, modified_at:)
    end

    def pass_induction!(trn:, completion_date:, modified_at: Time.zone.now)
      update_induction_status(trn:, status: 'Pass', completion_date:, modified_at:)
    end

    def fail_induction!(trn:, completion_date:, modified_at: Time.zone.now)
      update_induction_status(trn:, status: 'Fail', completion_date:, modified_at:)
    end

  private

    def update_induction_status(trn:, status:, modified_at:, start_date: nil, completion_date: nil)
      payload = { 'inductionStatus' => status,
                  'startDate' => start_date,
                  'completionDate' => completion_date,
                  'modifiedOn' => modified_at }.compact.to_json

      # FIXME: verify this is the right endpoint
      response = @connection.put(persons_path(trn, suffix: 'induction'), payload)

      Rails.logger.debug("calling TRS API: #{response}")

      if response.success?
        Rails.logger.debug("OK")

        # FIXME: is there anything that comes back in legit responses that
        #        we want to keep hold of?
        true
      else
        Rails.logger.warn("Error: #{response.status}")
        Rails.logger.warn("Response: #{response.body}")

        false
      end
    end

    def persons_path(trn, suffix: nil)
      ['v3', 'persons', trn, suffix].compact.join('/')
    end
  end
end
