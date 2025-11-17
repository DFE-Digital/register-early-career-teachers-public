module Schools
  module Shared
    class MentorAssignmentContext
      def initialize(store:, mentor_at_school_period:, ect_at_school_period:)
        @store = store
        @mentor_at_school_period = mentor_at_school_period
        @ect_at_school_period = ect_at_school_period
      end

      attr_reader :mentor_at_school_period, :ect_at_school_period

      def ect_teacher_full_name
        Teachers::Name.new(@ect_at_school_period.teacher).full_name
      end

      def mentor_teacher_full_name
        Teachers::Name.new(@mentor_at_school_period.teacher).full_name
      end

      def already_active_at_school?
        @mentor_at_school_period.school_id == @ect_at_school_period.school_id
      end

      def eligible_for_funding?
        Teachers::MentorFundingEligibility.new(trn: @mentor_at_school_period.teacher.trn).eligible?
      end

      def user_selected_lead_provider
        id = @store.lead_provider_id
        @user_selected_lead_provider ||= LeadProvider.find_by(id:) if id
      end

      def ect_lead_provider
        @ect_lead_provider ||= ECTAtSchoolPeriods::CurrentTraining.new(@ect_at_school_period)&.lead_provider
      end

      def lead_providers_within_contract_period
        return [] unless contract_period

        @lead_providers_within_contract_period ||= LeadProviders::Active
          .in_contract_period(contract_period)
          .select(:id, :name)
      end

    private

      def contract_period
        ContractPeriod.containing_date(@ect_at_school_period&.started_on&.to_date)
      end
    end
  end
end
