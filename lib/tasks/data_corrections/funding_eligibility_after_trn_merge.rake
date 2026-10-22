namespace :data_corrections do
  desc "Correct funding eligibility for teachers who have had a TRN merge"

  task set_funding_eligibility_after_trn_merge: :environment do
    author = Events::SystemAuthor.new
    affected_teachers = Teacher
      .joins(:events)
      .where(events: { event_type: :teacher_merged })
      .distinct

    affected_teachers.each do |teacher|
      ActiveRecord::Base.transaction do
        # If merge has removed the ECT's eligibility data, set it based on the TRS induction start date, or registration date
        if teacher.ect_first_became_eligible_for_training_at.nil?
          if teacher.trs_induction_start_date.present?
            teacher.ect_first_became_eligible_for_training_at = teacher.trs_induction_start_date
          elsif teacher.trs_induction_status == "InProgress"
            ect_registered_on = teacher.ect_at_school_periods.earliest_first.first&.started_on

            teacher.ect_first_became_eligible_for_training_at = ect_registered_on
          end
        end

        # If merge has removed the mentor's eligibility data, set it based on the earliest training period start date
        if teacher.mentor_first_became_eligible_for_training_at.nil? && teacher.mentor_training_periods.any?
          training_started_on = teacher.mentor_training_periods.earliest_first.first.started_on

          teacher.mentor_first_became_eligible_for_training_at = training_started_on
        end

        # If the ECT is exempt and has not been marked as ineligible for funding, set the ineligible date to today
        if teacher.trs_induction_status == "Exempt" && teacher.ect_became_ineligible_for_funding_on.nil?
          teacher.ect_became_ineligible_for_funding_on = Date.current
        end

        # If the mentor has a completed declaration, mark them as ineligible for funding
        completed_mentor_declarations = teacher.mentor_declarations.declaration_type_completed
        earliest_date_training_completed = completed_mentor_declarations
          .map { |declaration| declaration.training_period.finished_on }
          .compact
          .min

        if earliest_date_training_completed && teacher.mentor_became_ineligible_for_funding_on.nil?
          teacher.mentor_became_ineligible_for_funding_on = earliest_date_training_completed
          teacher.mentor_became_ineligible_for_funding_reason = "completed_declaration_received"
        end

        teacher.save!

        # Mark submitted declarations as eligible for eligible ECTs
        # Submitted declarations have payment_status "no_payment"
        if teacher.ect_first_became_eligible_for_training_at.present?
          declarations = teacher.ect_declarations.payment_status_no_payment

          Declarations::Actions::MarkDeclarationsEligible.new(declarations:, author:).mark
        end

        if teacher.mentor_first_became_eligible_for_training_at.present?
          declarations = teacher.mentor_declarations.payment_status_no_payment

          Declarations::Actions::MarkDeclarationsEligible.new(declarations:, author:).mark
        end
      end
    end
  end
end
