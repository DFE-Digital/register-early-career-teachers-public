module API
  class ParticipantSerializer < Blueprinter::Base
    identifier :ecf_user_id, name: :id
    field(:type) { "participant" }

    class AttributesSerializer < Blueprinter::Base
      exclude :id

      view :v3 do
        field(:full_name) { |t, _| Teachers::Name.new(t).full_name }
        field(:trn) { |t, _| t.trn }

        field(:ecf_enrolments) do |teacher, _options|
          (teacher.ect_at_school_periods + teacher.mentor_at_school_periods).map do |school_period|
            # Better using uuids instead as we don't know whether latest_training_period is an id from ect_at_school_periods or mentor_at_school_periods
            training_period = school_period.training_periods.find { |training_period| teacher.latest_training_period.include?(training_period.id) }

            next if training_period.blank?

            {
              training_record_id: school_period.id,
              email: school_period.email,
              mentor_id: training_period.for_ect? ? school_period&.mentors&.map(&:id) : nil,
              school_urn: training_period.school_partnership&.school&.urn,
              participant_type: training_period.for_ect? ? :ect : :mentor,
              cohort: training_period.school_partnership&.registration_period&.year.to_s,
              training_status: nil,
              participant_status: teacher.trs_induction_status,
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
              mentor_ineligible_for_funding_reason: training_period.for_mentor? ? teacher.mentor_became_ineligible_for_funding_reason : nil,
            }
          end
        end

        field :created_at
        field :updated_at
      end
    end

    association :attributes, blueprint: AttributesSerializer do |participant|
      participant
    end

    %i[v1 v2 v3].each do |version|
      view version do
        association :attributes, blueprint: AttributesSerializer, view: version do |participant|
          participant
        end
      end
    end
  end
end
