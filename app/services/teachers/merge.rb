module Teachers
  class Merge
    class MergeError < StandardError; end

    attr_reader :author, :source, :destination, :event_note, :zendesk_ticket_id

    def initialize(author:, source:, destination:, event_note: nil, zendesk_ticket_id: nil)
      @author = author
      @source = source
      @destination = destination
      @event_note = event_note
      @zendesk_ticket_id = zendesk_ticket_id
    end

    def merge!
      ensure_distinct_teachers

      ActiveRecord::Base.transaction do
        move_school_periods
        move_induction_records
        record_teacher_id_change
        refresh_metadata
        record_merge_events
        anonymise_source
      end

      destination
    end

  private

    def ensure_distinct_teachers
      raise MergeError, "Cannot merge a teacher into itself" if source == destination
    end

    def move_school_periods
      source.ect_at_school_periods.find_each { |period| period.update!(teacher: destination) }
      source.mentor_at_school_periods.find_each { |period| period.update!(teacher: destination) }
    end

    def move_induction_records
      source.induction_periods.find_each { |period| period.update!(teacher: destination) }
      source.induction_extensions.find_each { |extension| extension.update!(teacher: destination) }
    end

    def record_teacher_id_change
      TeacherIdChange.create!(
        teacher: destination,
        api_from_teacher_id: source.api_id,
        api_to_teacher_id: destination.api_id
      )
    end

    # The declarative refresh hook only re-points the destination's metadata on
    # reassignment, so refresh the destination explicitly and tear down the
    # stale source rows so their latest_*_training_period_id FKs don't dangle
    def refresh_metadata
      source.lead_provider_metadata.destroy_all
      Metadata::Manager.new.refresh_metadata!([destination])
    end

    def record_merge_events
      Events::Record.record_teacher_merged_events!(author:, source:, destination:, body: event_note, zendesk_ticket_id:)
    end

    def anonymise_source
      Teachers::Anonymise.new(teacher: source.reload, reason: :teacher_record_merged).anonymise!
    end
  end
end
