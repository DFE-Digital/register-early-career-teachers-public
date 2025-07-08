module TRS
  # The TRS::FakeAPIClient is intended to be used in two 'modes'
  #
  # The default mode is intended for testing, the class can be directly instantiated
  # with custom data to return TRS::Teacher objects in various states
  #
  # When random mode is enabled (by passing in `random_mode: true`) it's intended to
  # be used by the app.
  #
  # In this mode TRS::Teacher objects in various states can be returned by
  # passing in special TRNs, outlined in #override_data_for_special_trns.
  #
  # Any other random TRN will return a TRS::Teacher with a random name from
  # lib/trs/fake_api_names.yml
  class FakeAPIClient
    class FakeAPIClientUsedInProduction < StandardError; end
    attr_reader :random_mode

    def initialize(
      random_mode: false,
      raise_not_found: false,
      raise_deactivated: false,
      induction_status: nil,
      has_qts: true,
      has_itt: true,
      is_prohibited_from_teaching: false,
      has_alerts_but_not_prohibited: false
    )
      fail(FakeAPIClientUsedInProduction) if Rails.env.production?

      @random_mode = random_mode

      @raise_not_found = raise_not_found
      @raise_deactivated = raise_deactivated
      @induction_status = induction_status
      @has_qts = has_qts
      @has_itt = has_itt
      @is_prohibited_from_teaching = is_prohibited_from_teaching
      @has_alerts_but_not_prohibited = has_alerts_but_not_prohibited
    end

    def find_teacher(trn:, date_of_birth: "1977-02-03", national_insurance_number: nil)
      raise(TRS::Errors::TeacherNotFound, "Teacher with TRN #{trn} not found") if @raise_not_found
      raise(TRS::Errors::TeacherDeactivated, "Teacher with TRN #{trn} deactivated") if @raise_deactivated

      Rails.logger.info("TRSFakeAPIClient pretending to find teacher with TRN=#{trn} and Date of birth=#{date_of_birth} and National Insurance Number=#{national_insurance_number}")

      override_data_for_special_trns(trn) if random_mode
      build_trs_teacher(trn:, date_of_birth:, national_insurance_number:)
    end

    def pass_induction!(...)
    end

    def fail_induction!(...)
    end

    def begin_induction!(...)
    end

    def reset_teacher_induction(...)
    end

  private

    def build_trs_teacher(trn:, date_of_birth:, national_insurance_number:)
      TRS::Teacher.new(
        teacher_params(trn:, date_of_birth:, national_insurance_number:).tap do |tp|
          tp.merge!(qts_data)
          tp.merge!(itt)

          if @is_prohibited_from_teaching
            tp.merge!(prohibited_from_teaching)
          elsif @has_alerts_but_not_prohibited
            tp.merge!(other_alerts)
          end

          tp.merge!(induction_status)
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
      end
    end

    def teacher_params(trn:, date_of_birth:, national_insurance_number:, first_name: 'Kirk', last_name: 'Van Houten')
      first_name, last_name = *random_name if @random_mode

      {
        'trn' => trn,
        'firstName' => first_name,
        'lastName' => last_name,
        'dateOfBirth' => date_of_birth,
        'nationalInsuranceNumber' => national_insurance_number,
      }
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

    def prohibited_from_teaching
      if @is_prohibited_from_teaching
        {
          'alerts' => [{ 'alertType' => { 'alertCategory' => { 'alertCategoryId' => TRS::Teacher::PROHIBITED_FROM_TEACHING_CATEGORY_ID } } }]
        }
      else
        {
          'alerts' => []
        }
      end
    end

    def other_alerts
      if @has_alerts_but_not_prohibited
        {
          # Conditional Registration Order - unacceptable professional conduct
          'alerts' => [{ 'alertType' => { 'alertCategory' => { 'alertCategoryId' => '5562a5b7-3e32-eb11-a814-000d3a23980a' } } }]
        }
      else
        {
          'alerts' => []
        }
      end
    end

    def induction_status
      if @induction_status
        { 'induction' => { 'status' => @induction_status } }
      else
        {}
      end
    end

    def itt
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
