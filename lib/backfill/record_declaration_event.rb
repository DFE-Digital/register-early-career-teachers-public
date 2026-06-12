module Backfill
  class RecordDeclarationEvent
    VALID_STATUSES = %i[paid clawed_back].freeze

    attr_reader :declaration, :status, :statement

    def initialize(declaration:, status:, statement:)
      @declaration = declaration
      @status = status
      @statement = statement

      validate_status
    end

    def process
      return false if event_exists?

      Event.create!(
        event_type:,
        heading:,
        happened_at:,
        declaration:,
        teacher:,
        training_period: declaration.training_period,
        author_name: "System",
        author_type: "system"
      )

      true
    end

  private

    def validate_status
      return if VALID_STATUSES.include?(status)

      raise ArgumentError, "Unknown declaration event status: #{status.inspect}"
    end

    def heading
      "#{teacher_name}'s #{declaration.declaration_type} declaration was #{formatted_status}"
    end

    def event_exists?
      declaration.events.exists?(event_type:)
    end

    def event_type
      "teacher_declaration_#{status}"
    end

    def happened_at
      statement.payment_date
    end

    def formatted_status
      status.to_s.humanize.downcase
    end

    def teacher_name
      Teachers::Name.new(teacher).full_name
    end

    def teacher
      @teacher ||= declaration.teacher
    end
  end
end
