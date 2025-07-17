RSpec.describe API::Guidance::ReleaseNotes::TagsComponent, type: :component do
  describe "initialization" do
    subject(:component) do
      described_class.new(
        tags:
      )
    end

    let(:tags) { %w[bug-fix new-feature] }

    describe '#initialize' do
      it 'sets it to the injected object if provided' do
        expect(component.tags).to eq(tags)
      end
    end

    describe "#render" do
      let(:expected_output) do
        %(<div class=\"release-notes-tags\">) +
          %(<div class=\"tag-group\">) +
          %(<strong class=\"govuk-tag govuk-tag--green\">New feature</strong>\n) +
          %(<strong class=\"govuk-tag govuk-tag--yellow\">Bug fix</strong></div></div>\n)
      end

      it "renders the correct output" do
        render_inline(component)

        expect(rendered_content).to eql(expected_output)
      end

      context "when a tag is are not mapped" do
        let(:tags) { %w[new-tag] }

        it "raises an error" do
          expect {
            render_inline(component)
          }.to raise_error(described_class::UnknownTagError, "Tag not recognised: new-tag")
        end
      end

      context "when tags is empty" do
        let(:tags) { [] }

        it "renders no tags" do
          render_inline(component)

          expect(rendered_content).to be_empty
        end
      end
    end
  end
end
