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
      public_send("#{user_type}_teacher_path", teacher)
    end

    def form_url
      public_send("#{user_type}_teacher_record_#{outcome_type}_outcome_path", teacher)
    end

    def submit_text
      "Record #{outcome_verb} outcome for #{teacher_full_name}"
    end

    def show_appeal_notice?
      !is_admin && warning?
    end

    def warning?
      outcome_type == :failed
    end

  private

    def user_type
      is_admin ? :admin : :ab
    end

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
