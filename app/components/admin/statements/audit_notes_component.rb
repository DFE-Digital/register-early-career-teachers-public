module Admin
  module Statements
    class AuditNotesComponent < ApplicationComponent
      attr_reader :statement

      def initialize(statement:)
        @statement = statement
      end

      def render? = audit_notes.any?

      def audit_notes
        @audit_notes ||= statement.audit_notes.order(created_at: :asc)
      end

      def timestamp(audit_note)
        tag.time(audit_note.created_at.to_fs(:govuk), datetime: audit_note.created_at.to_fs(:iso8601))
      end
    end
  end
end
