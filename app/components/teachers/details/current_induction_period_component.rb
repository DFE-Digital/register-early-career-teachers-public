module Teachers::Details
  class CurrentInductionPeriodComponent < ViewComponent::Base
    attr_reader :mode, :teacher, :induction, :enable_release, :enable_edit

    # @param mode [Symbol] either :admin, :appropriate_body, or :school
    # @param teacher [Teacher] the teacher whose induction period is being displayed
    # @param enable_edit [Boolean] display links to edit or delete, path depends on mode
    # @param enable_release [Boolean] display link to release the teacher (only for appropriate body mode)
    def initialize(mode:, teacher:, enable_edit: false, enable_release: false)
      @mode = mode
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

    def title
      current_period.appropriate_body.name
    end

    def actions
      [edit_link, delete_link, release_link].compact
    end

    def release_link
      return unless enable_release
      return if admin_mode? # TODO: Confirm ABs only

      helpers.govuk_link_to('Release', release_induction_period_path, no_visited_state: true)
    end

    def edit_link
      return unless enable_edit

      helpers.govuk_link_to('Edit', edit_induction_period_path, no_visited_state: true)
    end

    def delete_link
      return unless enable_edit && can_delete?

      helpers.govuk_link_to('Delete', confirm_delete_induction_period_path, method: :get, class: 'govuk-link--destructive', no_visited_state: true)
    end

    def release_induction_period_path
      if admin_mode?
        # no-op
      else
        helpers.new_ab_teacher_release_ect_path(teacher)
      end
    end

    def edit_induction_period_path
      if admin_mode?
        helpers.edit_admin_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id)
      else
        helpers.edit_ab_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id)
      end
    end

    def confirm_delete_induction_period_path
      if admin_mode?
        helpers.confirm_delete_admin_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id)
      else
        helpers.confirm_delete_ab_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id)
      end
    end

    def admin_mode?
      mode == :admin
    end

    def can_delete?
      current_period.outcome.blank?
    end

    def start_date
      current_period.started_on.to_fs(:govuk)
    end

    def training_programme
      if Rails.application.config.enable_bulk_claim
        helpers.training_programme_name(current_period.training_programme)
      else
        ::INDUCTION_PROGRAMMES[current_period.induction_programme.to_sym]
      end
    end
  end
end
