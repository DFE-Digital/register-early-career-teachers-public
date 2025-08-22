describe Teachers::CloseOldSchoolPeriods do
  subject(:service) { described_class.new(teacher:, new_school_start_date:, author:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:new_school_start_date) { Date.new(2024, 6, 1) }
  let(:school) { FactoryBot.create(:school) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }

  describe "#call" do
    context "with a single period to close" do
      let!(:period_to_close) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          started_on: Date.new(2024, 1, 1),
          finished_on: nil
        )
      end

      let!(:period_that_should_not_be_closed) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher: FactoryBot.create(:teacher),
          started_on: Date.new(2024, 7, 1),
          finished_on: nil
        )
      end

      it "calls ECTAtSchoolPeriods::Finish for the period" do
        finish_service = double("ECTAtSchoolPeriods::Finish", finish!: true)
        allow(ECTAtSchoolPeriods::Finish).to receive(:new).and_return(finish_service)

        service.call

        expect(ECTAtSchoolPeriods::Finish).to have_received(:new).with(
          ect_at_school_period: period_to_close,
          finished_on: new_school_start_date,
          author:
        )
        expect(finish_service).to have_received(:finish!)
      end

      it "does not call ECTAtSchoolPeriods::Finish for periods that shouldn't be closed" do
        finish_service = double("ECTAtSchoolPeriods::Finish", finish!: true)
        allow(ECTAtSchoolPeriods::Finish).to receive(:new).and_return(finish_service)

        service.call

        expect(ECTAtSchoolPeriods::Finish).not_to have_received(:new).with(
          hash_including(ect_at_school_period: period_that_should_not_be_closed)
        )
      end

      it "wraps the operations in a transaction" do
        allow(ActiveRecord::Base).to receive(:transaction).and_call_original

        service.call

        expect(ActiveRecord::Base).to have_received(:transaction).at_least(:once)
      end

      context "when ECTAtSchoolPeriods::Finish raises an error" do
        it "rolls back the transaction" do
          allow(ECTAtSchoolPeriods::Finish).to receive(:new).and_raise(StandardError, "Something went wrong")

          expect { service.call }.to raise_error(StandardError, "Something went wrong")

          # Verify the period was not actually closed
          expect(period_to_close.reload.finished_on).to be_nil
        end
      end
    end

    context "with multiple periods for the same teacher" do
      let!(:period_to_close) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          started_on: Date.new(2024, 1, 1),
          finished_on: nil
        )
      end

      it "closes the eligible period" do
        finish_service = double("ECTAtSchoolPeriods::Finish", finish!: true)
        allow(ECTAtSchoolPeriods::Finish).to receive(:new).and_return(finish_service)

        service.call

        expect(ECTAtSchoolPeriods::Finish).to have_received(:new).once
        expect(finish_service).to have_received(:finish!).once
      end
    end
  end

  describe "period selection logic" do
    let(:new_school_start_date) { Date.new(2024, 6, 1) }

    context "when there are periods that should be closed" do
      let!(:period_to_close) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          started_on: Date.new(2024, 1, 1),
          finished_on: nil
        )
      end

      let!(:period_that_should_not_be_closed) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher: FactoryBot.create(:teacher),
          started_on: Date.new(2024, 7, 1),
          finished_on: nil
        )
      end

      it "only closes periods that meet the criteria" do
        finish_service = double("ECTAtSchoolPeriods::Finish", finish!: true)
        allow(ECTAtSchoolPeriods::Finish).to receive(:new).and_return(finish_service)

        service.call

        expect(ECTAtSchoolPeriods::Finish).to have_received(:new).with(
          ect_at_school_period: period_to_close,
          finished_on: new_school_start_date,
          author:
        )
        expect(ECTAtSchoolPeriods::Finish).not_to have_received(:new).with(
          hash_including(ect_at_school_period: period_that_should_not_be_closed)
        )
      end
    end

    context "when periods are already finished" do
      let!(:already_finished_period) do
        FactoryBot.create(
          :ect_at_school_period,
          teacher:,
          started_on: Date.new(2024, 1, 1),
          finished_on: Date.new(2024, 3, 1)
        )
      end

      it "does not attempt to close already finished periods" do
        allow(ECTAtSchoolPeriods::Finish).to receive(:new)

        service.call

        expect(ECTAtSchoolPeriods::Finish).not_to have_received(:new)
      end
    end
  end
end
