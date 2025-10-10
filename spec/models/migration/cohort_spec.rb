describe Migration::Cohort, type: :model do
  subject { FactoryBot.create(:migration_cohort) }

  describe "#next" do
    let!(:next_cohort) { FactoryBot.create(:migration_cohort, start_year: subject.start_year + 1) }

    it "returns the next cohort of the given cohort" do
      expect(subject.next).to eq(next_cohort)
    end
  end

  describe "#payments_frozen?" do
    context "when the time to freeze payments was set to be in the past" do
      it do
        freeze_time do
          subject.payments_frozen_at = 1.second.ago
          expect(subject).to be_payments_frozen
        end
      end
    end

    context "when the time to freeze payments was not set to be in the past" do
      it do
        freeze_time do
          subject.payments_frozen_at = 2.minutes.from_now
          expect(subject).not_to be_payments_frozen
        end
      end
    end

    context "when no time to freeze payments was set" do
      it do
        freeze_time do
          subject.payments_frozen_at = nil
          expect(subject).not_to be_payments_frozen
        end
      end
    end
  end
end
