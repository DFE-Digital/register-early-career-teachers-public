shared_examples "a N+1 queries free endpoint" do |request_method|
  let(:parameters) { defined?(params) ? params : {} }

  it "does not introduce N+1 queries" do
    # Preload the path to ensure N+1 queries are only detected during the API
    # request and not during the path resolution (which calls factories with N+1s).
    resolved_path = path

    expect {
      Prosopite.scan do
        send(request_method, resolved_path, headers: api_headers, params: parameters)
      end
    }.not_to raise_error
  end
end
