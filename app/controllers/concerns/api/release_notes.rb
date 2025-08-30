module API
  module ReleaseNotes
    extend ActiveSupport::Concern

    included do
      helper_method :release_notes
    end

  private

    def release_notes
      @release_notes ||= YAML.load_file(
        Rails.root.join('app/views/api/release_notes/release_notes.yml'),
        permitted_classes: [Date]
      ).map.with_index { |note, i| API::ReleaseNote.new(**note.symbolize_keys, latest: i.zero?) }
    end
  end
end
