describe TRS::FakeAPIClient do
  it 'fails when used in production' do
    allow(Rails.env).to receive(:production?).and_return(true)

    expect { TRS::FakeAPIClient.new }.to raise_error(TRS::FakeAPIClient::FakeAPIClientUsedInProduction)
  end
end
