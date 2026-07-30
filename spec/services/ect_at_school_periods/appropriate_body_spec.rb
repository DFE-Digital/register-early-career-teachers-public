RSpec.describe ECTAtSchoolPeriods::AppropriateBody do
  subject(:service) { described_class.new(ect_at_school_period) }

  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      school_reported_appropriate_body:,
      started_on: 1.year.ago,
      finished_on: 1.month.ago
    )
  end

  describe "#name" do
    subject(:name) { service.name }

    context "when there is a school reported appropriate body" do
      let(:school_reported_appropriate_body) do
        FactoryBot.create(:appropriate_body_period)
      end

      context "and there is no induction period" do
        let!(:induction_period) { nil }

        it { is_expected.to eq(school_reported_appropriate_body.name) }
      end

      context "and there is an induction period but it is not ongoing" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.started_on,
            finished_on: ect_at_school_period.started_on + 3.months
          )
        end

        it { is_expected.to eq(school_reported_appropriate_body.name) }
      end

      context "and there is an ongoing induction period but it started " \
              "before the ECT joined the school" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            :unfinished,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.started_on.prev_day
          )
        end

        it { is_expected.to eq(school_reported_appropriate_body.name) }
      end

      context "and there is an ongoing induction period but it started " \
              "after the ECT left the school" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            :unfinished,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.finished_on.next_day
          )
        end

        it { is_expected.to eq(school_reported_appropriate_body.name) }
      end

      context "and there is an ongoing induction period that started " \
              "while the ECT was at the school" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            :unfinished,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.started_on
          )
        end

        it { is_expected.to eq(induction_period.appropriate_body_period.name) }
      end
    end

    context "when there is not a school reported appropriate body" do
      let(:school_reported_appropriate_body) { nil }

      context "and there is no induction period" do
        let!(:induction_period) { nil }

        it { is_expected.to eq("Not reported") }
      end

      context "and there is an induction period but it is not ongoing" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.started_on,
            finished_on: ect_at_school_period.started_on + 3.months
          )
        end

        it { is_expected.to eq("Not reported") }
      end

      context "and there is an ongoing induction period but it started " \
              "before the ECT joined the school" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            :unfinished,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.started_on.prev_day
          )
        end

        it { is_expected.to eq("Not reported") }
      end

      context "and there is an ongoing induction period but it started " \
              "after the ECT left the school" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            :unfinished,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.finished_on.next_day
          )
        end

        it { is_expected.to eq("Not reported") }
      end

      context "and there is an ongoing induction period that started " \
              "while the ECT was at the school" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            :unfinished,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.started_on
          )
        end

        it { is_expected.to eq(induction_period.appropriate_body_period.name) }
      end
    end
  end

  describe "#from_induction?" do
    let(:school_reported_appropriate_body) { nil }

    context "where there is no induction period" do
      let!(:induction_period) { nil }

      it { is_expected.not_to be_from_induction }
    end

    context "where there is an induction period but it is not ongoing" do
      let!(:induction_period) do
        FactoryBot.create(
          :induction_period,
          teacher: ect_at_school_period.teacher,
          started_on: ect_at_school_period.started_on,
          finished_on: ect_at_school_period.started_on + 3.months
        )
      end

      it { is_expected.not_to be_from_induction }
    end

    context "and there is an ongoing induction period but it started " \
            "before the ECT joined the school" do
      let!(:induction_period) do
        FactoryBot.create(
          :induction_period,
          :unfinished,
          teacher: ect_at_school_period.teacher,
          started_on: ect_at_school_period.started_on.prev_day
        )
      end

      it { is_expected.not_to be_from_induction }
    end

    context "and there is an ongoing induction period but it started " \
            "after the ECT left the school" do
      let!(:induction_period) do
        FactoryBot.create(
          :induction_period,
          :unfinished,
          teacher: ect_at_school_period.teacher,
          started_on: ect_at_school_period.finished_on.next_day
        )
      end

      it { is_expected.not_to be_from_induction }
    end

    context "and there is an ongoing induction period that started " \
            "while the ECT was at the school" do
      let!(:induction_period) do
        FactoryBot.create(
          :induction_period,
          :unfinished,
          teacher: ect_at_school_period.teacher,
          started_on: ect_at_school_period.started_on
        )
      end

      it { is_expected.to be_from_induction }
    end
  end

  describe "#from_school?" do
    context "when there is a school reported appropriate body" do
      let(:school_reported_appropriate_body) do
        FactoryBot.create(:appropriate_body_period)
      end

      context "and there is no induction period" do
        let!(:induction_period) { nil }

        it { is_expected.to be_from_school }
      end

      context "and there is an induction period but it is not ongoing" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.started_on,
            finished_on: ect_at_school_period.started_on + 3.months
          )
        end

        it { is_expected.to be_from_school }
      end

      context "and there is an ongoing induction period but it started " \
              "before the ECT joined the school" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            :unfinished,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.started_on.prev_day
          )
        end

        it { is_expected.to be_from_school }
      end

      context "and there is an ongoing induction period but it started " \
              "after the ECT left the school" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            :unfinished,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.finished_on.next_day
          )
        end

        it { is_expected.to be_from_school }
      end

      context "and there is an ongoing induction period that started " \
              "while the ECT was at the school" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            :unfinished,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.started_on
          )
        end

        it { is_expected.not_to be_from_school }
      end
    end

    context "when there is not a school reported appropriate body" do
      let(:school_reported_appropriate_body) { nil }

      context "and there is no induction period" do
        let!(:induction_period) { nil }

        it { is_expected.not_to be_from_school }
      end

      context "and there is an induction period but it is not ongoing" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.started_on,
            finished_on: ect_at_school_period.started_on + 3.months
          )
        end

        it { is_expected.not_to be_from_school }
      end

      context "and there is an ongoing induction period but it started " \
              "before the ECT joined the school" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            :unfinished,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.started_on.prev_day
          )
        end

        it { is_expected.not_to be_from_school }
      end

      context "and there is an ongoing induction period but it started " \
              "after the ECT left the school" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            :unfinished,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.finished_on.next_day
          )
        end

        it { is_expected.not_to be_from_school }
      end

      context "and there is an ongoing induction period that started " \
              "while the ECT was at the school" do
        let!(:induction_period) do
          FactoryBot.create(
            :induction_period,
            :unfinished,
            teacher: ect_at_school_period.teacher,
            started_on: ect_at_school_period.started_on
          )
        end

        it { is_expected.not_to be_from_school }
      end
    end
  end
end
