module Teachers::Details
  class CurrentInductionPeriodComponent < ViewComponent::Base
    attr_reader :mode, :teacher, :induction, :enable_release, :enable_edit, :enable_delete

    # @param mode [Symbol] either :admin, :appropriate_body, or :school
    # @param teacher [Teacher] the teacher whose induction period is being displayed
    # @param enable_edit [Boolean] display links to edit path depends on mode
    # @param enable_delete [Boolean] display links to delete path depends on mode (only for admin mode)
    # @param enable_release [Boolean] display link to release the teacher (only for appropriate body mode)
    def initialize(mode:, teacher:, enable_edit: false, enable_delete: false, enable_release: false)
      @mode = mode
      @teacher = teacher
      @induction = Teachers::Induction.new(teacher)
      @enable_edit = enable_edit
      @enable_delete = enable_delete
      @enable_release = enable_release
    end

    # @return [Boolean]
    def render?
      current_period.present?
    end

  private

    alias_method :enable_delete?, :enable_delete
    alias_method :enable_edit?, :enable_edit
    alias_method :enable_release?, :enable_release

    delegate :govuk_link_to, :training_programme_name, to: :helpers

    # @return [InductionPeriod, nil]
    def current_period
      @current_period ||= induction.current_induction_period
    end

    # @return [String]
    def title
      current_period.appropriate_body.name
    end

    # @return [Array<String>]
    def actions
      [edit_link, delete_link, release_link].compact
    end

    # @return [String, nil] appropriate bodies only
    def release_link
      return unless enable_release?
      return if admin_mode?

      govuk_link_to('Release', new_ab_teacher_release_ect_path(teacher), no_visited_state: true)
    end

    # @return [String, nil]
    def edit_link
      return unless enable_edit?

      govuk_link_to('Edit', edit_path, no_visited_state: true)
    end

    # @return [String]
    def edit_path
      if admin_mode?
        edit_admin_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id)
      else
        edit_ab_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id)
      end
    end

    # @return [String, nil] admins only
    def delete_link
      return unless enable_delete? && current_period.outcome.blank?
      return unless admin_mode?

      delete_path = confirm_delete_admin_teacher_induction_period_path(teacher_id: teacher.id, id: current_period.id)
      govuk_link_to('Delete', delete_path, method: :get, class: 'govuk-link--destructive', no_visited_state: true)
    end

    # @return [Boolean]
    def admin_mode?
      mode == :admin
    end

    # @return [String]
    def start_date
      current_period.started_on.to_fs(:govuk)
    end

    # @return [String]
    def training_programme
      if Rails.application.config.enable_bulk_claim
        training_programme_name(current_period.training_programme)
      else
        ::INDUCTION_PROGRAMMES[current_period.induction_programme.to_sym]
      end
    end
  end
end
