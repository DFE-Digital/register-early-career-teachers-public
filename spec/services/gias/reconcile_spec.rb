RSpec.describe GIAS::Reconcile, type: :service do
  let(:service) { described_class.new(urns).call }

  before do
    allow(Sentry).to receive(:capture_exception)
  end

  describe "#call" do
    context "when there are no schools to reconcile" do
      let(:urns) { [] }

      it "does not raise an error" do
        expect { service }.not_to raise_error
      end

      it "returns an empty array of unreconcilable URNs" do
        expect(service).to eq([])
      end
    end

    context "when there are schools to reconcile" do
      let(:urns) { [20_001, 20_002, 20_003, 20_004, 20_005] }
      let(:open_gias_school) { FactoryBot.create(:gias_school, :open, urn: 20_001) }
      let(:replaced_gias_school) { FactoryBot.create(:gias_school, :closed, urn: 20_002) }
      let(:merged_gias_school) { FactoryBot.create(:gias_school, :closed, urn: 20_003) }
      let(:closed_gias_school) { FactoryBot.create(:gias_school, :closed, urn: 20_005) }

      before do
        allow(GIAS::Reconciliation::Open).to receive(:open!).and_return(false)
        allow(GIAS::Reconciliation::Close).to receive(:close!).and_return(false)
        allow(GIAS::Reconciliation::Replace).to receive(:replace!).and_return(false)
        allow(GIAS::Reconciliation::Merge).to receive(:merge!).and_return(false)

        allow(GIAS::Reconciliation::Open).to receive(:open!).with(open_gias_school).and_return(:can_be_opened)
        allow(GIAS::Reconciliation::Close).to receive(:close!).with(closed_gias_school).and_return(:can_be_closed)
        allow(GIAS::Reconciliation::Merge).to receive(:merge!).with(merged_gias_school).and_return(:can_be_merged)
        allow(GIAS::Reconciliation::Replace).to receive(:replace!).with(replaced_gias_school).and_return(:can_be_replaced)
      end

      it "opens the open schools" do
        expect(GIAS::Reconciliation::Open).to receive(:open!).with(open_gias_school)

        service
      end

      it "closes the closed schools" do
        expect(GIAS::Reconciliation::Close).to receive(:close!).with(closed_gias_school)

        service
      end

      it "replaces the replaced schools" do
        expect(GIAS::Reconciliation::Replace).to receive(:replace!).with(replaced_gias_school)

        service
      end

      it "merges the merged schools" do
        expect(GIAS::Reconciliation::Merge).to receive(:merge!).with(merged_gias_school)

        service
      end

      context "when there are schools that cannot be reconciled" do
        let(:urns) { [20_001, 20_002, 20_003, 20_004, 20_005, 20_006, 20_007, 20_008, 20_009] }
        let!(:split_gias_school) { FactoryBot.create(:gias_school, :closed, closed_on: Date.current, urn: 20_004) }
        let!(:successor_1) { FactoryBot.create(:gias_school, :open, urn: 20_006) }
        let!(:successor_2) { FactoryBot.create(:gias_school, :open, urn: 20_007) }
        let!(:predecessor) { FactoryBot.create(:gias_school, :with_school, :closed, urn: 20_008) }
        let!(:other_unreconcilable_gias_school) { FactoryBot.create(:gias_school, :open, urn: 20_009) }

        before do
          allow(GIAS::Reconciliation::Open).to receive(:open!).with(successor_1).and_return(true)
          allow(GIAS::Reconciliation::Open).to receive(:open!).with(successor_2).and_return(true)
          allow(GIAS::Reconciliation::Close).to receive(:close!).with(predecessor).and_return(true)
          allow(GIAS::Reconciliation::Open).to receive(:open!).with(other_unreconcilable_gias_school).and_raise(StandardError, "Some error")

          FactoryBot.create(:gias_school_link, :successor_split, from_gias_school: split_gias_school, to_gias_school: successor_1)
          FactoryBot.create(:gias_school_link, :successor_split, from_gias_school: split_gias_school, to_gias_school: successor_2)
          FactoryBot.create(:gias_school_link, :predecessor, from_gias_school: split_gias_school, to_gias_school: predecessor)
        end

        it "raises an error that is captured by Sentry for unreconcilable schools, which includes URN details of successor and predecessors" do
          service

          expect(Sentry).to have_received(:capture_exception).twice

          expect(Sentry).to have_received(:capture_exception).with(
            an_instance_of(GIAS::Reconcile::UnreconcilableSchoolError),
            extra: {
              urn: 20_004,
              status: "closed",
              closed_on: Date.current,
              predecessor_urns: [20_008],
              successor_urns: [20_006, 20_007]
            }
          ).once
        end

        it "returns the unreconcilable URNs" do
          expect(service).to eq([20_004, 20_009])
        end

        it "reconciles the remaining schools" do
          service

          expect(GIAS::Reconciliation::Open).to have_received(:open!).with(open_gias_school)
          expect(GIAS::Reconciliation::Close).to have_received(:close!).with(closed_gias_school)
          expect(GIAS::Reconciliation::Merge).to have_received(:merge!).with(merged_gias_school)
          expect(GIAS::Reconciliation::Replace).to have_received(:replace!).with(replaced_gias_school)
        end
      end
    end
  end
end
