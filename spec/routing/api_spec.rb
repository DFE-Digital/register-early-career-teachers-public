describe 'API routes' do
  context 'when enable_api = true' do
    it 'permits access to the API routes' do
      expect(get: '/api/guidance').to route_to(controller: 'api/guidance', action: 'show')
    end
  end

  context 'when enable_api = false' do
    before { allow(Rails.application.config).to receive(:enable_api).and_return(false) }

    it 'prevents access to the API routes' do
      expect(get: '/api/guidance').not_to be_routable
    end
  end
end
