describe Admin::CurrentTeachers do
  describe "#current" do
    let(:teacher_1) { FactoryBot.create(:teacher) }
    let(:teacher_2) { FactoryBot.create(:teacher) }
    let(:teacher_3) { FactoryBot.create(:teacher) }
    let(:appropriate_body_1) { FactoryBot.create(:appropriate_body) }
    let(:appropriate_body_2) { FactoryBot.create(:appropriate_body) }

    context "with an appropriate body" do
      before do
        FactoryBot.create(
          :induction_period,
          :ongoing,
          teacher: teacher_1,
          appropriate_body: appropriate_body_1,
          started_on: 1.month.ago.to_date,
          induction_programme: "fip"
        )
        FactoryBot.create(
          :induction_period,
          :ongoing,
          teacher: teacher_2,
          appropriate_body: appropriate_body_2,
          started_on: 1.month.ago.to_date,
          induction_programme: "fip"
        )
        FactoryBot.create(
          :induction_period,
          teacher: teacher_3,
          appropriate_body: appropriate_body_1,
          started_on: 2.months.ago.to_date,
          finished_on: 1.month.ago.to_date,
          induction_programme: "fip"
        )
      end

      it "returns teachers with ongoing induction periods for the given appropriate bodies" do
        result = described_class.new([appropriate_body_1.id]).current

        expect(result).to include(teacher_1)
        expect(result).not_to include(teacher_2)
        expect(result).not_to include(teacher_3)
      end
    end

    context "without an appropriate body" do
      before do
        FactoryBot.create(
          :induction_period,
          :ongoing,
          teacher: teacher_1,
          started_on: 1.month.ago.to_date,
          induction_programme: "fip"
        )
        FactoryBot.create(
          :induction_period,
          teacher: teacher_2,
          started_on: 2.months.ago.to_date,
          finished_on: 1.month.ago.to_date,
          induction_programme: "fip"
        )
      end

      it "returns all teachers with ongoing induction periods" do
        result = described_class.new([]).current

        expect(result).to include(teacher_1)
        expect(result).not_to include(teacher_2)
      end
    end

    context "with multiple periods" do
      before do
        FactoryBot.create(
          :induction_period,
          :ongoing,
          teacher: teacher_1,
          appropriate_body: appropriate_body_1,
          started_on: 1.month.ago.to_date,
          induction_programme: "fip"
        )

        FactoryBot.create(
          :induction_period,
          teacher: teacher_1,
          appropriate_body: appropriate_body_1,
          started_on: 3.months.ago.to_date,
          finished_on: 2.months.ago.to_date,
          induction_programme: "fip"
        )
      end

      it "returns distinct teachers" do
        result = described_class.new([appropriate_body_1.id]).current

        expect(result.count).to eq(1)
      end
    end
  end
end
