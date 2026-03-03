RSpec.describe APISeedData::ECTScenarios do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  let(:contract_period_2023) { FactoryBot.create(:contract_period, year: 2023) }
  let(:contract_period_2024) { FactoryBot.create(:contract_period, year: 2024) }
  let(:contract_period_2025) { FactoryBot.create(:contract_period, year: 2025) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }

    # Create support data
    FactoryBot.create_list(:lead_provider, 2).each do |lead_provider|
      FactoryBot.create_list(:lead_provider_delivery_partnership, 3, :for_year, lead_provider:, year: contract_period_2023.year)
      FactoryBot.create_list(:lead_provider_delivery_partnership, 3, :for_year, lead_provider:, year: contract_period_2024.year)
      FactoryBot.create_list(:lead_provider_delivery_partnership, 3, :for_year, lead_provider:, year: contract_period_2025.year)
    end
    APISeedData::Schools.new.plant
    APISeedData::SchoolPartnerships.new.plant
    APISeedData::SchedulesAndMilestones.new.plant
  end

  describe "#plant" do
    it "logs the creation of scenarios" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO).at_least(:once)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter).at_least(:once)
      expect(logger).to have_received(:info).with(/Planting api ect seed scenarios/).once
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any teachers" do
        expect { instance.plant }.not_to change(Teacher, :count)
      end
    end
  end

  describe "#ect_2025_with_2024_mentor" do
    it "creates an ECT with a mentor" do
      expect {
        instance.ect_2025_with_2024_mentor
      }.to change(Teacher, :count).by_at_least(2) # 1 mentor + 1 ECT per active lead provider
    end

    it "creates ECTs for contract period 2025" do
      instance.ect_2025_with_2024_mentor

      ects_count = Teacher
        .joins(ect_at_school_periods: { training_periods: :active_lead_provider })
        .where(active_lead_providers: { contract_period_year: contract_period_2025.year })
        .distinct
        .count

      expect(ects_count).to be >= 1
    end

    it "creates mentors for contract period 2024" do
      instance.ect_2025_with_2024_mentor

      mentors_count = Teacher
        .joins(mentor_at_school_periods: { training_periods: :active_lead_provider })
        .where(active_lead_providers: { contract_period_year: contract_period_2024.year })
        .distinct
        .count

      expect(mentors_count).to be >= 1
    end

    it "makes sure the created mentors and mentees are both linked" do
      instance.ect_2025_with_2024_mentor

      mentorships = MentorshipPeriod
        .joins(:mentor, :mentee)
        .where(mentee: ECTAtSchoolPeriod.joins(training_periods: :active_lead_provider).where(active_lead_providers: { contract_period_year: contract_period_2025.year }))
        .where(mentor: MentorAtSchoolPeriod.joins(training_periods: :active_lead_provider).where(active_lead_providers: { contract_period_year: contract_period_2024.year }))

      expect(mentorships.count).to be >= 1

      mentorships.each do |mentorship|
        expect(mentorship.mentee.mentorship_periods.first.mentor).to eq(mentorship.mentor)
        expect(mentorship.mentor.mentorship_periods.first.mentee).to eq(mentorship.mentee)
      end
    end

    it "logs the creation of ECT scenarios" do
      instance.ect_2025_with_2024_mentor

      expect(logger).to have_received(:info).with(/Created ECT \(TRN: .*?\) from 2025 with mentor from 2024/).at_least(:once)
    end
  end

  describe "#ect_2025_with_2023_mentor" do
    it "creates an ECT with a mentor" do
      expect {
        instance.ect_2025_with_2023_mentor
      }.to change(Teacher, :count).by_at_least(2) # 1 mentor + 1 ECT per active lead provider
    end

    it "creates ECTs for contract period 2025" do
      instance.ect_2025_with_2023_mentor

      ects_count = Teacher
        .joins(ect_at_school_periods: { training_periods: :active_lead_provider })
        .where(active_lead_providers: { contract_period_year: contract_period_2025.year })
        .distinct
        .count

      expect(ects_count).to be >= 1
    end

    it "creates mentors for contract period 2023" do
      instance.ect_2025_with_2023_mentor

      mentors_count = Teacher
        .joins(mentor_at_school_periods: { training_periods: :active_lead_provider })
        .where(active_lead_providers: { contract_period_year: contract_period_2023.year })
        .distinct
        .count

      expect(mentors_count).to be >= 1
    end

    it "makes sure the created mentors and mentees are both linked" do
      instance.ect_2025_with_2023_mentor

      mentorships = MentorshipPeriod
        .joins(:mentor, :mentee)
        .where(mentee: ECTAtSchoolPeriod.joins(training_periods: :active_lead_provider).where(active_lead_providers: { contract_period_year: contract_period_2025.year }))
        .where(mentor: MentorAtSchoolPeriod.joins(training_periods: :active_lead_provider).where(active_lead_providers: { contract_period_year: contract_period_2023.year }))

      expect(mentorships.count).to be >= 1

      mentorships.each do |mentorship|
        expect(mentorship.mentee.mentorship_periods.first.mentor).to eq(mentorship.mentor)
        expect(mentorship.mentor.mentorship_periods.first.mentee).to eq(mentorship.mentee)
      end
    end

    it "logs the creation of ECT scenarios" do
      instance.ect_2025_with_2023_mentor

      expect(logger).to have_received(:info).with(/Created ECT \(TRN: .*?\) from 2025 with mentor from 2023/).at_least(:once)
    end
  end
end
