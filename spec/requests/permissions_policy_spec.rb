describe "The correct permissions_policy is set" do
  it "disables camera, gyroscope, microphone, usb, payment and fullscreen" do
    get("/")

    header = response.headers["feature-policy"]
    expected_permissions = %w[camera gyroscope microphone usb payment fullscreen].map { "#{it} 'none'" }

    expect(expected_permissions).to all(be_in(header))
  end
end
