module TRS
  class FakeAPIClient
    def initialize(raise_not_found: false, include_qts: true, include_itt: true, prohibited_from_teaching: false, induction_status: nil)
      @raise_not_found = raise_not_found
      @include_qts = include_qts
      @include_itt = include_itt
      @prohibited_from_teaching = prohibited_from_teaching
      @induction_status = induction_status
    end

    def find_teacher(trn:, date_of_birth: "1977-02-03", national_insurance_number: nil)
      raise(TRS::Errors::TeacherNotFound, "Teacher with TRN #{trn} not found") if @raise_not_found

      Rails.logger.info("TRSFakeAPIClient pretending to find teacher with TRN=#{trn} and Date of birth=#{date_of_birth} and National Insurance Number=#{national_insurance_number}")

      TRS::Teacher.new(
        teacher_params(trn:, date_of_birth:, national_insurance_number:)
          .merge(qts)
          .merge(itt)
          .merge(prohibited_from_teaching)
          .merge(induction_status)
      )
    end

    def pass_induction!(...)
    end

    def fail_induction!(...)
    end

    def begin_induction!(...)
    end

  private

    def teacher_params(trn:, date_of_birth:, national_insurance_number:)
      {
        'trn' => trn,
        'firstName' => 'Kirk',
        'lastName' => 'Van Houten',
        'dateOfBirth' => date_of_birth,
        'nationalInsuranceNumber' => national_insurance_number,
      }
    end

    def qts
      return {} unless @include_qts

      {
        'qts' => {
          'awarded' => Time.zone.today - 3.years,
          'certificateUrl' => 'https://fancy-certificates.example.com/1234',
          'statusDescription' => 'Passed'
        }
      }
    end

    def prohibited_from_teaching
      return {} unless @prohibited_from_teaching

      {
        'alerts' => [{ 'alertType' => { 'alertCategory' => { 'alertCategoryId' => 'b2b19019-b165-47a3-8745-3297ff152581' } } }],
      }
    end

    def induction_status
      return {} unless @induction_status

      {
        'induction' => { 'status' => @induction_status },
      }
    end

    def itt
      return {} unless @include_itt

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
    end
  end
end
