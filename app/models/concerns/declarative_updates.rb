module DeclarativeUpdates
  extend ActiveSupport::Concern

  SKIP_THREAD_KEY = {
    metadata: :skip_metadata_updates,
    touch: :skip_declarative_touch_updates
  }.freeze

  class_methods do
    def refresh_metadata(target, when_changing: [], on_event: %i[update])
      after_commit(on: on_event) do
        next if DeclarativeUpdates.skip?(:metadata)

        evaluated_target = instance_exec(&target)
        next unless evaluated_target
        next unless evaluated_target.class.exists?(evaluated_target.id)

        should_touch = destroyed? || when_changing.blank? || when_changing.any? do |attr|
          saved_change_to_attribute?(attr)
        end

        next unless should_touch

        Metadata::Manager.new.refresh_metadata!(evaluated_target)
      end
    end

    def touch(target, when_changing: [], on_event: %i[update], timestamp_attribute: :updated_at)
      events = Array(on_event)
      options = { target:, when_changing:, timestamp_attribute: }

      after_create { DeclarativeUpdates.perform_touch(self, **options) } if events.include?(:create)
      after_update { DeclarativeUpdates.perform_touch(self, **options) } if events.include?(:update)
      after_destroy { DeclarativeUpdates.perform_touch(self, **options) } if events.include?(:destroy)
    end
  end

  def self.perform_touch(record, target:, when_changing:, timestamp_attribute:)
    return if skip?(:touch)

    should_touch_based_on_changes = record.destroyed? || when_changing.blank? || when_changing.any? do |attr|
      record.saved_change_to_attribute?(attr)
    end

    return unless should_touch_based_on_changes

    evaluated_target = record.instance_exec(&target)

    return unless evaluated_target

    if evaluated_target.respond_to?(:update_all)
      evaluated_target.update_all(timestamp_attribute => Time.zone.now)
    else
      evaluated_target.update_column(timestamp_attribute, Time.zone.now)
    end
  end

  def self.skip(*types)
    keys = (types.presence || SKIP_THREAD_KEY.keys).map do |type|
      SKIP_THREAD_KEY.fetch(type) { raise ArgumentError, "Unknown declarative type: #{type}" }
    end

    prev = keys.index_with { |key| Thread.current[key] }
    keys.each { |key| Thread.current[key] = true }

    yield
  ensure
    prev.each { |key, val| Thread.current[key] = val }
  end

  def self.skip?(type)
    key = SKIP_THREAD_KEY.fetch(type) { raise ArgumentError, "Unknown declarative type: #{type}" }

    Thread.current[key]
  end
end
