RSpec.describe API::Teachers::Query, :with_metadata do
  it_behaves_like "a query that avoids includes" do
    before { FactoryBot.create(:teacher) }
  end

  describe "preloading relationships" do
    shared_examples "preloaded associations" do
      it { expect(result.association(:teacher_id_changes)).to be_loaded }
      it { expect(result.association(:started_induction_period)).to be_loaded }
      it { expect(result.association(:finished_induction_period)).to be_loaded }
      it { expect(result.association(:lead_provider_metadata)).to be_loaded }
      it { expect(result.association(:earliest_ect_at_school_period)).to be_loaded }
      it { expect(result.association(:earliest_mentor_at_school_period)).to be_loaded }

      it { expect(result.lead_provider_metadata.map { |metadata| metadata.association(:latest_ect_training_period) }).to all(be_loaded) }
      it { expect(result.lead_provider_metadata.map { |metadata| metadata.association(:latest_mentor_training_period) }).to all(be_loaded) }

      it "preloads latest_ect_training_period and latest_mentor_training_period associations" do
        latest_training_periods = result.lead_provider_metadata
          .map { |it| [it.latest_ect_training_period, it.latest_mentor_training_period] }
          .flatten
          .compact

        expect(latest_training_periods).not_to be_empty

        latest_training_periods.each do |training_period|
          expect(training_period.association(:school_partnership)).to be_loaded
          expect(training_period.school_partnership.association(:school)).to be_loaded
          expect(training_period.school_partnership.association(:lead_provider_delivery_partnership)).to be_loaded

          expect(training_period.school_partnership.lead_provider_delivery_partnership.association(:delivery_partner)).to be_loaded
          expect(training_period.school_partnership.lead_provider_delivery_partnership.association(:active_lead_provider)).to be_loaded

          if training_period.for_ect?
            expect(training_period.association(:ect_at_school_period)).to be_loaded
          elsif training_period.for_mentor?
            expect(training_period.association(:mentor_at_school_period)).to be_loaded
          end
        end
      end
    end

    let(:instance) { described_class.new }
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:, started_on: 1.year.ago, finished_on: nil) }
    let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:, started_on: 1.year.ago, finished_on: nil) }
    let!(:latest_ect_training_period) { FactoryBot.create(:training_period, :for_ect, ect_at_school_period:, started_on: 1.month.ago, finished_on: nil) }
    let!(:latest_mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period:, started_on: 1.month.ago, finished_on: nil) }

    describe "#teachers" do
      subject(:result) do
        instance.teachers.first
      end

      include_context "preloaded associations"
    end

    describe "#teacher_by_api_id" do
      subject(:result) { instance.teacher_by_api_id(teacher.api_id) }

      include_context "preloaded associations"
    end

    describe "#teacher_by_id" do
      subject(:result) { instance.teacher_by_id(teacher.id) }

      include_context "preloaded associations"
    end
  end

  describe "#teachers" do
    it "returns all teachers" do
      teachers = FactoryBot.create_list(:teacher, 3)
      query = described_class.new

      expect(query.teachers).to match_array(teachers)
    end

    it "orders teachers by created_at in ascending order" do
      teacher1 = travel_to(2.days.ago) { FactoryBot.create(:teacher) }
      teacher2 = travel_to(1.day.ago) { FactoryBot.create(:teacher) }
      teacher3 = FactoryBot.create(:teacher)

      query = described_class.new

      expect(query.teachers).to eq([teacher1, teacher2, teacher3])
    end

    describe "filtering" do
      describe "by `lead_provider`" do
        let(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing) }
        let!(:teacher1) { training_period.trainee.teacher }
        let!(:teacher2) { FactoryBot.create(:training_period, :for_ect, :ongoing).trainee.teacher }
        let!(:teacher3) { FactoryBot.create(:training_period, :for_ect, :ongoing).trainee.teacher }

        context "when `lead_provider` param is omitted" do
          it "returns all teachers" do
            expect(described_class.new.teachers).to contain_exactly(teacher1, teacher2, teacher3)
          end
        end

        it "filters by `lead_provider`" do
          lead_provider_id = training_period.lead_provider.id
          query = described_class.new(lead_provider_id:)

          expect(query.teachers).to contain_exactly(teacher1)
        end

        it "returns empty if no teachers are found for the given `lead_provider`" do
          query = described_class.new(lead_provider_id: FactoryBot.create(:lead_provider).id)

          expect(query.teachers).to be_empty
        end

        it "does not filter by `lead_provider` if an empty string is supplied" do
          query = described_class.new(lead_provider_id: " ")

          expect(query.teachers).to contain_exactly(teacher1, teacher2, teacher3)
        end
      end

      describe "by `contract_period_years`" do
        let(:contract_period1) { FactoryBot.create(:contract_period) }
        let(:contract_period2) { FactoryBot.create(:contract_period) }
        let(:contract_period3) { FactoryBot.create(:contract_period) }
        let(:school_partnership1) { FactoryBot.create(:school_partnership, active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: contract_period1)) }
        let(:school_partnership2) { FactoryBot.create(:school_partnership, active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: contract_period2)) }
        let(:school_partnership3) { FactoryBot.create(:school_partnership, active_lead_provider: FactoryBot.create(:active_lead_provider, contract_period: contract_period3)) }
        let!(:teacher1) { FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership: school_partnership1).trainee.teacher }
        let!(:teacher2) { FactoryBot.create(:training_period, :for_mentor, :ongoing, school_partnership: school_partnership2).trainee.teacher }
        let!(:teacher3) { FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership: school_partnership3).trainee.teacher }

        context "when `contract_period_years` param is omitted" do
          it "returns all teachers" do
            expect(described_class.new.teachers).to contain_exactly(teacher1, teacher2, teacher3)
          end
        end

        it "filters by `contract_period_years`" do
          query = described_class.new(contract_period_years: contract_period2.year.to_s)

          expect(query.teachers).to contain_exactly(teacher2)
        end

        it "filters by multiple `contract_period_years`" do
          query1 = described_class.new(contract_period_years: [contract_period1.year, contract_period2.year])
          expect(query1.teachers).to contain_exactly(teacher1, teacher2)

          query2 = described_class.new(contract_period_years: [contract_period2.year.to_s, contract_period3.year.to_s])
          expect(query2.teachers).to contain_exactly(teacher2, teacher3)
        end

        it "returns no delivery partners if no `contract_period_years` are found" do
          query = described_class.new(contract_period_years: "0000")

          expect(query.teachers).to be_empty
        end

        it "ignores invalid `contract_period_years`" do
          query = described_class.new(contract_period_years: [contract_period1.year, 1099])

          expect(query.teachers).to contain_exactly(teacher1)
        end

        it "does not filter by `contract_period_years` if blank" do
          query = described_class.new(contract_period_years: " ")

          expect(query.teachers).to contain_exactly(teacher1, teacher2, teacher3)
        end
      end

      describe "by `api_from_teacher_id`" do
        let(:teacher1) { FactoryBot.create(:training_period, :for_ect, :ongoing).trainee.teacher }
        let(:teacher2) { FactoryBot.create(:training_period, :for_mentor, :ongoing).trainee.teacher }
        let(:teacher3) { FactoryBot.create(:training_period, :for_ect, :ongoing).trainee.teacher }
        let!(:teacher_id_change1) { FactoryBot.create(:teacher_id_change, teacher: teacher1, api_from_teacher_id: teacher2.api_id) }
        let!(:teacher_id_change2) { FactoryBot.create(:teacher_id_change, teacher: teacher2, api_from_teacher_id: teacher3.api_id) }
        let!(:teacher_id_change3) { FactoryBot.create(:teacher_id_change, teacher: teacher3, api_from_teacher_id: teacher1.api_id) }

        context "when `api_from_teacher_id` param is omitted" do
          it "returns all teachers" do
            expect(described_class.new.teachers).to contain_exactly(teacher1, teacher2, teacher3)
          end
        end

        it "filters by `api_from_teacher_id`" do
          api_from_teacher_id = teacher_id_change2.api_from_teacher_id
          query = described_class.new(api_from_teacher_id:)

          expect(query.teachers).to contain_exactly(teacher2)
        end

        it "returns empty if no teachers are found for the given `api_from_teacher_id`" do
          query = described_class.new(api_from_teacher_id: SecureRandom.uuid)

          expect(query.teachers).to be_empty
        end

        it "does not filter by `api_from_teacher_id` if an empty string is supplied" do
          query = described_class.new(api_from_teacher_id: " ")

          expect(query.teachers).to contain_exactly(teacher1, teacher2, teacher3)
        end
      end

      describe "by `training_status`" do
        let(:school_partnership) { FactoryBot.create(:school_partnership) }
        let!(:deferred_teacher) { FactoryBot.create(:training_period, :for_ect, :ongoing, :deferred, school_partnership:).trainee.teacher }
        let!(:withdrawn_teacher) { FactoryBot.create(:training_period, :for_mentor, :ongoing, :withdrawn, school_partnership:).trainee.teacher }
        let!(:active_teacher) { FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership:).trainee.teacher }

        context "when `training_status` param is omitted" do
          it "returns all teachers" do
            query = described_class.new

            expect(query.teachers).to contain_exactly(deferred_teacher, withdrawn_teacher, active_teacher)
          end
        end

        it "filters by deferred `training_status`" do
          query = described_class.new(training_status: :deferred)

          expect(query.teachers).to contain_exactly(deferred_teacher)
        end

        it "filters by withdrawn `training_status`" do
          query = described_class.new(training_status: :withdrawn)

          expect(query.teachers).to contain_exactly(withdrawn_teacher)
        end

        it "filters by active `training_status`" do
          query = described_class.new(training_status: :active)

          expect(query.teachers).to contain_exactly(active_teacher)
        end

        it "returns no teachers if an invalid `training_status` is supplied" do
          query = described_class.new(training_status: "invalid")

          expect(query.teachers).to be_empty
        end

        it "does not filter by `training_status` if an empty string is supplied" do
          query = described_class.new(training_status: " ")

          expect(query.teachers).to contain_exactly(deferred_teacher, withdrawn_teacher, active_teacher)
        end
      end

      describe "by `training_status` when a teacher has multiple training periods" do
        let(:teacher) { FactoryBot.create(:teacher) }
        let(:school_partnership) { FactoryBot.create(:school_partnership) }
        let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, teacher:) }
        let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, teacher:) }
        let!(:deferred_training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, :deferred, school_partnership:, ect_at_school_period:) }
        let!(:withdrawn_training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, :withdrawn, school_partnership:, mentor_at_school_period:) }

        it "returns the teacher if any of the latest training periods match the filter" do
          query = described_class.new(training_status: :deferred)

          expect(query.teachers).to contain_exactly(teacher)

          query = described_class.new(training_status: :withdrawn)

          expect(query.teachers).to contain_exactly(teacher)
        end

        it "does not return the teacher if none of the latest training periods match the filter" do
          query = described_class.new(training_status: :active)

          expect(query.teachers).to be_empty
        end
      end

      describe "by `updated_since`" do
        it "filters by `updated_since`" do
          FactoryBot.create(:teacher).tap { it.update(updated_at: 2.days.ago) }
          teacher2 = FactoryBot.create(:teacher)

          query = described_class.new(updated_since: 1.day.ago)

          expect(query.teachers).to contain_exactly(teacher2)
        end

        it "does not filter by `updated_since`` if omitted" do
          teacher1 = FactoryBot.create(:teacher).tap { it.update(updated_at: 1.week.ago) }
          teacher2 = FactoryBot.create(:teacher).tap { it.update(updated_at: 2.weeks.ago) }

          expect(described_class.new.teachers).to contain_exactly(teacher1, teacher2)
        end

        it "does not filter by `updated_since` if blank" do
          teacher1 = FactoryBot.create(:teacher).tap { it.update(updated_at: 1.week.ago) }
          teacher2 = FactoryBot.create(:teacher).tap { it.update(updated_at: 2.weeks.ago) }

          query = described_class.new(updated_since: " ")

          expect(query.teachers).to contain_exactly(teacher1, teacher2)
        end
      end
    end

    describe "ordering" do
      let!(:teacher1) { FactoryBot.create(:training_period, :for_ect, :ongoing).trainee.teacher }
      let!(:teacher2) { travel_to(1.day.ago) { FactoryBot.create(:training_period, :for_mentor, :ongoing).trainee.teacher } }

      describe "default order" do
        it "returns teachers ordered by created_at, in ascending order" do
          query = described_class.new
          expect(query.teachers).to eq([teacher2, teacher1])
        end
      end

      describe "order by created_at, in descending order" do
        it "returns teachers in correct order" do
          query = described_class.new(sort: { created_at: :desc })
          expect(query.teachers).to eq([teacher1, teacher2])
        end
      end

      describe "order by updated_at, in ascending order" do
        before { teacher2.update!(updated_at: 1.day.from_now) }

        it "returns teachers in correct order" do
          query = described_class.new(sort: { updated_at: :asc })
          expect(query.teachers).to eq([teacher1, teacher2])
        end
      end

      describe "order by updated_at, in descending order" do
        it "returns teachers in correct order" do
          query = described_class.new(sort: { updated_at: :desc })
          expect(query.teachers).to eq([teacher1, teacher2])
        end
      end
    end
  end

  describe "#teacher_by_api_id" do
    it "returns the teachers for a given id" do
      teacher = FactoryBot.create(:teacher)
      query = described_class.new

      expect(query.teacher_by_api_id(teacher.api_id)).to eq(teacher)
    end

    it "raises an error if the teacher does not exist" do
      query = described_class.new

      expect { query.teacher_by_api_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the teacher is not in the filtered query" do
      teacher1 = FactoryBot.create(:training_period, :for_ect, :ongoing).trainee.teacher
      teacher2 = FactoryBot.create(:training_period, :for_mentor, :ongoing).trainee.teacher
      lead_provider_id = teacher1.lead_provider_metadata.first.lead_provider_id

      query = described_class.new(lead_provider_id:)

      expect { query.teacher_by_api_id(teacher2.api_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an api_id is not supplied" do
      expect { described_class.new.teacher_by_api_id(nil) }.to raise_error(ArgumentError, "api_id needed")
    end
  end

  describe "#teacher_by_id" do
    it "returns the teacher for a given id" do
      teacher = FactoryBot.create(:teacher)
      query = described_class.new

      expect(query.teacher_by_id(teacher.id)).to eq(teacher)
    end

    it "raises an error if the teacher does not exist" do
      query = described_class.new

      expect { query.teacher_by_id("XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the teacher is not in the filtered query" do
      teacher1 = FactoryBot.create(:training_period, :for_ect, :ongoing).trainee.teacher
      teacher2 = FactoryBot.create(:training_period, :for_mentor, :ongoing).trainee.teacher
      lead_provider_id = teacher1.lead_provider_metadata.first.lead_provider_id

      query = described_class.new(lead_provider_id:)

      expect { query.teacher_by_id(teacher2.api_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if an id is not supplied" do
      expect { described_class.new.teacher_by_id(nil) }.to raise_error(ArgumentError, "id needed")
    end
  end
end
