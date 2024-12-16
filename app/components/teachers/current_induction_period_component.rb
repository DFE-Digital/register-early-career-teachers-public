module Teachers
  class CurrentInductionPeriodComponent < ViewComponent::Base
    attr_reader :teacher, :induction

    def initialize(teacher:)
      @teacher = teacher
      @induction = Teachers::Induction.new(teacher)
    end

    def render?
      current_period.present?
    end

  private

    def current_period
      @current_period ||= induction.current_induction_period
    end

    def release_link
      helpers.govuk_link_to('Release', helpers.new_ab_teacher_release_ect_path(teacher_trn: teacher.trn), no_visited_state: true)
    end
  end
end
