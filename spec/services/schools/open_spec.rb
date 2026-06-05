RSpec.describe Schools::Open do
  subject(:service) { described_class.call }

  describe "#call" do
    let!(:open_gias_school) do
      FactoryBot.create(:gias_school, :open)
    end

    let!(:existing_school) do
      FactoryBot.create(:gias_school, :open, :with_school)
    end

    let!(:closed_gias_school) do
      FactoryBot.create(:gias_school, :closed)
    end

    before do
      allow(open_gias_school).to receive(:create_school!)
      allow(existing_school).to receive(:create_school!)
      allow(closed_gias_school).to receive(:create_school!)
    end

    it "creates schools for open GIAS schools without a school record" do
      service

      expect(open_gias_school).to have_received(:create_school!)
      expect(existing_school).not_to have_received(:create_school!)
      expect(closed_gias_school).not_to have_received(:create_school!)
    end
  end
end
