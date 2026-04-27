RSpec.describe "Release Notes" do
  describe "GET /api/guidance/release-notes" do
    it "renders valid notes" do
      expect { get(api_guidance_release_notes_path) }.not_to raise_error
      expect(response).to be_successful
      expect(response.body).to include("Release notes")
    end
  end

  describe "GET /api/guidance/release-notes/:slug" do
    let(:notes_file_path) { Rails.root.join("app/views/api/release_notes/release_notes.yml") }
    let(:notes_data) { YAML.load_file(notes_file_path, permitted_classes: [Date]) }
    let(:api_release_notes) do
      notes_data.map do
        API::ReleaseNote.new(**it.symbolize_keys)
      end
    end

    context "with valid slug" do
      let(:note) { api_release_notes.sample }

      it "renders the note" do
        get(api_guidance_release_note_path(note.slug))

        expect(response).to be_successful
        expect(response.body).to include(note.title)
        expect(response.body).to include(note.body)
        expect(response.body).to include(note.date)
        expect(response.body).to include(note.tags.sample.titleize.humanize)
      end
    end

    context "with unknown slug" do
      it "returns 404" do
        get(api_guidance_release_note_path("non-existent-slug"))

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
