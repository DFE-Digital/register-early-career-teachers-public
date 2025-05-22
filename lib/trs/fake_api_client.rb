module TRS
  class FakeAPIClient
    class FakeAPIClientUsedInProduction < StandardError; end
    attr_reader :random_names

    def initialize(
      raise_not_found: false,
      raise_deactivated: false,
      include_qts: true,
      include_itt: true,
      prohibited_from_teaching: false,
      induction_status: nil,
      random_names: false
    )
      fail(FakeAPIClientUsedInProduction) if Rails.env.production?

      @raise_not_found = raise_not_found
      @raise_deactivated = raise_deactivated
      @include_qts = include_qts
      @include_itt = include_itt
      @prohibited_from_teaching = prohibited_from_teaching
      @induction_status = induction_status
      @random_names = random_names
    end

    def find_teacher(trn:, date_of_birth: "1977-02-03", national_insurance_number: nil)
      raise(TRS::Errors::TeacherNotFound, "Teacher with TRN #{trn} not found") if @raise_not_found
      raise(TRS::Errors::TeacherDeactivated, "Teacher with TRN #{trn} deactivated") if @raise_deactivated

      Rails.logger.info("TRSFakeAPIClient pretending to find teacher with TRN=#{trn} and Date of birth=#{date_of_birth} and National Insurance Number=#{national_insurance_number}")

      if random_names
        build_trs_teacher_based_on_trn_range(trn:, date_of_birth:, national_insurance_number:)
      else
        build_trs_teacher(trn:, date_of_birth:, national_insurance_number:)
      end
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
        teacher_params(trn:, date_of_birth:, national_insurance_number:)
          .merge(qts)
          .merge(itt)
          .merge(prohibited_from_teaching)
          .merge(induction_status)
      )
    end

    def build_trs_teacher_based_on_trn_range(trn:, date_of_birth:, national_insurance_number:)
      @induction_status = 'RequiredToComplete'

      case trn.to_i
      when 7_000_001 then raise(TRS::Errors::QTSNotAwarded)
      when 7_000_002 then raise(TRS::Errors::TeacherNotFound)
      when 7_000_003 then raise(TRS::Errors::ProhibitedFromTeaching)
      when 7_000_004 then raise(TRS::Errors::TeacherDeactivated)
      else
        build_trs_teacher(trn:, date_of_birth:, national_insurance_number:)
      end
    end

    def teacher_params(trn:, date_of_birth:, national_insurance_number:, first_name: 'Kirk', last_name: 'Van Houten')
      first_name, last_name = *random_name if @random_names

      {
        'trn' => trn,
        'firstName' => first_name,
        'lastName' => last_name,
        'dateOfBirth' => date_of_birth,
        'nationalInsuranceNumber' => national_insurance_number,
      }
    end

    def random_name
      File.read(Rails.root.join('spec/support/api/trs/fake_api_names.yml')).split("\n").sample.split(" ", 2)
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
