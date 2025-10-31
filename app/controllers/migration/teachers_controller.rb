class Migration::TeachersController < ::AdminController
  layout "full"

  def index
    @pagy, teachers = pagy(
      Teachers::Search.new(query_string: params[:q]).search.order(:trs_last_name, :trs_first_name, :id)
    )
    @teachers = Admin::TeacherPresenter.wrap(teachers)
  end

  def show
    @page = params[:page] || 1
    fetch_teacher_data
  end

private

  def fetch_teacher_data
    teacher
    user
    ect_profile
    mentor_profile
    ect_school_periods
    mentor_school_periods
    failures
  end

  def failures
    @failures = @teacher.teacher_migration_failures
  end

  def ect_school_periods
    @ect_periods = Migration::SchoolPeriodPresenter.wrap(
      teacher.ect_at_school_periods.order(:started_on)
    )
  end

  def mentor_school_periods
    @mentor_periods = Migration::SchoolPeriodPresenter.wrap(
      teacher.mentor_at_school_periods.order(:started_on)
    )
  end

  def ect_profile
    @ect_profile ||= find_ect_profile_for_teacher
  end

  def find_ect_profile_for_teacher
    profile = if teacher.api_ect_training_record_id.present?
                Migration::ParticipantProfile.find(teacher.api_ect_training_record_id)
              else
                Migration::TeacherProfile.joins(:participant_profiles).where(trn: teacher.trn).first.participant_profiles.ect.first
              end
    Migration::ParticipantProfilePresenter.new(profile) if profile.present?
  end

  def mentor_profile
    @mentor_profile ||= find_mentor_profile_for_teacher
  end

  def find_mentor_profile_for_teacher
    profile = if teacher.api_mentor_training_record_id.present?
                Migration::ParticipantProfile.find(teacher.api_mentor_training_record_id)
              else
                Migration::TeacherProfile.joins(:participant_profiles).where(trn: teacher.trn).first.participant_profiles.mentor.first
              end
    Migration::ParticipantProfilePresenter.new(profile) if profile.present?
  end

  def make_gantt_chart?
    ect_profile&.induction_records&.any? || mentor_profile&.induction_records&.any?
  end

  def user
    @user ||= Migration::User.find(teacher.api_id)
  end

  def teacher
    @teacher ||= Admin::TeacherPresenter.new(Teacher.find(params[:id]))
  end

  helper_method :make_gantt_chart?
end
