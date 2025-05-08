module API
  class ParticipantSerializer < Blueprinter::Base
    class AttributesSerializer < Blueprinter::Base
      exclude :id

      field(:full_name) { |p, _| [p.trainee.teacher.trs_first_name, p.trainee.teacher.trs_last_name].join(' ') }
      field(:trn) { |p, _| p.trainee.teacher.trn }

      field(:ecf_enrolments) do |object, options|
        object.trainee.training_periods.map do |training_period|
          next unless training_period.lead_provider == options[:lead_provider]

          {
            training_record_id: training_period.id,
            email: training_period.trainee.email,
            mentor_id: training_period.for_ect? ? training_period.trainee&.mentors&.map(&:id) : nil,
            school_urn: training_period.school_partnership&.school&.urn,
            participant_type: training_period.for_ect? ? :ect : :mentor,
            cohort: training_period.school_partnership&.registration_period&.year.to_s,
            training_status: training_period.trainee.teacher.trs_induction_status,
            participant_status: nil,
            teacher_reference_number_validated: nil,
            eligible_for_funding: nil,
            pupil_premium_uplift: nil,
            sparsity_uplift: nil,
            schedule_identifier: nil,
            delivery_partner_id: training_period.delivery_partner&.id,
            withdrawal: [],
            deferral: [],
            created_at: training_period.created_at.rfc3339,
            induction_end_date: training_period.finished_on&.strftime("%Y-%m-%d"),
            mentor_funding_end_date: nil,
            cohort_changed_after_payments_frozen: nil,
            mentor_ineligible_for_funding_reason: training_period.for_mentor? ? training_period.trainee.teacher.mentor_became_ineligible_for_funding_reason : nil,
          }
        end
      end

      field :created_at
      field :updated_at
    end

    identifier :id
    field(:type) { "participant" }

    association :attributes, blueprint: AttributesSerializer do |participant|
      participant
    end
  end
end
