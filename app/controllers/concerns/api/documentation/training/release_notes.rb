module API
  module Documentation
    module Training
      module ReleaseNotes
        extend ActiveSupport::Concern

        included do
          helper_method :release_notes
        end

      private

        def release_notes
          @release_notes ||= YAML.load_file(
            Rails.root.join("app/views/api/documentation/training/release_notes/release_notes.yml"),
            permitted_classes: [Date]
          ).map { API::ReleaseNote.new(**it.symbolize_keys) }
        end
      end
    end
  end
end
