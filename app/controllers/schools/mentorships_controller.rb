module Schools
  class MentorshipsController < SchoolsController
    before_action :set_ect
    before_action :register_mentor, only: :create, if: :register_new_mentor?

    def new
      @mentor_form = AssignMentorForm.new(ect: ect_at_school_period)

      assign_previously_chosen_mentor_id
    end

    def create
      @mentor_form = AssignMentorForm.new(ect: ect_at_school_period, mentor_id:)

      if MentorAtSchoolPeriods::Eligibility.for_first_provider_led_training?(mentor_at_school_period:, ect_at_school_period:)
        kickoff_assign_existing_wizard!(ect_id: ect_at_school_period.id, mentor_period_id: mentor_at_school_period.id)
        return redirect_to schools_assign_existing_mentor_wizard_review_mentor_eligibility_path
      end

      if @mentor_form.save(author: current_user)
        redirect_to confirmation_schools_ect_mentorship_path(@ect_at_school_period)
      else
        render :new
      end
    end

    def confirmation
      @mentor_name = ECTAtSchoolPeriods::Mentorship.new(ect_at_school_period).current_mentor_name
    end

  private

    attr_reader :ect_at_school_period

    def mentor_id
      @mentor_id ||= params.dig(:schools_assign_mentor_form, :mentor_id)
    end

    def assign_previously_chosen_mentor_id
      return if params[:preselect].blank?

      @mentor_form.mentor_id = params[:preselect]
    end

    def mentor_at_school_period
      @mentor_at_school_period ||= school.mentor_at_school_periods.find_by(id: mentor_id)
    end

    def register_mentor
      redirect_to schools_register_mentor_wizard_start_path(ect_id: ect_at_school_period.id)
    end

    def register_new_mentor?
      mentor_id == '0'
    end

    def set_ect
      @ect_at_school_period ||= school.ect_at_school_periods.find_by_id(params[:ect_id])
      @ect_name = Teachers::Name.new(@ect_at_school_period.teacher).full_name if @ect_at_school_period
    end

    def store
      @store ||= SessionRepository.new(session:, form_key: :assign_existing_mentor_wizard)
    end

    def kickoff_assign_existing_wizard!(ect_id:, mentor_period_id:)
      store.update!(ect_id:, mentor_period_id:)
    end
  end
end
