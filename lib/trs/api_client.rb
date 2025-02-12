module TRS
  class APIClient
    def initialize
      @connection = Faraday.new(url: Rails.application.config.trs_api_base_url) do |faraday|
        faraday.headers['Authorization'] = "Bearer #{Rails.application.config.trs_api_key}"
        faraday.headers['Accept'] = 'application/json'
        faraday.headers['X-Api-Version'] = Rails.application.config.trs_api_version
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

    def pass_induction!(trn:, start_date:, completed_date:, modified_at: Time.zone.now)
      update_induction_status(trn:, status: 'Passed', start_date:, completed_date:, modified_at:)
    end

    def fail_induction!(trn:, start_date:, completed_date:, modified_at: Time.zone.now)
      update_induction_status(trn:, status: 'Failed', start_date:, completed_date:, modified_at:)
    end

  private

    def update_induction_status(trn:, status:, modified_at:, start_date:, completed_date: nil)
      payload = { 'status' => status,
                  'startDate' => start_date,
                  'completedDate' => completed_date,
                  'modifiedOn' => modified_at }.compact.to_json

      response = @connection.put(persons_path(trn, suffix: 'cpd-induction'), payload)

      Rails.logger.debug("calling TRS API: #{response}")

      if response.success?
        Rails.logger.debug("OK")

        # FIXME: is there anything that comes back in legit responses that
        #        we want to keep hold of?
        true
      else
        Rails.logger.error("Error: #{response.status}")
        Rails.logger.error("Response: #{response.body}")

        false
      end
    end

    def persons_path(trn, suffix: nil)
      ['v3', 'persons', trn, suffix].compact.join('/')
    end
  end
end
