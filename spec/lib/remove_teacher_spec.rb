RSpec.describe RemoveTeacher, :aggregate_failures do
  subject(:remove_teacher) { described_class.new(teacher.id) }

  let!(:teacher) { FactoryBot.create(:teacher) }

  it "#has_many_associations" do
    expect(remove_teacher.has_many_associations).to eq(%i[
      appropriate_bodies
      ect_at_school_periods
      ect_training_periods
      events
      induction_extensions
      induction_periods
      lead_provider_metadata
      mentor_at_school_periods
      mentor_training_periods
      teacher_id_changes
      teacher_migration_failures
    ])
  end

  describe "#call" do
    let!(:first_appropriate_body) { FactoryBot.create(:appropriate_body) }

    let!(:second_appropriate_body) { FactoryBot.create(:appropriate_body) }

    let!(:induction_period) do
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body: first_appropriate_body)
    end

    let!(:ongoing_induction_period) do
      FactoryBot.create(:induction_period, :ongoing,
                        teacher:,
                        appropriate_body: second_appropriate_body,
                        started_on: 1.week.ago)
    end

    let!(:other_teacher) { FactoryBot.create(:teacher) }

    let!(:passed_induction_period) do
      FactoryBot.create(:induction_period, :pass,
                        teacher: other_teacher,
                        appropriate_body: second_appropriate_body)
    end

    before do
      FactoryBot.create(:event,
                        teacher:,
                        appropriate_body: first_appropriate_body)

      FactoryBot.create(:event,
                        teacher:,
                        appropriate_body: second_appropriate_body)

      FactoryBot.create(:event,
                        teacher: other_teacher,
                        appropriate_body: second_appropriate_body)
    end

    describe "unrelated records" do
      before do
        FactoryBot.create(:api_token)
        FactoryBot.create(:contract_period)
        FactoryBot.create(:delivery_partner)
        FactoryBot.create(:gias_school)
        FactoryBot.create(:lead_provider)
        FactoryBot.create(:school)
        FactoryBot.create(:statement)
        FactoryBot.create(:user)
      end

      it do
        expect {
          remove_teacher.call
        }.to not_change(AppropriateBody, :count)
          .and not_change(API::Token, :count)
          .and not_change(ContractPeriod, :count)
          .and not_change(DeliveryPartner, :count)
          .and not_change(GIAS::School, :count)
          .and not_change(LeadProvider, :count)
          .and not_change(School, :count)
          .and not_change(Statement, :count)
          .and not_change(User, :count)
      end
    end

    it "removes teacher and training data" do
      # Original
      expect(Teacher.count).to eq(2)
      expect(InductionPeriod.count).to eq(3)
      expect(AppropriateBody.count).to eq(2)
      expect(Event.count).to eq(3)

      # Remove
      remove_teacher.call

      # Targeted
      expect { Teacher.find(teacher.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { InductionPeriod.find(induction_period.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { InductionPeriod.find(ongoing_induction_period.id) }.to raise_error(ActiveRecord::RecordNotFound)

      # Ignored
      expect(Teacher.find(other_teacher.id)).to be_a(Teacher)
      expect(InductionPeriod.find(passed_induction_period.id)).to be_an(InductionPeriod)

      # Result
      expect(Teacher.count).to eq(1)
      expect(InductionPeriod.count).to eq(1)
      expect(AppropriateBody.count).to eq(2)
      expect(Event.count).to eq(1)
    end
  end
end
