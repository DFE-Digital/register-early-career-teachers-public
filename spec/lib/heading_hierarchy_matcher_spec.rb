RSpec.describe "have_valid_heading_hierarchy" do
  let(:page) { instance_double(Playwright::Page, content: html) }

  context "when heading levels increase one level at a time" do
    let(:html) do
      <<~HTML
        <h1>Page title</h1>
        <h2>Section</h2>
        <h3>Subsection</h3>
        <h2>Another section</h2>
      HTML
    end

    it "passes" do
      expect(page).to have_valid_heading_hierarchy
    end
  end

  context "when a level 2 heading appears before the level 1 heading" do
    let(:html) do
      <<~HTML
        <h2>There is a problem</h2>
        <h1>Page title</h1>
      HTML
    end

    it "passes" do
      expect(page).to have_valid_heading_hierarchy
    end
  end

  context "when there is no level 1 heading" do
    let(:html) do
      <<~HTML
        <h3>Subsection</h3>
      HTML
    end

    it "fails" do
      expect { expect(page).to have_valid_heading_hierarchy }
        .to raise_error(RSpec::Expectations::ExpectationNotMetError, /expected one h1, but found 0/)
    end
  end

  context "when there is more than one level 1 heading" do
    let(:html) do
      <<~HTML
        <h1>Page title</h1>
        <h1>Another page title</h1>
      HTML
    end

    it "fails" do
      expect { expect(page).to have_valid_heading_hierarchy }
        .to raise_error(RSpec::Expectations::ExpectationNotMetError, /expected one h1, but found 2/)
    end
  end

  context "when a heading level is skipped" do
    let(:html) do
      <<~HTML
        <h1>Page title</h1>
        <h3 class="govuk-visually-hidden">Subsection</h3>
      HTML
    end

    it "fails with details of the headings either side of the skipped level" do
      expect { expect(page).to have_valid_heading_hierarchy }
        .to raise_error(
          RSpec::Expectations::ExpectationNotMetError,
          /h1 "Page title" was followed by h3 "Subsection"/
        )
    end
  end
end
