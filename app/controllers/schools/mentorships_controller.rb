module Schools
  class MentorshipsController < SchoolsController
    before_action :set_ect
    before_action :register_mentor, only: :create, if: :register_new_mentor?

    def new
      @mentor_form = AssignMentorForm.new(ect:)

      assign_previously_chosen_mentor_id
    end

    def create
      @mentor_form = AssignMentorForm.new(ect:, mentor_id:)

      if mentor_at_school_period.present? && provider_led_and_eligible_for_funding?
        kickoff_assign_existing_wizard!(ect_id: ect.id, mentor_period_id: mentor_at_school_period.id)
        return redirect_to schools_assign_existing_mentor_wizard_review_mentor_eligibility_path
      end

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

    def assign_previously_chosen_mentor_id
      return if params[:preselect].blank?

      @mentor_form.mentor_id = params[:preselect]
    end

    def mentor_at_school_period
      @mentor_at_school_period ||= school.mentor_at_school_periods.find_by(id: mentor_id)
    end

    def provider_led_and_eligible_for_funding?
      ect&.provider_led? &&
        mentor_at_school_period&.teacher &&
        Teachers::MentorFundingEligibility
          .new(trn: mentor_at_school_period.teacher.trn)
          .eligible?
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

    def store
      @store ||= SessionRepository.new(session:, form_key: :assign_existing_mentor_wizard)
    end

    def kickoff_assign_existing_wizard!(ect_id:, mentor_period_id:)
      store.update!(ect_id:, mentor_period_id:)
    end
  end
end
