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
      let(:urns) { [20_001, 20_002, 20_003, 20_005, 20_006, 20_007] }
      let(:open_gias_school) { FactoryBot.create(:gias_school, status: "open", urn: 20_001) }
      let(:replaced_gias_school) { FactoryBot.create(:gias_school, :closed, urn: 20_002) }
      let(:merged_gias_school) { FactoryBot.create(:gias_school, :closed, urn: 20_003) }
      let(:closed_gias_school) { FactoryBot.create(:gias_school, :closed, urn: 20_005) }
      let(:successor_gias_school_1) { FactoryBot.create(:gias_school, status: "open", urn: 20_006) }
      let(:successor_gias_school_2) { FactoryBot.create(:gias_school, status: "open", urn: 20_007) }

      before do
        allow(GIAS::Reconciliation::Open).to receive(:open!).and_return(false)
        allow(GIAS::Reconciliation::Close).to receive(:close!).and_return(false)
        allow(GIAS::Reconciliation::Replace).to receive(:replace!).and_return(false)
        allow(GIAS::Reconciliation::Merge).to receive(:merge!).and_return(false)

        allow(GIAS::Reconciliation::Open).to receive(:open!).with(open_gias_school).and_return(true)
        allow(GIAS::Reconciliation::Close).to receive(:close!).with(closed_gias_school).and_return(true)
        allow(GIAS::Reconciliation::Merge).to receive(:merge!).with(merged_gias_school).and_return(true)
        allow(GIAS::Reconciliation::Replace).to receive(:replace!).with(replaced_gias_school).and_return(true)
      end

      context "when all schools are reconcilable" do
        before do
          FactoryBot.create(:gias_school_link, :successor_unique, from_gias_school: replaced_gias_school, to_gias_school: successor_gias_school_1)
          FactoryBot.create(:gias_school_link, :successor_merged, from_gias_school: merged_gias_school, to_gias_school: successor_gias_school_2)
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

        it "does not open the successor schools of replaced schools" do
          expect(GIAS::Reconciliation::Open).not_to receive(:open!).with(successor_gias_school_1)

          service
        end

        it "merges the merged schools" do
          expect(GIAS::Reconciliation::Merge).to receive(:merge!).with(merged_gias_school)

          service
        end

        it "does not open the successor schools of merged schools" do
          expect(GIAS::Reconciliation::Open).not_to receive(:open!).with(successor_gias_school_2)

          service
        end

        it "returns an empty array of unreconcilable URNs" do
          expect(service).to eq([])
        end
      end

      context "when two schools are merging into the same successor" do
        let(:urns) { [20_003, 20_007, 20_008] }
        let(:merged_gias_school) { FactoryBot.create(:gias_school, :with_school, :closed, closed_on: Date.current, urn: 20_003) }
        let(:other_merged_gias_school) { FactoryBot.create(:gias_school, :with_school, :closed, closed_on: Date.current, urn: 20_008) }
        let(:successor_gias_school_2) { FactoryBot.create(:gias_school, :with_school, status: "open", urn: 20_007) }

        before do
          FactoryBot.create(:gias_school_link, :successor_merged, from_gias_school: merged_gias_school, to_gias_school: successor_gias_school_2)
          FactoryBot.create(:gias_school_link, :successor_merged, from_gias_school: other_merged_gias_school, to_gias_school: successor_gias_school_2)
          allow(GIAS::Reconciliation::Merge).to receive(:merge!).with(other_merged_gias_school).and_return(true)
        end

        it "merges both schools" do
          expect(GIAS::Reconciliation::Merge).to receive(:merge!).with(merged_gias_school)
          expect(GIAS::Reconciliation::Merge).to receive(:merge!).with(other_merged_gias_school)

          service
        end

        context "when a teacher has overlapping mentor periods at the predecessor schools" do
          let(:mentor_teacher) { FactoryBot.create(:teacher) }

          before do
            FactoryBot.create(:mentor_at_school_period, teacher: mentor_teacher, school: merged_gias_school.school, started_on: Date.new(2025, 1, 1), finished_on: Date.new(2025, 6, 30))
            FactoryBot.create(:mentor_at_school_period, teacher: mentor_teacher, school: other_merged_gias_school.school, started_on: Date.new(2025, 5, 1), finished_on: Date.new(2025, 10, 31))
            FactoryBot.create(:mentor_at_school_period, teacher: mentor_teacher, school: successor_gias_school_2.school, started_on: Date.new(2025, 8, 1), finished_on: Date.new(2025, 12, 31))

            allow(GIAS::Reconciliation::Merge).to receive(:merge!).and_call_original
          end

          it "merges the mentor periods correctly" do
            service

            merged_mentor_at_school_periods = mentor_teacher.reload.mentor_at_school_periods

            expect(merged_mentor_at_school_periods.count).to eq(1)
            expect(merged_mentor_at_school_periods.first.started_on).to eq(Date.new(2025, 1, 1))
            expect(merged_mentor_at_school_periods.first.finished_on).to eq(Date.new(2025, 12, 31))
            expect(merged_mentor_at_school_periods.first.school).to eq(successor_gias_school_2.school)
          end
        end
      end

      context "when there are schools that cannot be reconciled" do
        let(:urns) { [20_001, 20_002, 20_003, 20_004, 20_005, 20_006, 20_007] }
        let(:split_gias_school) { FactoryBot.create(:gias_school, :closed, closed_on: Date.current, urn: 20_004) }

        before do
          allow(GIAS::Reconciliation::Open).to receive(:open!).with(successor_gias_school_1).and_return(false)
          allow(GIAS::Reconciliation::Open).to receive(:open!).with(successor_gias_school_2).and_return(false)

          FactoryBot.create(:gias_school_link, :successor_split, from_gias_school: split_gias_school, to_gias_school: successor_gias_school_1)
          FactoryBot.create(:gias_school_link, :successor_split, from_gias_school: split_gias_school, to_gias_school: successor_gias_school_2)
          FactoryBot.create(:gias_school_link, :predecessor, from_gias_school: successor_gias_school_1, to_gias_school: split_gias_school)
          FactoryBot.create(:gias_school_link, :predecessor, from_gias_school: successor_gias_school_2, to_gias_school: split_gias_school)
        end

        it "raises an error that is captured by Sentry for unreconcilable schools" do
          expect(Sentry).to receive(:capture_message).with(
            "Could not reconcile school with URN 20004",
            level: :info,
            extra: hash_including(urn: 20_004,
                                  status: "closed",
                                  closed_on: Date.current,
                                  predecessor_urns: [],
                                  successor_urns: [20_006, 20_007])
          ).once

          expect(Sentry).to receive(:capture_message).with(
            "Could not reconcile school with URN 20006",
            level: :info,
            extra: hash_including(urn: 20_006,
                                  status: "open",
                                  closed_on: nil,
                                  predecessor_urns: [20_004],
                                  successor_urns: [])
          ).once

          expect(Sentry).to receive(:capture_message).with(
            "Could not reconcile school with URN 20007",
            level: :info,
            extra: hash_including(urn: 20_007,

                                  status: "open",
                                  closed_on: nil,
                                  predecessor_urns: [20_004],
                                  successor_urns: [])
          ).once

          service
        end

        it "returns the unreconcilable URNs" do
          expect(service).to eq([20_004, 20_006, 20_007])
        end

        it "reconciles the remaining schools" do
          service

          expect(GIAS::Reconciliation::Open).to have_received(:open!).with(open_gias_school)
          expect(GIAS::Reconciliation::Close).to have_received(:close!).with(closed_gias_school)
          expect(GIAS::Reconciliation::Merge).to have_received(:merge!).with(merged_gias_school)
          expect(GIAS::Reconciliation::Replace).to have_received(:replace!).with(replaced_gias_school)
        end

        context "for schools with a proposed status" do
          let!(:proposed_to_open_gias_school) { FactoryBot.create(:gias_school, status: "proposed_to_open", urn: 20_011) }
          let!(:proposed_to_close_gias_school) { FactoryBot.create(:gias_school, status: "proposed_to_close", urn: 20_012) }
          let(:urns) { [20_011, 20_012] }

          it "does not log a failure for the schools" do
            expect(Sentry).not_to receive(:capture_message).with("Could not reconcile school with URN 20011", any_args)
            expect(Sentry).not_to receive(:capture_message).with("Could not reconcile school with URN 20012", any_args)

            service
          end
        end
      end

      context "when reconciling a school raises an error" do
        before do
          allow(GIAS::Reconciliation::Open).to receive(:open!).with(open_gias_school).and_raise(StandardError.new("An error occurred"))
        end

        it "the error is captured by Sentry" do
          expect(Sentry).to receive(:capture_exception)
            .with(instance_of(StandardError),
                  extra: hash_including(urn: 20_001,
                                        status: "open",
                                        closed_on: nil,
                                        predecessor_urns: [],
                                        successor_urns: [])).once

          service
        end

        it "the URN of the school is included in the unreconcilable URNs" do
          expect(service).to include(20_001)
        end

        it "reconciles the remaining schools" do
          service

          expect(GIAS::Reconciliation::Close).to have_received(:close!).with(closed_gias_school)
          expect(GIAS::Reconciliation::Merge).to have_received(:merge!).with(merged_gias_school)
          expect(GIAS::Reconciliation::Replace).to have_received(:replace!).with(replaced_gias_school)
        end
      end
    end
  end
end
