module DeclarativeMetadata
  extend ActiveSupport::Concern

  class_methods do
    def refresh_metadata(target, when_changing: [], on_event: %i[update])
      after_commit(on: on_event) do
        should_touch = when_changing.blank? || when_changing.any? do |attr|
          saved_change_to_attribute?(attr)
        end

        Metadata::Manager.new.refresh_metadata!(instance_exec(&target)) if should_touch
      end
    end
  end
end
