RSpec.shared_context 'fake trs api client' do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new)
  end
end

RSpec.shared_context 'fake trs api client that finds nothing' do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new(raise_not_found: true))
  end
end

RSpec.shared_context 'fake trs api client deactivated teacher' do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new(raise_deactivated: true))
  end
end

RSpec.shared_context 'fake trs api client returns 200 then 400' do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::FakeAPIClient.new,
      TRS::FakeAPIClient.new(raise_not_found: true)
    )
  end
end

RSpec.shared_context 'fake trs api client that finds teacher without QTS' do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new(include_qts: false))
  end
end

RSpec.shared_context 'fake trs api client that finds teacher prohibited from teaching' do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new(prohibited_from_teaching: true))
  end
end

RSpec.shared_context 'fake trs api client that finds teacher with specific induction status' do |status|
  before do
    allow(TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new(induction_status: status))
  end
end

RSpec.shared_context 'fake trs api client that finds teacher that has passed their induction' do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new(induction_status: 'Passed'))
  end
end

RSpec.shared_context 'fake trs api client that finds teacher that has failed their induction' do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new(induction_status: 'Failed'))
  end
end

RSpec.shared_context 'fake trs api client that finds teacher that is exempt from induction' do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(TRS::FakeAPIClient.new(induction_status: 'Exempt'))
  end
end

RSpec.shared_context 'fake trs api returns a teacher and then a teacher that has completed their induction' do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::FakeAPIClient.new,
      TRS::FakeAPIClient.new(induction_status: 'Passed')
    )
  end
end

RSpec.shared_context 'fake trs api returns a teacher and then a teacher that has failed their induction' do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::FakeAPIClient.new,
      TRS::FakeAPIClient.new(induction_status: 'Failed')
    )
  end
end

RSpec.shared_context 'fake trs api returns a teacher and then a teacher that is exempt from induction' do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::FakeAPIClient.new,
      TRS::FakeAPIClient.new(induction_status: 'Exempt')
    )
  end
end

RSpec.shared_context 'fake trs api returns 2 random teachers' do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::FakeAPIClient.new(random_names: true),
      TRS::FakeAPIClient.new(random_names: true)
    )
  end
end
