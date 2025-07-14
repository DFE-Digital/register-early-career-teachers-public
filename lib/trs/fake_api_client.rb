module TRS
  class FakeAPIClient
    class FakeAPIClientUsedInProduction < StandardError; end

    def initialize(raise_not_found: false, raise_deactivated: false)
      fail(FakeAPIClientUsedInProduction) if Rails.env.production?

      @raise_not_found = raise_not_found
      @raise_deactivated = raise_deactivated
    end

    def find_teacher(trn:, date_of_birth: "1977-02-03", national_insurance_number: nil)
      raise(TRS::Errors::TeacherNotFound, "Teacher with TRN #{trn} not found") if @raise_not_found
      raise(TRS::Errors::TeacherDeactivated, "Teacher with TRN #{trn} deactivated") if @raise_deactivated

      Rails.logger.info("TRSFakeAPIClient pretending to find teacher with TRN=#{trn} and Date of birth=#{date_of_birth} and National Insurance Number=#{national_insurance_number}")

      override_data_for_special_trns(trn)

      build_trs_teacher(trn:, date_of_birth:, national_insurance_number:)
    end

    def begin_induction!(trn:, start_date:, modified_at: Time.zone.now)
      Rails.logger.info("TRSFakeAPIClient pretending to begin teacher with TRN=#{trn}'s induction")

      update_induction_status(
        trn:,
        status: 'InProgress',
        start_date: start_date.iso8601,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

    def pass_induction!(trn:, start_date:, completed_date:, modified_at: Time.zone.now)
      Rails.logger.info("TRSFakeAPIClient pretending to pass teacher with TRN=#{trn}'s induction")

      update_induction_status(
        trn:,
        status: 'Passed',
        start_date: start_date.iso8601,
        completed_date: completed_date.iso8601,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

    def fail_induction!(trn:, start_date:, completed_date:, modified_at: Time.zone.now)
      Rails.logger.info("TRSFakeAPIClient pretending to fail teacher with TRN=#{trn}'s induction")

      update_induction_status(
        trn:,
        status: 'Failed',
        start_date: start_date.iso8601,
        completed_date: completed_date.iso8601,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

    def reset_teacher_induction(trn:, modified_at: Time.zone.now)
      Rails.logger.info("TRSFakeAPIClient pretending to reset teacher with TRN=#{trn}'s induction")

      update_induction_status(
        trn:,
        status: 'RequiredToComplete',
        start_date: nil,
        completed_date: nil,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

  private

    def redis_client
      @redis_client ||= Redis.new(url: ENV.fetch('REDIS_CACHE_URL', 'redis://localhost:6379'))
    end

    def redis_induction_key(trn)
      "#{trn}:induction"
    end

    def update_induction_status(trn:, status:, modified_at:, start_date:, completed_date: nil)
      payload = { 'status' => status,
                  'startDate' => start_date,
                  'completedDate' => completed_date,
                  'modifiedOn' => modified_at }.transform_values { |v| (v.present?) ? v : '' }

      redis_client.mapped_hmset(redis_induction_key(trn), payload)
    end

    # FIXME: Named for consistency with update_induction_status in the real client, but it's doing more
    #        than just the status, both should probably end with _induction_details
    def retrieve_induction_status(trn)
      redis_client
        .hgetall(redis_induction_key(trn))
        .transform_values { |v| (v.present?) ? v : nil }
    end

    def build_trs_teacher(trn:, date_of_birth:, national_insurance_number:)
      TRS::Teacher.new(
        teacher_params(trn:, date_of_birth:, national_insurance_number:).tap do |tp|
          tp.merge!(qts_data)
          tp.merge!(itt_data)

          if @is_prohibited_from_teaching
            tp.merge!(prohibited_from_teaching_data)
          elsif @has_alerts_but_not_prohibited
            tp.merge!(other_alert_data)
          end

          tp.merge!(induction_data(trn))
        end
      )
    end

    def override_data_for_special_trns(trn)
      case trn.to_i
      when 7_000_001 then @has_qts = false
      when 7_000_002 then raise(TRS::Errors::TeacherNotFound)
      when 7_000_003 then @is_prohibited_from_teaching = true
      when 7_000_004 then raise(TRS::Errors::TeacherDeactivated)
      when 7_000_005 then @has_alerts_but_not_prohibited = true
      when 7_000_006 then nil # teacher with TRN 7000006 is seeded as an early roll out mentor
      else
        @has_qts = true
        @has_itt = true
        @is_prohibited_from_teaching = false
        @has_alerts_but_not_prohibited = false
      end
    end

    def teacher_params(trn:, date_of_birth:, national_insurance_number:, first_name: 'Kirk', last_name: 'Van Houten')
      if (teacher = ::Teacher.find_by(trn:))
        {
          'trn' => teacher.trn,
          'firstName' => teacher.trs_first_name,
          'lastName' => teacher.trs_last_name,
          'dateOfBirth' => date_of_birth,
          'nationalInsuranceNumber' => national_insurance_number,
        }
      else
        first_name, last_name = *random_name

        {
          'trn' => trn,
          'firstName' => first_name,
          'lastName' => last_name,
          'dateOfBirth' => date_of_birth,
          'nationalInsuranceNumber' => national_insurance_number,
        }
      end
    end

    def random_name
      File.read(Rails.root.join('lib/trs/fake_api_names.yml')).split("\n").sample.split(" ", 2)
    end

    def qts_data
      if @has_qts
        {
          'qts' => {
            'awarded' => Time.zone.today - 3.years,
            'certificateUrl' => 'https://fancy-certificates.example.com/1234',
            'statusDescription' => 'Passed'
          }
        }
      else
        { 'qts' => nil }
      end
    end

    def prohibited_from_teaching_data
      {
        'alerts' => [{ 'alertType' => { 'alertCategory' => { 'alertCategoryId' => TRS::Teacher::PROHIBITED_FROM_TEACHING_CATEGORY_ID } } }]
      }
    end

    def other_alert_data
      {
        # Conditional Registration Order - unacceptable professional conduct
        'alerts' => [{ 'alertType' => { 'alertCategory' => { 'alertCategoryId' => '5562a5b7-3e32-eb11-a814-000d3a23980a' } } }]
      }
    end

    def induction_data(trn)
      return { 'induction' => { 'status' => @induction_status } } if @induction_status

      if redis_client.connected? && (induction_status = retrieve_induction_status(trn)) && induction_status.present?
        {
          'induction' => {
            'status' => induction_status['status'],
            'startDate' => induction_status['startDate'],
            'completedDate' => induction_status['completedDate']
          }
        }
      else
        {
          'induction' => {
            'status' => 'InProgress',
            'startDate' => 2.years.ago.to_date.to_s,
            'completedDate' => 1.year.ago.to_date.to_s
          }
        }
      end
    end

    def itt_data
      if @has_itt
        {
          "initialTeacherTraining" => [
            {
              "qualification" => { "name" => "Postgraduate Certificate in Education" },
              "startDate" => "2020-12-31",
              "result" => "Pass",
              "subjects" => [],
              "endDate" => "2021-04-05",
              "programmeType" => nil,
              "programmeTypeDescription" => nil,
              "ageRange" => nil,
              "provider" => { "name" => "Example Provider Ltd." },
            }
          ]
        }
      else
        { "initialTeacherTraining" => [] }
      end
    end
  end
end
