module Schools
  module RegisterMentorWizard
    class RegistrationSession
      class Queries
        def initialize(registration_session:)
          @registration_session = registration_session
        end

        def active_record_at_school
          @active_record_at_school ||= MentorAtSchoolPeriods::Search
            .new
            .mentor_periods(trn: registration_session.trn, urn: registration_session.school_urn)
            .ongoing
            .last
        end

        def school
          @school ||= School.find_by_urn(registration_session.school_urn)
        end

        def lead_provider
          @lead_provider ||= LeadProvider.find(registration_session.lead_provider_id) if registration_session.lead_provider_id
        end

        def latest_registration_choice
          @latest_registration_choice ||= MentorAtSchoolPeriods::LatestRegistrationChoices.new(trn: registration_session.trn)
        end

        def previous_training_period
          latest_registration_choice.training_period
        end

        def lead_providers_within_contract_period
          return [] unless contract_period

          @lead_providers_within_contract_period ||= LeadProviders::Active.in_contract_period(contract_period).select(:id, :name)
        end

        def contract_period
          @contract_period ||= ContractPeriod.containing_date(registration_session.started_on&.to_date || Date.current)
        end

        def mentor_at_school_periods
          @mentor_at_school_periods ||= ::MentorAtSchoolPeriods::Search.new.mentor_periods(trn: registration_session.trn)
        end

        def previous_school_mentor_at_school_periods
          finishes_in_the_future_scope = ::MentorAtSchoolPeriod.finished_on_or_after(registration_session.start_date)
          mentor_at_school_periods.where.not(school:).ongoing.or(finishes_in_the_future_scope)
        end

        def ect
          return if registration_session.store["ect_id"].blank?

          @ect ||= ECTAtSchoolPeriod.find(registration_session.store["ect_id"])
        end

        def ect_training_service
          @ect_training_service ||= ECTAtSchoolPeriods::CurrentTraining.new(ect)
        end

      private

        attr_reader :registration_session
      end
    end
  end
end
