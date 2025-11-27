class API::Teachers::SchoolTransferSerializer < Blueprinter::Base
  class TrainingPeriodSerializer < Blueprinter::Base
    field(:school_urn) do |(data, _options)|
      data[:school].urn
    end
    field(:provider) do |(data, _options)|
      data[:training_period].lead_provider&.name
    end
    field(:date) do |(data, _options)|
      data[:training_period].finished_on&.rfc3339
    end
  end

  class TransferSerializer < Blueprinter::Base
    field(:training_record_id) do |(transfer, teacher, _options)|
      if transfer.for_ect?
        teacher.api_ect_training_record_id
      else
        teacher.api_mentor_training_record_id
      end
    end
    field(:transfer_type) do |(transfer, _teacher, _options)|
      transfer.type
    end
    field(:status) do |(transfer, _teacher, _options)|
      transfer.status
    end

    association :leaving, blueprint: TrainingPeriodSerializer do |(transfer, _teacher, _options)|
      { training_period: transfer.leaving_training_period, school: transfer.leaving_school }
    end
    association :joining, blueprint: TrainingPeriodSerializer do |(transfer, _teacher, _options)|
      if transfer.joining_training_period.present?
        { training_period: transfer.joining_training_period, school: transfer.joining_school }
      end
    end
  end

  class AttributesSerializer < Blueprinter::Base
    exclude :id

    # TODO: use transfer updated at once implemented
    field(:api_updated_at, name: :updated_at)

    association :transfers, blueprint: TransferSerializer do |teacher, options|
      ect_transfers = ::Teachers::SchoolTransfers::History.transfers_for(
        school_periods: teacher.ect_at_school_periods,
        lead_provider_id: options[:lead_provider_id]
      )
      mentor_transfers = ::Teachers::SchoolTransfers::History.transfers_for(
        school_periods: teacher.mentor_at_school_periods,
        lead_provider_id: options[:lead_provider_id]
      )
      (ect_transfers + mentor_transfers)
        .sort_by { it.leaving_training_period.started_on }
        .map { [it, teacher] }
    end
  end

  identifier :api_id, name: :id
  field(:type) { "participant-transfer" }

  association :attributes, blueprint: AttributesSerializer do |teacher|
    teacher
  end
end
