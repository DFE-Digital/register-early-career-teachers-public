RSpec.describe API::TimeTravelerMiddleware, type: :request do
  subject do
    response = request.get("/", headers)
    Time.zone.parse(response.body)
  end

  let(:app) { proc { [200, {}, Time.zone.now.to_s] } }
  let(:middleware) { described_class.new(app) }
  let(:request) { Rack::MockRequest.new(middleware) }
  let(:headers) { {} }

  it { is_expected.to be_within(1.minute).of(Time.zone.now) }

  context "when the HTTP_X_WITH_SERVER_DATE header is present" do
    let(:travelled_time) { Time.zone.local(2021, 8, 8, 10, 10, 0) }
    let(:headers) { {"HTTP_X_WITH_SERVER_DATE" => travelled_time.iso8601} }

    it { is_expected.to be_within(1.minute).of(travelled_time) }
  end
end
