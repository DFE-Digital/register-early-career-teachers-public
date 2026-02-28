module TestGuidance
  class TRSExampleTeacherDetails < ApplicationComponent
    # @return [Array<String>]
    def head
      [
        "Name",
        "TRN",
        "Date of birth",
        "Induction status",
        active_period_with_header,
        "Notes",
        ""
      ]
    end

    # @return [Array<Array>]
    def rows
      teachers.map do |name, trn, dob, ni_number, status, note, *|
        teacher = Teacher.find_by(trn:)

        next if exhausted?(teacher)

        [
          name,
          trn,
          dob,
          status_indicator(status, teacher),
          active_period_with(teacher),
          note.to_s,
          populate_button(trn, dob, ni_number)
        ]
      end
    end

    # @return [Array<Array>]
    def teachers
      CSV.read(file_path, headers: true).map(&:values_at)
    end

    # @return [Pathname]
    def file_path = Rails.application.config.test_guidance_fixtures

    # Once used by RIAB the status changes to "In progress" if active or "Induction paused" once released
    def status_indicator(trs_induction_status, teacher)
      trs_induction_status = teacher&.induction_periods&.any? ? "InProgress" : trs_induction_status
      induction_status = Teachers::InductionStatus.new(trs_induction_status:, teacher:)
      govuk_tag(**induction_status.status_tag_kwargs)
    end

    def populate_button(trn, dob, national_insurance_number)
      govuk_button_link_to("Select", "#",
                           class: "populate-find-ect-form-button",
                           secondary: true,
                           data: {
                             trn:,
                             dob: Date.parse(dob).strftime("%d/%m/%Y"),
                             national_insurance_number:
                           })
    end

    # @return [String]
    def active_period_with_header
      case
      when Current.user.appropriate_body_user? then "Claimed by"
      when Current.user.school_user? then "Registered with"
      else
        "N/A"
      end
    end

    # @param [Teacher, nil]
    # @return [String]
    def active_period_with(teacher, inactive: "-")
      return inactive if teacher.nil?

      case
      when Current.user.appropriate_body_user?
        teacher.ongoing_induction_period&.appropriate_body_period&.name || inactive
      when Current.user.school_user?
        teacher.current_or_next_ect_at_school_period&.school&.gias_school&.name || inactive
      else
        inactive
      end
    end

    # Teacher is not available for further testing and cannot be claimed until TRS is reset
    # @param [Teacher, nil]
    # @return [Boolean]
    def exhausted?(teacher)
      return false if teacher.nil?

      TRS::Teacher::INELIGIBLE_INDUCTION_STATUSES.include?(teacher.trs_induction_status)
    end
  end
end
