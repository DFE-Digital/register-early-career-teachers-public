describe Teachers::Merge::InductionPeriods do
  subject { described_class.new(teacher: source) }

  let!(:source) do
    FactoryBot.create(:teacher,
                      :merged_in_trs,
                      trn: source_trn,
                      trs_redirected_to: destination_trn)
  end

  let!(:destination) { FactoryBot.create(:teacher, trn: destination_trn) }

  let(:source_trn) { "654321" }
  let(:destination_trn) { "123456" }

  let(:source_started_on) { 2.months.ago }
  let(:destination_started_on) { 1.month.ago }

  describe "#move!" do
    context "when the source is not being merged in TRS" do
      let!(:source) { FactoryBot.create(:teacher, trn: source_trn) }

      it "does not move any induction periods" do
        expect { subject.move! }.not_to(change { source.induction_periods.count })
      end
    end

    context "when there is no destination teacher" do
      let!(:destination) { nil }

      it "does not move any induction periods" do
        expect { subject.move! }.not_to(change { source.induction_periods.count })
      end
    end

    context "when the source does not have any induction periods" do
      context "when the destination does not have any induction periods" do
        it "does not move the source's induction periods" do
          expect { subject.move! }.not_to(change { source.induction_periods.count })
        end

        it "does not change the destination's induction periods" do
          expect { subject.move! }.not_to(change { destination.induction_periods.count })
        end
      end

      context "when the destination has induction periods" do
        before do
          FactoryBot.create(:induction_period, teacher: destination)
        end

        it "does not move the source's induction periods" do
          expect { subject.move! }.not_to(change { source.induction_periods.count })
        end

        it "does not change the destination's induction periods" do
          expect { subject.move! }.not_to(change { destination.induction_periods.count })
        end
      end
    end

    context "when the source has induction periods" do
      let!(:induction_extension) { FactoryBot.create(:induction_extension, teacher: source) }

      context "when the destination does not have any induction periods" do
        let!(:induction_period) do
          FactoryBot.create(:induction_period, teacher: source, started_on: source_started_on)
        end

        it "moves the source's induction periods and extensions to the destination" do
          subject.move!

          expect(induction_period.reload.teacher).to eq(destination)
          expect(induction_extension.reload.teacher).to eq(destination)
        end
      end

      context "when the destination has induction periods" do
        before do
          FactoryBot.create(:induction_period, :unfinished, teacher: destination, started_on: destination_started_on)
        end

        context "when the source's induction period overlaps with the destination's induction period" do
          let!(:induction_period) do
            FactoryBot.create(:induction_period, :unfinished, teacher: source, started_on: destination_started_on)
          end

          it "does not move the source's induction periods" do
            expect { subject.move! }.not_to(change { induction_period.reload.teacher })
          end

          it "does not move the source's induction extensions" do
            expect { subject.move! }.not_to(change { induction_extension.reload.teacher })
          end
        end

        context "when the source's induction period does not overlap with the destination's induction period" do
          let!(:induction_period) do
            FactoryBot.create(:induction_period,
                              teacher: source,
                              started_on: source_started_on,
                              finished_on: destination_started_on)
          end

          it "moves the source's induction periods and extensions to the destination" do
            subject.move!

            expect(induction_period.reload.teacher).to eq(destination)
            expect(induction_extension.reload.teacher).to eq(destination)
          end
        end
      end
    end
  end

  describe "#sync" do
    context "when the source is not being merged in TRS" do
      let!(:source) { FactoryBot.create(:teacher, trn: source_trn) }

      it "does not sync with TRS" do
        subject.move!

        expect(BeginECTInductionJob).not_to receive(:perform_now)
        subject.sync
      end
    end

    context "when there is no destination teacher" do
      let!(:destination) { nil }

      it "does not sync with TRS" do
        subject.move!

        expect(BeginECTInductionJob).not_to receive(:perform_now)
        subject.sync
      end
    end

    context "when the teacher does not have any induction periods" do
      context "when the destination does not have any induction periods" do
        it "does not sync with TRS" do
          subject.move!

          expect(BeginECTInductionJob).not_to receive(:perform_now)
          subject.sync
        end
      end

      context "when the destination has induction periods" do
        before do
          FactoryBot.create(:induction_period, teacher: destination)
        end

        it "does not sync with TRS" do
          subject.move!

          expect(BeginECTInductionJob).not_to receive(:perform_now)
          subject.sync
        end
      end
    end

    context "when the teacher has induction periods" do
      context "when the destination does not have any induction periods" do
        let!(:induction_period) do
          FactoryBot.create(:induction_period, teacher: source, started_on: source_started_on)
        end

        it "syncs the teachers induction start date with TRS" do
          subject.move!

          expect(BeginECTInductionJob).to receive(:perform_now).with(
            trn: destination.trn,
            start_date: induction_period.started_on
          )

          subject.sync
        end
      end

      context "when the destination has induction periods" do
        context "when the source's induction period overlaps with the destination's induction period" do
          let!(:induction_period) do
            FactoryBot.create(:induction_period, :unfinished, teacher: source, started_on: destination_started_on)
          end

          before do
            FactoryBot.create(:induction_period, :unfinished, teacher: destination, started_on: destination_started_on)
          end

          it "does not sync with TRS" do
            subject.move!

            expect(BeginECTInductionJob).not_to receive(:perform_now)
            subject.sync
          end
        end

        context "when the source's induction period does not overlap with the destination's induction period" do
          context "when the source's induction period starts before the destination's induction period" do
            let!(:induction_period) do
              FactoryBot.create(:induction_period,
                                teacher: source,
                                started_on: source_started_on,
                                finished_on: destination_started_on,
                                number_of_terms: 1)
            end

            before do
              FactoryBot.create(:induction_period, :unfinished, teacher: destination, started_on: destination_started_on)
            end

            it "syncs the source's induction start date with TRS" do
              subject.move!

              expect(BeginECTInductionJob).to receive(:perform_now).with(
                trn: destination.trn,
                start_date: induction_period.started_on
              )

              subject.sync
            end
          end

          context "when the source's induction period starts after the destination's induction period" do
            let!(:induction_period) do
              FactoryBot.create(:induction_period,
                                :unfinished,
                                teacher: source,
                                started_on: Time.zone.today)
            end

            before do
              FactoryBot.create(:induction_period, :unfinished, teacher: destination, started_on: destination_started_on, finished_on: Date.yesterday, number_of_terms: 1)
            end

            it "does not sync with TRS" do
              subject.move!

              expect(BeginECTInductionJob).not_to receive(:perform_now)
              subject.sync
            end
          end
        end
      end
    end
  end
end
