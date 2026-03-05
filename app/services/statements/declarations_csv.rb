require "csv"

module Statements
  class DeclarationsCSV
    Column = Data.define(:header, :value_method)

    COLUMNS = [
      Column.new("Participant ID", :participant_id),
      Column.new("Participant Name", :participant_name),
      Column.new("TRN", :trn),
      Column.new("Type", :participant_type),
      Column.new("Mentor Profile ID", :mentor_profile_id),
      Column.new("Schedule", :schedule_identifier),
      Column.new("Eligible For Funding", :eligible_for_funding),
      Column.new("Eligible For Funding Reason", :eligible_for_funding_reason),
      Column.new("Sparsity Uplift", :sparsity_uplift),
      Column.new("Pupil Premium Uplift", :pupil_premium_uplift),
      Column.new("Sparsity And Pp", :sparsity_and_pp),
      Column.new("Lead Provider Name", :lead_provider_name),
      Column.new("Delivery Partner Name", :delivery_partner_name),
      Column.new("School URN", :school_urn),
      Column.new("School Name", :school_name),
      Column.new("Training Status", :training_status),
      Column.new("Training Status Reason", :training_status_reason),
      Column.new("Declaration ID", :declaration_id),
      Column.new("Declaration Status", :declaration_status),
      Column.new("Declaration Type", :csv_declaration_type),
      Column.new("Declaration Date", :declaration_date),
      Column.new("Declaration Created At", :declaration_created_at),
      Column.new("Evidence Held", :evidence_held),
      Column.new("Statement Name", :statement_name),
      Column.new("Statement ID", :csv_statement_id),
      Column.new("Uplift Payable", :uplift_payable)
    ].freeze

    HEADERS = COLUMNS.map(&:header).freeze

    attr_reader :statement

    def initialize(statement:)
      @statement = statement
    end

    def filename
      [
        statement.lead_provider.name.parameterize,
        Statements::Period.for(statement).parameterize,
        "declarations.csv"
      ].join("-")
    end

    def type
      "text/csv"
    end

    def to_csv
      CSV.generate(headers: HEADERS, write_headers: true) do |csv|
        declarations.each do |declaration|
          csv << CSVSupport::RowSanitizer.sanitize(row_for(declaration))
        end
      end
    end

  private

    def declarations
      @declarations ||= Statements::DeclarationsSearch.new(statement:).declarations
    end

    def row_for(declaration)
      COLUMNS.map { |column| send(column.value_method, declaration) }
    end

    def teacher(declaration)
      declaration.teacher
    end

    def participant_id(declaration)
      teacher(declaration).api_id
    end

    def participant_name(declaration)
      Teachers::Name.new(teacher(declaration)).full_name
    end

    def trn(declaration)
      teacher(declaration).trn
    end

    def participant_type(declaration)
      declaration.for_ect? ? "ect" : "mentor"
    end

    def mentor_profile_id(declaration)
      # "Mentor Profile ID" is the legacy ECF1 name, in RECT this maps to
      # Teacher#api_mentor_training_record_id (not Teacher#api_id).
      return unless declaration.for_ect?

      declaration.mentorship_period&.mentor&.teacher&.api_mentor_training_record_id
    end

    def eligible_for_funding_reason(_declaration)
      # TODO: RECT does not currently persist a dedicated declaration level
      # eligible funding reason for statement exports. The existing declaration
      # serializer also returns nil for this field, so leave it blank until
      # product agrees the source.
      nil
    end

    def schedule_identifier(declaration)
      declaration.training_period.schedule.identifier
    end

    def eligible_for_funding(declaration)
      declaration.training_period.eligible_for_funding?
    end

    def sparsity_uplift(declaration)
      declaration.sparsity_uplift
    end

    def pupil_premium_uplift(declaration)
      declaration.pupil_premium_uplift
    end

    def sparsity_and_pp(declaration)
      declaration.sparsity_uplift && declaration.pupil_premium_uplift
    end

    def lead_provider_name(declaration)
      declaration.training_period.lead_provider.name
    end

    def delivery_partner_name(declaration)
      declaration.delivery_partner_when_created.name
    end

    def school_urn(declaration)
      declaration.training_period.school.urn
    end

    def school_name(declaration)
      declaration.training_period.school.name
    end

    def training_status(declaration)
      training_period_status(declaration.training_period).to_s
    end

    def training_status_reason(declaration)
      training_period = declaration.training_period
      case training_period_status(training_period)
      when :withdrawn
        training_period.withdrawal_reason&.dasherize
      when :deferred
        training_period.deferral_reason&.dasherize
      end
    end

    def declaration_status(declaration)
      status = declaration.overall_status
      # Keep external ECF wording: RECT stores "no_payment", but exports use "submitted".
      status == "no_payment" ? "submitted" : status
    end

    def declaration_id(declaration)
      declaration.api_id
    end

    def csv_declaration_type(declaration)
      declaration.declaration_type
    end

    def declaration_date(declaration)
      declaration.declaration_date.utc.iso8601
    end

    def declaration_created_at(declaration)
      declaration.created_at.utc.iso8601
    end

    def evidence_held(declaration)
      declaration.evidence_type
    end

    def statement_name(_declaration)
      Statements::Period.for(statement)
    end

    def csv_statement_id(_declaration)
      statement.api_id
    end

    def uplift_payable(declaration)
      declaration.uplift_paid?
    end

    def training_period_status(training_period)
      API::TrainingPeriods::TrainingStatus.new(training_period:).status
    end
  end
end
