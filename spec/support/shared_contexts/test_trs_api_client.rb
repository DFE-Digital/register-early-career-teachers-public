RSpec.shared_context "test TRS API returns a teacher" do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new
    )
  end
end

RSpec.shared_context "test TRS API returns nothing" do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new(raise_not_found: true)
    )
  end
end

RSpec.shared_context "test TRS API returns a merged teacher" do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new(raise_merged: true)
    )
  end
end

RSpec.shared_context "test TRS API returns a deactivated teacher" do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new(raise_deactivated: true)
    )
  end
end

RSpec.shared_context "test TRS API returns a teacher and then nothing" do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new,
      TRS::TestAPIClient.new(raise_not_found: true)
    )
  end
end

RSpec.shared_context "test TRS API returns a teacher without QTS" do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new(has_qts: false)
    )
  end
end

RSpec.shared_context "test TRS API returns a teacher prohibited from teaching" do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new(is_prohibited_from_teaching: true)
    )
  end
end

RSpec.shared_context "test TRS API returns a teacher with specific induction status" do |status|
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new(induction_status: status)
    )
  end
end

RSpec.shared_context "test TRS API returns a teacher that has passed their induction" do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new(induction_status: "Passed")
    )
  end
end

RSpec.shared_context "test TRS API returns a teacher that has failed their induction" do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new(induction_status: "Failed")
    )
  end
end

RSpec.shared_context "test TRS API returns a teacher that is exempt from induction" do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new(induction_status: "Exempt")
    )
  end
end

RSpec.shared_context "test TRS API returns a teacher and then a teacher that has passed their induction" do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new,
      TRS::TestAPIClient.new(induction_status: "Passed")
    )
  end
end

RSpec.shared_context "test TRS API returns a teacher and then a teacher that has failed their induction" do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new,
      TRS::TestAPIClient.new(induction_status: "Failed")
    )
  end
end

RSpec.shared_context "test TRS API returns a teacher and then a teacher that is exempt from induction" do
  before do
    allow(TRS::APIClient).to receive(:new).and_return(
      TRS::TestAPIClient.new,
      TRS::TestAPIClient.new(induction_status: "Exempt")
    )
  end
end
