module Schools
  module ECTs
    module ChangeMentorWizard
      class CheckAnswersStep < Step
        def previous_step
          return :edit unless mentor_eligible_for_training?
          return :training if store.accepting_current_lead_provider

          :lead_provider
        end

        def next_step = :confirmation

        def current_mentor_name = name_for(current_mentor_at_school_period.teacher)
        def new_mentor_name = name_for(selected_mentor_at_school_period.teacher)

        def save!
          ECTAtSchoolPeriods::SwitchMentor.switch(
            ect_at_school_period,
            to: selected_mentor_at_school_period,
            author:,
            lead_provider: selected_lead_provider
          )

          true
        end

      private

        def mentor_eligible_for_training?
          ::MentorAtSchoolPeriods::Eligibility.for_first_provider_led_training?(
            ect_at_school_period:,
            mentor_at_school_period: selected_mentor_at_school_period
          )
        end

        def current_mentor_at_school_period
          ect_at_school_period.current_or_next_mentorship_period.mentor
        end

        def selected_mentor_at_school_period
          ect_at_school_period
            .school
            .mentor_at_school_periods
            .find(store.mentor_at_school_period_id)
        end

        def selected_lead_provider
          @selected_lead_provider ||= if store.accepting_current_lead_provider
                                        lead_provider_for_ect_at_school_period
                                      else
                                        LeadProvider.find_by(id: store.lead_provider_id)
                                      end
        end

        def lead_provider_for_ect_at_school_period
          @lead_provider_for_ect_at_school_period ||= ECTAtSchoolPeriods::CurrentTraining
            .new(ect_at_school_period)
            .lead_provider_via_school_partnership_or_eoi
        end
      end
    end
  end
end
