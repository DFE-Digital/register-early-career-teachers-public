require "rails_helper"

RSpec.describe Teachers::Induction do
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:service) { described_class.new(teacher) }

  describe "#current_induction_period" do
    before do
      FactoryBot.create(:induction_period, teacher:, started_on: 2.years.ago, finished_on: 1.year.ago)
    end

    it "returns the induction period without a finished_on date" do
      current_period = FactoryBot.create(:induction_period, :active, teacher:, started_on: 6.months.ago)

      expect(service.current_induction_period).to eq(current_period)
    end

    it "returns nil when there is no current period" do
      expect(service.current_induction_period).to be_nil
    end
  end

  describe "#past_induction_periods" do
    let(:older_finish) do
      FactoryBot.create(:induction_period,
                        teacher:,
                        started_on: 3.years.ago,
                        finished_on: 2.years.ago)
    end
    let(:recent_finish) do
      FactoryBot.create(:induction_period,
                        teacher:,
                        started_on: 2.years.ago,
                        finished_on: 1.year.ago)
    end
    let(:current) do
      FactoryBot.create(:induction_period,
                        teacher:,
                        started_on: 6.months.ago,
                        finished_on: nil)
    end
    it "returns completed induction periods ordered by finish date ascending (oldest completed first)" do
      past_periods = service.past_induction_periods

      expect(past_periods).to eq([older_finish, recent_finish])
    end
  end

  describe "#induction_start_date" do
    it "returns the start date of the first induction period" do
      FactoryBot.create(:induction_period,
                        teacher:,
                        started_on: 2.years.ago,
                        finished_on: 1.year.ago)
      FactoryBot.create(:induction_period,
                        teacher:,
                        started_on: 3.years.ago,
                        finished_on: 2.years.ago)
      expect(service.induction_start_date).to eq(3.years.ago.to_date)
    end

    it "returns nil when there are no induction periods" do
      expect(service.induction_start_date).to be_nil
    end
  end

  describe "#has_induction_periods?" do
    it "returns true when teacher has induction periods" do
      FactoryBot.create(:induction_period,
                        teacher:,
                        started_on: 1.year.ago,
                        finished_on: 6.months.ago)
      expect(service.has_induction_periods?).to be true
    end

    it "returns false when teacher has no induction periods" do
      expect(service.has_induction_periods?).to be false
    end
  end

  describe "#has_extensions?" do
    it "returns true when teacher has induction extensions" do
      FactoryBot.create(:induction_extension, teacher:)

      expect(service.has_extensions?).to be true
    end

    it "returns false when teacher has no induction extensions" do
      expect(service.has_extensions?).to be false
    end
  end

  describe "#with_appropriate_body?" do
    let(:other_appropriate_body) { FactoryBot.create(:appropriate_body) }
    let(:induction_period) { FactoryBot.create(:induction_period, :active, teacher:) }

    it "returns true when the current induction is with the body" do
      expect(service.with_appropriate_body?(induction_period.appropriate_body)).to be true
    end

    it "returns false when the current induction is with another body" do
      expect(service.with_appropriate_body?(other_appropriate_body)).to be false
    end
  end
end
