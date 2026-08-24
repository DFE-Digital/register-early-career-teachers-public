module Admin::DataFixesWizard
  class PreviewStep < Step
    def previous_step = :csv
    def next_step = :verify

    def save!
      processed_changes = changes.process
      store.processed_changes = processed_changes.presence || nil
    end

    delegate :errors, to: :changes
    delegate :parsed_rows, to: :store
    def error_presenter = ErrorSummaryPresenter

  private

    def changes
      @changes ||= Admin::DataFixes::Changes.new(parsed_rows: store.parsed_rows)
    end

    class ErrorSummaryPresenter
      def initialize(error_messages)
        @error_messages = error_messages
      end

      def formatted_error_messages
        @error_messages.flat_map do |attribute, messages|
          messages.map { |message| [attribute, message] }
        end
      end
    end
  end
end
