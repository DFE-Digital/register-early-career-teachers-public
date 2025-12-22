module Teachers
  class ConfirmOutcomeComponent < ApplicationComponent
    attr_reader :service, :teacher_full_name

    delegate :teacher,
             to: :service

    def initialize(service:)
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
  end
end
