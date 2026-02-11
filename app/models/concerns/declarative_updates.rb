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

        should_touch = destroyed? || when_changing.blank? || when_changing.any? do |attr|
          saved_change_to_attribute?(attr)
        end

        Metadata::Manager.new.refresh_metadata!(instance_exec(&target)) if should_touch
      end
    end

    def touch(target, when_changing: [], on_event: %i[update], timestamp_attribute: :updated_at, if: nil)
      condition = binding.local_variable_get(:if)

      after_commit(on: on_event) do
        next if DeclarativeUpdates.skip?(:touch)

        should_touch_based_on_changes = destroyed? || when_changing.blank? || when_changing.any? do |attr|
          saved_change_to_attribute?(attr)
        end

        should_touch_based_on_condition = condition.nil? || evaluate_condition(condition)

        should_touch = should_touch_based_on_changes && should_touch_based_on_condition

        next unless should_touch

        evaluated_target = instance_exec(&target)

        next unless evaluated_target

        if evaluated_target.respond_to?(:update_all)
          evaluated_target.update_all(timestamp_attribute => Time.zone.now)
        else
          evaluated_target.update_column(timestamp_attribute, Time.zone.now)
        end
      end
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

private

  def evaluate_condition(condition)
    case condition
    when Symbol, String
      send(condition)
    when Proc
      instance_exec(&condition)
    else
      condition
    end
  end
end
