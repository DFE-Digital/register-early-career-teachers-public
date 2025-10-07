class API::TeacherSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    class TeacherIdChangeSerializer < Blueprinter::Base
      field :api_from_teacher_id, name: :from_participant_id
      field :api_to_teacher_id, name: :to_participant_id
      field :created_at, name: :changed_at
    end

    class TrainingPeriodSerializer < Blueprinter::Base
      field(:training_record_id) do |training_period|
        teacher = training_period.trainee.teacher

        if training_period.for_ect?
          teacher.api_ect_training_record_id
        else
          teacher.api_mentor_training_record_id
        end
      end
      field(:email) { |training_period| training_period.trainee.email }
      field(:mentor_id) do |training_period|
        "mentor_api_id" if training_period.for_ect? # TODO: implement when we have metadata for mentor_api_id
      end
      field(:school_urn) { |training_period| training_period.school_partnership.school.urn }
      field(:participant_type) { |training_period| training_period.for_ect? ? "ect" : "mentor" }
      field(:cohort) { |training_period| training_period.school_partnership.contract_period.year }
      field(:training_status) { "active" } # TODO: implement when we have training status service
      field(:participant_status) { "active" } # TODO: implement when we have participant status service
      field(:eligible_for_funding) { true } # TODO: implement when we have eligibility service
      field(:pupil_premium_uplift) do |training_period|
        training_period.for_ect? && training_period.trainee.teacher.ect_pupil_premium_uplift
      end
      field(:sparsity_uplift) do |training_period|
        training_period.for_ect? && training_period.trainee.teacher.ect_sparsity_uplift
      end
      field(:schedule_identifier) { "ecf-extended-september" } # TODO: implement when training periods have a connection to a schedule
      field(:delivery_partner_id) { |training_period| training_period.school_partnership.delivery_partner.api_id }
      field(:withdrawal) { nil } # TODO: implement when we have withdrawal service
      field(:deferral) { nil } # TODO: implement when we have deferral service
      field(:created_at) do |training_period|
        teacher = training_period.trainee.teacher

        earliest_school_period = if training_period.for_ect?
                                   teacher.earliest_ect_at_school_period
                                 else
                                   teacher.earliest_mentor_at_school_period
                                 end

        earliest_school_period.created_at.utc.rfc3339
      end
      field(:induction_end_date) { |training_period| training_period.trainee.teacher.finished_induction_period&.finished_on&.rfc3339 }
      field(:overall_induction_start_date) { |training_period| training_period.trainee.teacher.started_induction_period&.started_on&.rfc3339 }
      field(:mentor_funding_end_date) { |training_period| training_period.trainee.teacher.mentor_became_ineligible_for_funding_on&.rfc3339 if training_period.for_mentor? }
      field(:mentor_ineligible_for_funding_reason) { |training_period| training_period.trainee.teacher.mentor_became_ineligible_for_funding_reason if training_period.for_mentor? }
      field(:cohort_changed_after_payments_frozen) do |training_period|
        teacher = training_period.trainee.teacher

        if training_period.for_ect?
          teacher.ect_payments_frozen_year.present?
        else
          teacher.mentor_payments_frozen_year.present?
        end
      end
    end

    exclude :id

    field(:full_name) { |teacher| Teachers::Name.new(teacher).full_name_in_trs }
    field(:trn, name: :teacher_reference_number) # TODO: ensure we return nil for invalid TRNs
    field :updated_at

    association :ecf_enrolments, blueprint: TrainingPeriodSerializer do |teacher, options|
      metadata = lead_provider_metadata(teacher:, options:)
      [metadata.latest_ect_training_period, metadata.latest_mentor_training_period].compact
    end

    association :teacher_id_changes, blueprint: TeacherIdChangeSerializer, name: :participant_id_changes

    class << self
      def lead_provider_metadata(teacher:, options:)
        teacher.lead_provider_metadata.select { it.lead_provider_id == options[:lead_provider_id] }.sole
      end
    end
  end

  identifier :api_id, name: :id
  field(:type) { "participant" }

  association :attributes, blueprint: AttributesSerializer do |teacher|
    teacher
  end
end
