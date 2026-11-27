module TRS
  # 7000001 - 7000011 are special TRNs that mimic:
  #
  # 1. Missing QTS
  # 2. Not found
  # 3. Prohibited
  # 4. Deactivated
  # 5. Alerts
  # 6. ERO mentor
  # 7. Passed induction
  # 8. Failed induction
  # 9. Exempt
  # 10. Failed induction in Wales
  # 11. Merged
  #
  class FakeAPIClient
    class FakeAPIClientUsedInProduction < StandardError; end

    MERGED_TRN_REDIRECTS_TO = "7000012"

    def initialize(store: TRS::FakeTeacherStore.new)
      fail(FakeAPIClientUsedInProduction) if Rails.env.production?

      @store = store
    end

    def find_teacher(trn:, date_of_birth: "1977-02-03", national_insurance_number: nil, **)
      Rails.logger.info("TRSFakeAPIClient pretending to find teacher with TRN=#{trn} and Date of birth=#{date_of_birth} and National Insurance Number=#{national_insurance_number}")

      options = @store.options_for(trn)
      raise_errors_for_special_trns(trn, options)

      build_trs_teacher(trn:, date_of_birth:, national_insurance_number:, options:)
    end

    def begin_induction!(trn:, start_date:, modified_at: Time.zone.now)
      Rails.logger.info("TRSFakeAPIClient pretending to begin teacher with TRN=#{trn}'s induction")

      update_induction_status(
        trn:,
        status: "InProgress",
        start_date: start_date.iso8601,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

    def pass_induction!(trn:, start_date:, completed_date:, modified_at: Time.zone.now)
      Rails.logger.info("TRSFakeAPIClient pretending to pass teacher with TRN=#{trn}'s induction")

      update_induction_status(
        trn:,
        status: "Passed",
        start_date: start_date.iso8601,
        completed_date: completed_date.iso8601,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

    def fail_induction!(trn:, start_date:, completed_date:, modified_at: Time.zone.now)
      Rails.logger.info("TRSFakeAPIClient pretending to fail teacher with TRN=#{trn}'s induction")

      update_induction_status(
        trn:,
        status: "Failed",
        start_date: start_date.iso8601,
        completed_date: completed_date.iso8601,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

    def reset_teacher_induction!(trn:, modified_at: Time.zone.now)
      Rails.logger.info("TRSFakeAPIClient pretending to reset teacher with TRN=#{trn}'s induction")

      update_induction_status(
        trn:,
        status: "RequiredToComplete",
        start_date: nil,
        completed_date: nil,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

    def reopen_teacher_induction!(trn:, start_date:, modified_at: Time.zone.now)
      Rails.logger.info("TRSFakeAPIClient pretending to reopen teacher with TRN=#{trn}'s induction")

      update_induction_status(
        trn:,
        status: "InProgress",
        start_date: start_date.iso8601,
        completed_date: nil,
        modified_at: modified_at.utc.iso8601(3)
      )
    end

  private

    def update_induction_status(trn:, status:, modified_at:, start_date:, completed_date: nil)
      @store.set_induction(trn, status:, modified_at:, start_date:, completed_date:)
    end

    def build_trs_teacher(trn:, date_of_birth:, national_insurance_number:, options:)
      TRS::Teacher.new(
        teacher_params(trn:, date_of_birth:, national_insurance_number:).tap do |tp|
          tp.merge!(qts_data(options[:has_qts]))
          tp.merge!(itt_data(options[:has_itt]))

          if options[:prohibited_from_teaching]
            tp.merge!(prohibited_from_teaching_data)
          elsif options[:has_alerts]
            tp.merge!(other_alert_data)
          end

          tp.merge!(induction_data(trn, options[:induction_status]))
        end
      )
    end

    def raise_errors_for_special_trns(trn, options)
      case options[:error_type].to_s
      when "not_found" then raise(TRS::Errors::TeacherNotFound, "Teacher with TRN #{trn} not found")
      when "deactivated" then raise(TRS::Errors::TeacherDeactivated, "Teacher with TRN #{trn} deactivated")
      when "merged" then raise(TRS::Errors::TeacherMerged.new(trn:, redirected_to: MERGED_TRN_REDIRECTS_TO))
      end
    end

    def teacher_params(trn:, date_of_birth:, national_insurance_number:, first_name: "Kirk", last_name: "Van Houten")
      if (teacher = ::Teacher.find_by(trn:))
        {
          "trn" => teacher.trn,
          "firstName" => teacher.trs_first_name,
          # "middleName" => teacher.trs_middle_name,
          "lastName" => teacher.trs_last_name,
          "dateOfBirth" => date_of_birth,
          "nationalInsuranceNumber" => national_insurance_number,
        }
      else
        first_name, last_name = *random_name

        {
          "trn" => trn,
          "firstName" => first_name,
          # "middleName" => middle_name,
          "lastName" => last_name,
          "dateOfBirth" => date_of_birth,
          "nationalInsuranceNumber" => national_insurance_number,
        }
      end
    end

    def random_name
      File.readlines(Rails.root.join("lib/trs/fake_api_names.csv"))
          .sample
          .split(" ", 2)
    end

    def qts_data(has_qts)
      if has_qts
        {
          "qts" => {
            "holdsFrom" => 3.years.ago.to_date.to_s,
            "routes" => [
              {
                "routeToProfessionalStatusType" => {
                  "routeToProfessionalStatusTypeId" => "32017d68-9da4-43b2-ae91-4f24c68f6f78",
                  "name" => "HEI - Historic",
                  "professionalStatusType" => "QualifiedTeacherStatus"
                }
              }
            ]
          }
        }
      else
        { "qts" => nil }
      end
    end

    def prohibited_from_teaching_data
      {
        "alerts" => [{ "alertType" => { "alertCategory" => { "alertCategoryId" => TRS::Teacher::PROHIBITED_FROM_TEACHING_CATEGORY_ID } } }]
      }
    end

    def other_alert_data
      {
        # Conditional Registration Order - unacceptable professional conduct
        "alerts" => [{ "alertType" => { "alertCategory" => { "alertCategoryId" => TRS::Teacher::UNACCEPTABLE_CONDUCT_CATEGORY_ID } } }]
      }
    end

    def induction_data(trn, induction_status_override)
      return { "induction" => { "status" => induction_status_override } } if induction_status_override

      if (induction = @store.induction_for(trn))
        { "induction" => induction.slice("status", "startDate", "completedDate") }
      else
        {
          "induction" => {
            "status" => "InProgress",
            "startDate" => 2.years.ago.to_date.to_s,
            "completedDate" => 1.year.ago.to_date.to_s
          }
        }
      end
    end

    def itt_data(has_itt)
      if has_itt
        {

          "routesToProfessionalStatuses" => [
            {
              "routeToProfessionalStatusType" => {
                "professionalStatusType" => "QualifiedTeacherStatus"
              },
              "status" => "Holds",
              "holdsFrom" => "2022-01-01",
              "trainingStartDate" => "2020-12-31",
              "trainingEndDate" => "2021-04-05",
              "trainingProvider" => {
                "name" => "Example Provider Ltd."
              }
            }
          ]
        }

      else
        { "routesToProfessionalStatuses" => [] }
      end
    end
  end
end
