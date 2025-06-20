RSpec.describe ParityCheck::RequestBenchmark do
  it "attaches the request duration in milliseconds to the response env" do
    allow(Process).to receive(:clock_gettime).and_return(1.0, 1.25)

    connection = Faraday::Connection.new { it.use described_class }
    url = "http://example.com"
    stub_request(:get, url).to_return(status: 200, body: "OK")
    response = connection.get(url)

    expect(response.env[:request_duration_ms].to_i).to eq(250)
  end
end
