RSpec.describe Declarations::MentorCompletion do
  let(:author) { Events::LeadProviderAPIAuthor.new(lead_provider:) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:) }
  let(:training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:) }
  let(:declaration) { FactoryBot.create(:declaration, :eligible, declaration_type: "completed", training_period:) }

  let(:service) do
    described_class.new(
      author:,
      declaration:
    )
  end

  describe "#perform" do
    context "when declaration type is `completed`" do
      context "when mentor training is completed" do
        it "mentor is now ineligible for funding" do
          expect(teacher.mentor_became_ineligible_for_funding_on).to be_nil
          expect(teacher.mentor_became_ineligible_for_funding_reason).to be_nil

          service.perform

          expect(teacher.mentor_became_ineligible_for_funding_on).to eq(declaration.declaration_date.to_date)
          expect(teacher.mentor_became_ineligible_for_funding_reason).to eq("completed_declaration_received")
        end

        it "records a mentor completion status change event" do
          expect(Events::Record).to receive(:record_mentor_completion_status_change!).with(
            author:,
            teacher:,
            training_period:,
            declaration:,
            modifications: hash_including(
              mentor_became_ineligible_for_funding_on: [nil, declaration.declaration_date.to_date],
              mentor_became_ineligible_for_funding_reason: [nil, "completed_declaration_received"]
            )
          )

          service.perform
        end
      end

      context "when completed mentor training is voided" do
        let!(:teacher) { FactoryBot.create(:teacher, mentor_became_ineligible_for_funding_on: Time.zone.today, mentor_became_ineligible_for_funding_reason: "completed_declaration_received") }
        let!(:declaration) { FactoryBot.create(:declaration, :voided, declaration_type: "completed", training_period:) }

        it "mentor is now eligible for funding" do
          expect(teacher.mentor_became_ineligible_for_funding_on).to eq(Time.zone.today)
          expect(teacher.mentor_became_ineligible_for_funding_reason).to eq("completed_declaration_received")

          service.perform

          expect(teacher.mentor_became_ineligible_for_funding_on).to be_nil
          expect(teacher.mentor_became_ineligible_for_funding_reason).to be_nil
        end

        it "records a mentor completion status change event" do
          expect(Events::Record).to receive(:record_mentor_completion_status_change!).with(
            author:,
            teacher:,
            training_period:,
            declaration:,
            modifications: hash_including(
              mentor_became_ineligible_for_funding_on: [Time.zone.today, nil],
              mentor_became_ineligible_for_funding_reason: ["completed_declaration_received", nil]
            )
          )

          service.perform
        end
      end
    end

    context "when declaration type is not `completed`" do
      let(:declaration) { FactoryBot.create(:declaration, :eligible, declaration_type: "started") }

      it "returns false without action" do
        expect(Events::Record).not_to receive(:record_mentor_completion_status_change!)
        expect(service.perform).to be(false)
      end
    end

    context "when teacher type is ECT" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }
      let(:training_period) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:) }

      it "returns false without action" do
        expect(Events::Record).not_to receive(:record_mentor_completion_status_change!)
        expect(service.perform).to be(false)
      end
    end
  end
end
