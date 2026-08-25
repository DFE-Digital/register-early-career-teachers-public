RSpec.describe HeadingHierarchy::HarPageVisitReader do
  it "returns HTML documents" do
    page_visits = page_visits_from(
      har_entry(url: "http://example.test/ects", content: "<h1>ECTs</h1>")
    )

    expect(page_visits).to contain_exactly(
      HeadingHierarchy::PageVisit.new(url: "http://example.test/ects", content: "<h1>ECTs</h1>")
    )
  end

  it "does not return HTML responses that are not documents" do
    page_visits = page_visits_from(har_entry(resource_type: "xhr"))

    expect(page_visits).to be_empty
  end

  it "does not return non HTML responses" do
    page_visits = page_visits_from(har_entry(mime_type: "text/csv"))

    expect(page_visits).to be_empty
  end

  it "does not return redirects" do
    page_visits = page_visits_from(
      har_entry(status: 302, redirect_url: "http://example.test/ects/redirected")
    )

    expect(page_visits).to be_empty
  end

private

  def page_visits_from(*entries)
    Tempfile.create(["heading-hierarchy", ".har"]) do |file|
      file.write(JSON.generate({ "log" => { "entries" => entries } }))
      file.flush

      described_class.new(file.path).page_visits
    end
  end

  def har_entry(
    resource_type: "document",
    url: "http://example.test/ects",
    status: 200,
    redirect_url: "",
    mime_type: "text/html; charset=utf-8",
    content: "<h1>ECTs</h1>"
  )
    {
      "_resourceType" => resource_type,
      "request" => { "url" => url },
      "response" => {
        "status" => status,
        "redirectURL" => redirect_url,
        "content" => {
          "mimeType" => mime_type,
          "text" => content
        }
      }
    }
  end
end
