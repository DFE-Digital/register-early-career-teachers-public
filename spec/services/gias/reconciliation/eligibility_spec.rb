RSpec.describe GIAS::Reconciliation::Eligibility do
  subject(:eligibility) { described_class.new(gias_school) }

  describe "#can_be_closed?" do
    subject { eligibility.can_be_closed? }

    let(:gias_school) do
      FactoryBot.create(:gias_school, :with_school, status: :closed, closed_on:)
    end

    let(:closed_on) { Date.current }

    it { is_expected.to be true }

    context "when the school has a successor" do
      before do
        FactoryBot.create(:gias_school_link, :successor, from_gias_school: gias_school)
      end

      it { is_expected.to be false }
    end

    context "when the school is a predecessor" do
      before do
        FactoryBot.create(:gias_school_link, :predecessor, to_gias_school: gias_school)
      end

      it { is_expected.to be false }
    end

    context "when a school closure event has already been recorded" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :closed, closed_on:) }

      before do
        FactoryBot.create(:event, event_type: :school_closed, school: gias_school.school)
      end

      it { is_expected.to be false }
    end

    context "when the school is not closed" do
      let(:gias_school) { FactoryBot.create(:gias_school, status: :proposed_to_close) }

      it { is_expected.to be false }
    end

    context "when the school closed in the past" do
      let(:closed_on) { Date.yesterday }

      it { is_expected.to be true }
    end

    context "when the school closes in the future" do
      let(:closed_on) { Date.tomorrow }

      it { is_expected.to be false }
    end

    context "when the school has no closed_on date" do
      let(:closed_on) { nil }

      it { is_expected.to be false }
    end

    context "when there is no associated school record" do
      let(:gias_school) { FactoryBot.create(:gias_school, status: :closed, closed_on:) }

      it { is_expected.to be false }
    end
  end

  describe "#can_be_opened?" do
    subject { eligibility.can_be_opened? }

    let(:gias_school) { FactoryBot.create(:gias_school, status: :open) }

    it { is_expected.to be true }

    context "when the school has a predecessor" do
      before do
        FactoryBot.create(:gias_school_link, :predecessor, from_gias_school: gias_school)
      end

      it { is_expected.to be false }
    end

    context "when the school has a successor" do
      before do
        FactoryBot.create(:gias_school_link, :successor, from_gias_school: gias_school)
      end

      it { is_expected.to be false }
    end

    context "when the school is a successor" do
      before do
        FactoryBot.create(:gias_school_link, :successor, to_gias_school: gias_school)
      end

      it { is_expected.to be false }
    end

    context "when the school is a predecessor" do
      before do
        FactoryBot.create(:gias_school_link, :predecessor, to_gias_school: gias_school)
      end

      it { is_expected.to be false }
    end

    context "when the school already has an associated school" do
      let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :open) }

      it { is_expected.to be false }
    end

    context "when the school is not open" do
      let(:gias_school) { FactoryBot.create(:gias_school, status: :proposed_to_open) }

      it { is_expected.to be false }
    end
  end

  describe "#can_be_replaced?" do
    subject { eligibility.can_be_replaced? }

    let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :closed, closed_on:) }
    let(:closed_on) { Date.current }

    context "when the school has no successor" do
      it { is_expected.to be false }
    end

    context "when the school has one successor" do
      let(:successor) { FactoryBot.create(:gias_school, status: :open) }

      let(:link_type) { :successor_unique }

      before do
        FactoryBot.create(:gias_school_link, link_type, from_gias_school: gias_school, to_gias_school: successor)
      end

      it { is_expected.to be true }

      context "when the successor is not open" do
        let(:successor) { FactoryBot.create(:gias_school, status: :proposed_to_open) }

        it { is_expected.to be false }
      end

      context "when the successor already has an associated school" do
        let(:successor) { FactoryBot.create(:gias_school, :with_school, status: :open) }

        it { is_expected.to be false }
      end

      context "when the school is not closed" do
        let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :proposed_to_close) }

        it { is_expected.to be false }
      end

      context "when the school closed in the past" do
        let(:closed_on) { Date.yesterday }

        it { is_expected.to be true }
      end

      context "when the school closes in the future" do
        let(:closed_on) { Date.tomorrow }

        it { is_expected.to be false }
      end

      context "when the school has no closed_on date" do
        let(:closed_on) { nil }

        it { is_expected.to be false }
      end

      context "when the link is a merge" do
        let(:link_type) { :successor_merged }

        it { is_expected.to be false }
      end

      context "when the link is an amalgamation" do
        let(:link_type) { :successor_amalgamated }

        it { is_expected.to be false }
      end

      context "when the link is a split" do
        let(:link_type) { :successor_split }

        it { is_expected.to be false }
      end

      context "when there is no associated school record" do
        let(:gias_school) { FactoryBot.create(:gias_school, status: :closed, closed_on:) }

        it { is_expected.to be false }
      end
    end

    context "when the school has multiple successors" do
      let(:successor) { FactoryBot.create(:gias_school, :with_school, status: :open) }

      before do
        FactoryBot.create(:gias_school_link, :successor_unique, from_gias_school: gias_school, to_gias_school: successor)
        FactoryBot.create(:gias_school_link, :successor, from_gias_school: gias_school)
      end

      it { is_expected.to be false }
    end
  end

  describe "#can_be_merged?" do
    subject { eligibility.can_be_merged? }

    let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :closed, closed_on:) }

    let(:closed_on) { Date.current }

    context "when the school has no successor" do
      it { is_expected.to be false }
    end

    context "when the school has one successor" do
      let(:successor) { FactoryBot.create(:gias_school, :with_school, status: :open) }

      let(:link_type) { :successor_merged }

      before do
        FactoryBot.create(:gias_school_link, link_type, from_gias_school: gias_school, to_gias_school: successor)
      end

      it { is_expected.to be true }

      context "when the successor is not open" do
        let(:successor) { FactoryBot.create(:gias_school, status: :proposed_to_open) }

        it { is_expected.to be false }
      end

      context "when the school is not closed" do
        let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :proposed_to_close) }

        it { is_expected.to be false }
      end

      context "when the school closed in the past" do
        let(:closed_on) { Date.yesterday }

        it { is_expected.to be true }
      end

      context "when the school closes in the future" do
        let(:closed_on) { Date.tomorrow }

        it { is_expected.to be false }
      end

      context "when the school has no closed_on date" do
        let(:closed_on) { nil }

        it { is_expected.to be false }
      end

      context "when a merged event has already been recorded" do
        before do
          FactoryBot.create(:event, event_type: :school_merged, school: gias_school.school)
        end

        it { is_expected.to be false }
      end

      context "when the link represents an amalgamation" do
        let(:link_type) { :successor_amalgamated }

        it { is_expected.to be true }
      end

      context "when the link represents a replacement" do
        let(:link_type) { :successor_unique }

        it { is_expected.to be false }
      end

      context "when the link represents a split" do
        let(:link_type) { :successor_split }

        it { is_expected.to be false }
      end

      context "when there is no associated school record" do
        let(:gias_school) { FactoryBot.create(:gias_school, status: :closed, closed_on:) }

        it { is_expected.to be false }
      end
    end

    context "when the school has multiple successors" do
      let(:first_successor) do
        FactoryBot.create(:gias_school, :with_school, status: :open)
      end

      let(:second_successor) do
        FactoryBot.create(:gias_school, :with_school, status: :open)
      end

      before do
        FactoryBot.create(:gias_school_link, :successor_merged, from_gias_school: gias_school, to_gias_school: first_successor)
        FactoryBot.create(:gias_school_link, :successor_merged, from_gias_school: gias_school, to_gias_school: second_successor)
      end

      it { is_expected.to be false }
    end
  end
end
