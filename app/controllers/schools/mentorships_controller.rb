module Schools
  class MentorshipsController < SchoolsController
    before_action :set_ect
    before_action :register_mentor, only: :create, if: :register_new_mentor?

    def new
      @mentor_form = AssignMentorForm.new(ect:)
    end

    def create
      @mentor_form = AssignMentorForm.new(ect:, mentor_id:)

      if @mentor_form.save(author: current_user)
        redirect_to confirmation_schools_ect_mentorship_path(@ect)
      else
        render :new
      end
    end

    def confirmation
      @mentor_name = ECTAtSchoolPeriods::Mentorship.new(ect).current_mentor_name
    end

  private

    attr_reader :ect

    def mentor_id
      @mentor_id ||= params.dig(:schools_assign_mentor_form, :mentor_id)
    end

    def register_mentor
      redirect_to schools_register_mentor_wizard_start_path(ect_id: ect.id)
    end

    def register_new_mentor?
      mentor_id == '0'
    end

    def set_ect
      @ect ||= school.ect_at_school_periods.find_by_id(params[:ect_id])
      @ect_name = Teachers::Name.new(@ect.teacher).full_name if @ect
    end
  end
end
