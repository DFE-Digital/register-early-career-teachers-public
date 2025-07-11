module TRS
  class APIClient
    private_class_method :new

    def initialize
      @connection = Faraday.new(url: Rails.application.config.trs_api_base_url) do |faraday|
        faraday.headers['Authorization'] = "Bearer #{Rails.application.config.trs_api_key}"
        faraday.headers['Accept'] = 'application/json'
        faraday.headers['X-Api-Version'] = Rails.application.config.trs_api_version
        faraday.headers['Content-Type'] = 'application/json'
        faraday.response :logger if Rails.env.development?
      end
    end

    def self.build
      if Rails.application.config.enable_fake_trs_api
        Rails.logger.warn("Using TRS::FakeAPIClient")

        return TRS::FakeAPIClient.new(random_names: true)
      end

      new
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

      return TRS::Teacher.new(JSON.parse(response.body)) if response.success?

      case Rack::Utils::HTTP_STATUS_CODES.fetch(response.status)
      when "Not Found"
        raise(TRS::Errors::TeacherNotFound)
      when "Gone"
        raise(TRS::Errors::TeacherDeactivated)
      else
        fail(TRS::Errors::APIRequestError, "#{response.status} #{response.body}")
      end
    end

    def begin_induction!(trn:, start_date:, modified_at: Time.zone.now)
      update_induction_status(
        trn:,
        status: 'InProgress',
        start_date: start_date.iso8601,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

    def pass_induction!(trn:, start_date:, completed_date:, modified_at: Time.zone.now)
      update_induction_status(
        trn:,
        status: 'Passed',
        start_date: start_date.iso8601,
        completed_date: completed_date.iso8601,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

    def fail_induction!(trn:, start_date:, completed_date:, modified_at: Time.zone.now)
      update_induction_status(
        trn:,
        status: 'Failed',
        start_date: start_date.iso8601,
        completed_date: completed_date.iso8601,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

    def reset_teacher_induction(trn:, modified_at: Time.zone.now)
      update_induction_status(
        trn:,
        status: 'RequiredToComplete',
        start_date: nil,
        completed_date: nil,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

    def reopen_teacher_induction!(trn:, start_date:, modified_at: Time.zone.now)
      update_induction_status(
        trn:,
        status: 'InProgress',
        start_date: start_date.iso8601,
        completed_date: nil,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

  private

    def update_induction_status(trn:, status:, modified_at:, start_date:, completed_date: nil)
      payload = { 'status' => status,
                  'startDate' => start_date,
                  'completedDate' => completed_date,
                  'modifiedOn' => modified_at }.to_json

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
