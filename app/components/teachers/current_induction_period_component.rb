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

    def actions
      links = []
      links << edit_link if can_edit?
      links << release_link
      links
    end

    def release_link
      helpers.govuk_link_to('Release', helpers.new_ab_teacher_release_ect_path(teacher_trn: teacher.trn), no_visited_state: true)
    end

    def edit_link
      helpers.govuk_link_to('Edit', helpers.edit_admin_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id), no_visited_state: true)
    end

    def can_edit?
      current_period.outcome.blank?
    end

    def started_on
      current_period.started_on.to_fs(:govuk)
    end
  end
end
