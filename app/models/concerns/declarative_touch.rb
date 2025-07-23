module DeclarativeTouch
  extend ActiveSupport::Concern

  class_methods do
    def touch(target, when_changing: [], on_event: %i[update], timestamp_attribute: :updated_at)
      after_commit(on: on_event) do
        should_touch = when_changing.blank? || when_changing.any? do |attr|
          saved_change_to_attribute?(attr)
        end

        Array.wrap(instance_exec(&target)).map { it.update_column(timestamp_attribute, Time.zone.now) } if should_touch
      end
    end
  end
end
