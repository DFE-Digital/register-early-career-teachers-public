module Teachers
  class RecordOutcomeComponent < ViewComponent::Base
    include Rails.application.routes.url_helpers

    attr_reader :teacher, :pending_induction_submission, :mode, :outcome_type, :is_admin, :appropriate_body

    def initialize(teacher:, pending_induction_submission:, mode:, outcome_type:, appropriate_body: nil)
      @teacher = teacher
      @pending_induction_submission = pending_induction_submission
      @mode = mode
      @outcome_type = outcome_type
      @is_admin = mode == :admin
      @appropriate_body = appropriate_body
    end

    def title
      "Record #{outcome_text} outcome for #{teacher_full_name}"
    end

    def backlink_href
      if is_admin
        admin_teacher_path(teacher)
      else
        ab_teacher_path(teacher)
      end
    end

    def form_url
      if is_admin
        if outcome_type == :passed
          admin_teacher_record_passed_outcome_path(teacher)
        else
          admin_teacher_record_failed_outcome_path(teacher)
        end
      elsif outcome_type == :passed
        ab_teacher_record_passed_outcome_path(teacher)
      else
        ab_teacher_record_failed_outcome_path(teacher)
      end
    end

    def submit_text
      "Record #{outcome_verb} outcome for #{teacher_full_name}"
    end

    def show_appeal_notice?
      !is_admin && outcome_type == :failed
    end

    def warning?
      outcome_type == :failed
    end

  private

    def teacher_full_name
      ::Teachers::Name.new(teacher).full_name
    end

    def outcome_text
      outcome_type == :passed ? "passed" : "failed"
    end

    def outcome_verb
      outcome_type == :passed ? "pass" : "failing"
    end
  end
end
