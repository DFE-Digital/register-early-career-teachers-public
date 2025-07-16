describe API::ReleaseNote do
  describe "initialization" do
    subject(:release_note) { API::ReleaseNote.new(title:, date:, body:, tags:) }

    let(:title) { "A title" }
    let(:date) { Date.new(2024, 1, 1) }
    let(:body) { "Some body text" }
    let(:tags) { ["#bug-fix", "#new-feature"] }

    it "is initialized with title, date, body and tags" do
      expect(release_note.title).to eql(title)
      expect(release_note.date).to eql(date.to_formatted_s(:govuk))
      expect(release_note.body).to eql(%(<p class="govuk-body-m">#{body}</p>))
      expect(release_note.tags).to eql(tags)
    end

    context "when the body contains markdown" do
      let(:body) { "Some **body** text" }

      it "the body contains rendered markdown" do
        expected_body_with_markdown = %(<p class="govuk-body-m">Some <strong>body</strong> text</p>)
        expect(release_note.body).to eql(expected_body_with_markdown)
      end
    end
  end
end
