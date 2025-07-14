module TRS
  class TestAPIClient
    class TestAPIClientUsedInProduction < StandardError; end

    def initialize(
      raise_not_found: false,
      raise_deactivated: false,
      induction_status: nil,
      has_qts: true,
      has_itt: true,
      is_prohibited_from_teaching: false,
      has_alerts_but_not_prohibited: false
    )
      fail(TestAPIClientUsedInProduction) if Rails.env.production?

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

      build_trs_teacher(trn:, date_of_birth:, national_insurance_number:)
    end

    def begin_induction!(...) = nil
    def pass_induction!(...) = nil
    def fail_induction!(...) = nil
    def reset_teacher_induction!(...) = nil
    def reopen_teacher_induction!(...) = nil

  private

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

          tp.merge!(induction_data)
        end
      )
    end

    def teacher_params(trn:, date_of_birth:, national_insurance_number:, first_name: 'Kirk', last_name: 'Van Houten')
      {
        'trn' => trn,
        'firstName' => first_name,
        'lastName' => last_name,
        'dateOfBirth' => date_of_birth,
        'nationalInsuranceNumber' => national_insurance_number,
      }
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

    def induction_data
      if @induction_status
        { 'induction' => { 'status' => @induction_status } }
      else
        { 'induction' => { 'status' => 'RequiredToComplete' } }
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
