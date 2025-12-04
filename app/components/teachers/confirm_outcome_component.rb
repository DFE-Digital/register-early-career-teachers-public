module Teachers
  class ConfirmOutcomeComponent < ApplicationComponent
    attr_reader :service, :teacher_full_name

    include UserModes
    
    delegate :appropriate_body,
             :teacher,
             :pending_induction_submission,
             :outcome,
             to: :service

    def initialize(mode:, service:)
      @service = service
      @teacher_full_name = ::Teachers::Name.new(teacher).full_name
    end

  private

    def appeal_notice
      "#{teacher_full_name} can appeal this outcome. You must tell them about their right to appeal and the appeal process."
    end

    def confirm_appeal
      "Yes, #{teacher_full_name} has been sent written confirmation of their induction outcome, their right to appeal and the appeal process."
    end

    def failed?
      outcome == :fail
    end
  end
end
