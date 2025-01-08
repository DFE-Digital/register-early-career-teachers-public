module Teachers
  class CurrentInductionPeriodComponent < ViewComponent::Base
    attr_reader :teacher, :induction, :enable_release, :enable_edit

    # FIXME: it's not entirely clear here that enable_edit is for
    #        admin and enable_release for ABs. This could be
    #        reworked so we pass in an array of links and render
    #        whatever's passed in - but that does mean shifting
    #        a bit of logic around (probably to Teachers::Induction)
    def initialize(teacher:, enable_edit: false, enable_release: false)
      @teacher = teacher
      @induction = Teachers::Induction.new(teacher)
      @enable_release = enable_release
      @enable_edit = enable_edit
    end

    def render?
      current_period.present?
    end

  private

    def current_period
      @current_period ||= induction.current_induction_period
    end

    def actions
      [edit_link, release_link].compact
    end

    def release_link
      return unless enable_release

      helpers.govuk_link_to('Release', helpers.new_ab_teacher_release_ect_path(teacher_trn: teacher.trn), no_visited_state: true)
    end

    def edit_link
      return unless enable_edit && can_edit?

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
