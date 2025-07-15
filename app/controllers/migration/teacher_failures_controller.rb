class Migration::TeacherFailuresController < ::AdminController
  layout "full"

  def index
    @pagy, teachers = pagy(
      find_matching_failures(params[:err]).order(:trs_last_name, :trs_first_name, :id)
    )
    @teachers = Admin::TeacherPresenter.wrap(teachers)
  end

private

  def find_matching_failures(failure_message)
    scope = ::Teacher.joins(:teacher_migration_failures)
    if failure_message.present?
      tmf = TeacherMigrationFailure.arel_table
      scope = scope.where(tmf[:message].matches("%#{failure_message}%"))
    end
    scope.distinct
  end
end
