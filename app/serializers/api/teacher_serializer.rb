class API::TeacherSerializer < Blueprinter::Base
  class AttributesSerializer < Blueprinter::Base
    class TeacherIdChangeSerializer < Blueprinter::Base
      field :api_from_teacher_id, name: :from_participant_id
      field :api_to_teacher_id, name: :to_participant_id
      field :created_at, name: :changed_at
    end

    class WithdrawalAndDeferralSerializer < Blueprinter::Base
      field(:reason) do |data|
        data[:reason]
      end
      field(:date) do |data|
        data[:date]
      end
    end

    class TrainingPeriodSerializer < Blueprinter::Base
      field(:training_record_id) do |(training_period, teacher, _)|
        if training_period.for_ect?
          teacher.api_ect_training_record_id
        else
          teacher.api_mentor_training_record_id
        end
      end
      field(:email) { |(training_period, _, _)| training_period.email }
      field(:mentor_id) do |(training_period, _, metadata)|
        metadata.api_mentor_id if training_period.for_ect?
      end
      field(:school_urn) { |(training_period, _, _)| training_period.school_partnership.school.urn.to_s }
      field(:participant_type) { |(training_period, _, _)| training_period.for_ect? ? "ect" : "mentor" }
      field(:cohort) do |(training_period, _, metadata)|
        if training_period.for_ect?
          metadata.latest_ect_contract_period_year.to_s
        else
          metadata.latest_mentor_contract_period_year.to_s
        end
      end
      field(:training_status) { |(training_period, _, _)| API::TrainingPeriods::TrainingStatus.new(training_period:).status }
      field(:participant_status) { |(training_period, teacher, _)| API::TrainingPeriods::TeacherStatus.new(latest_training_period: training_period, teacher:).status }
      field(:eligible_for_funding) do |(training_period, teacher, _)|
        if training_period.for_ect?
          teacher.ect_first_became_eligible_for_training_at.present?
        else
          teacher.mentor_first_became_eligible_for_training_at.present?
        end
      end
      field(:pupil_premium_uplift) do |(training_period, teacher, _)|
        training_period.for_ect? && teacher.ect_pupil_premium_uplift
      end
      field(:sparsity_uplift) do |(training_period, teacher, _)|
        training_period.for_ect? && teacher.ect_sparsity_uplift
      end
      field(:schedule_identifier) do |(training_period, _, _)|
        training_period.schedule.identifier
      end
      field(:delivery_partner_id) do |(training_period, _, _)|
        training_period
          .school_partnership
          .lead_provider_delivery_partnership
          .delivery_partner
          .api_id
      end
      association :withdrawal, blueprint: WithdrawalAndDeferralSerializer do |(training_period, _, _)|
        training_status = API::TrainingPeriods::TrainingStatus.new(training_period:).status
        { reason: training_period.withdrawal_reason.dasherize, date: training_period.withdrawn_at } if training_status == :withdrawn
      end
      association :deferral, blueprint: WithdrawalAndDeferralSerializer do |(training_period, _, _)|
        training_status = API::TrainingPeriods::TrainingStatus.new(training_period:).status
        { reason: training_period.deferral_reason.dasherize, date: training_period.deferred_at } if training_status == :deferred
      end
      field(:created_at) do |(training_period, teacher, _)|
        earliest_school_period = if training_period.for_ect?
                                   teacher.earliest_ect_at_school_period
                                 else
                                   teacher.earliest_mentor_at_school_period
                                 end

        earliest_school_period.created_at
      end
      field(:induction_end_date) do |(training_period, teacher, _)|
        if training_period.for_ect?
          if teacher.finished_induction_period.present?
            teacher.finished_induction_period.finished_on
          else
            teacher.trs_induction_completed_date
          end
        end
      end
      field(:overall_induction_start_date) do |(training_period, teacher, _)|
        if training_period.for_ect?
          if teacher.started_induction_period.present?
            teacher.started_induction_period.started_on
          else
            teacher.trs_induction_start_date
          end
        end
      end
      field(:mentor_funding_end_date) { |(training_period, teacher, _)| teacher.mentor_became_ineligible_for_funding_on if training_period.for_mentor? }
      field(:cohort_changed_after_payments_frozen) do |(training_period, teacher, _)|
        if training_period.for_ect?
          teacher.ect_payments_frozen_year.present?
        else
          teacher.mentor_payments_frozen_year.present?
        end
      end
      field(:mentor_ineligible_for_funding_reason) { |(training_period, teacher, _)| teacher.mentor_became_ineligible_for_funding_reason if training_period.for_mentor? }
    end

    exclude :id

    field(:full_name) { |teacher| Teachers::Name.new(teacher).full_name }
    field(:trn, name: :teacher_reference_number)
    field(:api_updated_at, name: :updated_at)

    association :ecf_enrolments, blueprint: TrainingPeriodSerializer do |teacher, options|
      metadata = ::API::TeacherSerializer.lead_provider_metadata(teacher:, options:)
      [[metadata.latest_ect_training_period, teacher, metadata], [metadata.latest_mentor_training_period, teacher, metadata]].reject { |period, _| period.nil? }
    end

    association :teacher_id_changes, blueprint: TeacherIdChangeSerializer, name: :participant_id_changes
  end

  identifier :api_id, name: :id
  field(:type) { "participant" }

  association :attributes, blueprint: AttributesSerializer do |teacher|
    teacher
  end

  class << self
    def lead_provider_metadata(teacher:, options:)
      teacher.lead_provider_metadata.select { it.lead_provider_id == options[:lead_provider_id] }.sole
    end
  end
end
