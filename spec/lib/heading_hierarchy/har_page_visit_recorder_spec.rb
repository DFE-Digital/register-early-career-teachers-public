RSpec.describe HeadingHierarchy::HARPageVisitRecorder do
  let(:tracing) { instance_double(Playwright::Tracing) }
  let(:context) { instance_double(Playwright::BrowserContext, tracing:) }
  let(:page) { instance_double(Playwright::Page, context:) }
  let(:recorder) { described_class.new(page, base_url: "http://example.test") }
  let(:har_paths) { [] }

  before do
    allow(tracing).to receive(:start_har) do |path|
      har_paths << path
    end
    allow(tracing).to receive(:stop_har) do
      File.write(har_paths.last, JSON.generate({ "log" => { "entries" => [] } }))
    end
  end

  it "records same origin non asset responses with their content embedded" do
    recorder.start

    expect(tracing).to have_received(:start_har).with(
      har_paths.last,
      content: "embed",
      mode: "minimal",
      urlFilter: %r{^#{Regexp.escape('http://example.test')}/(?!assets/)}
    )
  ensure
    recorder.stop
  end

  it "stops recording, reads the HAR and removes the temporary file" do
    recorder.start
    expect(File.exist?(har_paths.last)).to be(true)
    expect(recorder.stop).to eq([])
    expect(File.exist?(har_paths.last)).to be(false)
  end

  it "removes the temporary file when stopping the recording fails" do
    recorder.start
    expect(File.exist?(har_paths.last)).to be(true)
    allow(tracing).to receive(:stop_har).and_raise(Playwright::Error.new(message: "Could not stop recording"))

    expect { recorder.stop }.to raise_error(Playwright::Error, "Could not stop recording")
    expect(File.exist?(har_paths.last)).to be(false)
  end
end
