RSpec.describe Metadata::Handlers::Teacher do
  let(:instance) { described_class.new(teacher1) }

  let!(:teacher1) { FactoryBot.create(:teacher) }

  let!(:school1) { FactoryBot.create(:school) }
  let!(:school_partnership1) { FactoryBot.create(:school_partnership, school: school1) }
  let(:lead_provider1) { school_partnership1.lead_provider }

  include_context "supports refreshing all metadata", :teacher, Teacher do
    let(:object) { teacher1 }
  end

  describe ".destroy_all_metadata!", :with_metadata do
    subject(:destroy_all_metadata) { described_class.destroy_all_metadata! }

    before { instance.refresh_metadata! }

    it "destroys all metadata for the teacher" do
      expect { destroy_all_metadata }.to change(Metadata::TeacherLeadProvider, :count).from(1).to(0)
    end
  end

  describe "#refresh_metadata!" do
    subject(:refresh_metadata) { instance.refresh_metadata! }

    describe "TeacherLeadProvider" do
      include_context "supports tracking metadata upsert changes", Metadata::TeacherLeadProvider do
        let(:handler) { instance }

        def perform_refresh_metadata
          refresh_metadata
        end
      end

      it "creates metadata for all combinations of the teacher and lead providers" do
        FactoryBot.create_list(:lead_provider, 2)

        expect { refresh_metadata }.to change(Metadata::TeacherLeadProvider, :count).by(LeadProvider.count)
      end

      context "two training periods for different lead providers" do
        let!(:school_partnership2) { FactoryBot.create(:school_partnership, school: school1) }
        let(:lead_provider2) { school_partnership2.lead_provider }

        let!(:ect_at_school_period1) do
          FactoryBot.create(
            :ect_at_school_period,
            school: school1,
            teacher: teacher1,
            started_on: 1.year.ago,
            finished_on: Date.current
          )
        end
        let!(:ect_training_period1) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            started_on: ect_at_school_period1.started_on,
            finished_on: (ect_at_school_period1.started_on + 30.days),
            ect_at_school_period: ect_at_school_period1,
            school_partnership: school_partnership1
          )
        end
        let!(:ect_training_period2) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            started_on: (ect_at_school_period1.started_on + 31.days),
            finished_on: ect_at_school_period1.finished_on,
            ect_at_school_period: ect_at_school_period1,
            school_partnership: school_partnership2
          )
        end

        let!(:mentor_at_school_period1) do
          FactoryBot.create(
            :mentor_at_school_period,
            school: school1,
            teacher: teacher1,
            started_on: 1.year.ago,
            finished_on: Date.current
          )
        end
        let!(:mentor_training_period1) do
          FactoryBot.create(
            :training_period,
            :for_mentor,
            started_on: mentor_at_school_period1.started_on,
            finished_on: (mentor_at_school_period1.started_on + 30.days),
            mentor_at_school_period: mentor_at_school_period1,
            school_partnership: school_partnership1
          )
        end
        let!(:mentor_training_period2) do
          FactoryBot.create(
            :training_period,
            :for_mentor,
            started_on: (mentor_at_school_period1.started_on + 31.days),
            finished_on: mentor_at_school_period1.finished_on,
            mentor_at_school_period: mentor_at_school_period1,
            school_partnership: school_partnership2
          )
        end

        it "creates metadata for both lead providers" do
          refresh_metadata

          metadata1 = Metadata::TeacherLeadProvider.where(lead_provider: lead_provider1).sole
          expect(metadata1).to have_attributes(
            teacher: teacher1,
            lead_provider: lead_provider1,
            latest_ect_training_period: ect_training_period1,
            latest_ect_contract_period: ect_training_period1.contract_period,
            latest_mentor_training_period: mentor_training_period1,
            latest_mentor_contract_period: mentor_training_period1.contract_period,
            api_mentor_id: nil
          )

          metadata2 = Metadata::TeacherLeadProvider.where(lead_provider: lead_provider2).sole
          expect(metadata2).to have_attributes(
            teacher: teacher1,
            lead_provider: lead_provider2,
            latest_ect_training_period: ect_training_period2,
            latest_ect_contract_period: ect_training_period2.contract_period,
            latest_mentor_training_period: mentor_training_period2,
            latest_mentor_contract_period: mentor_training_period2.contract_period,
            api_mentor_id: nil
          )
        end
      end

      context "two training periods, one starting in the future" do
        let!(:ect_at_school_period1) do
          FactoryBot.create(
            :ect_at_school_period,
            school: school1,
            teacher: teacher1,
            started_on: 30.days.ago,
            finished_on: 1.year.from_now
          )
        end
        let!(:ect_training_period1) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            started_on: ect_at_school_period1.started_on,
            finished_on: 10.days.ago,
            ect_at_school_period: ect_at_school_period1,
            school_partnership: school_partnership1
          )
        end
        let!(:ect_training_period2) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            started_on: 10.days.from_now,
            finished_on: ect_at_school_period1.finished_on,
            ect_at_school_period: ect_at_school_period1,
            school_partnership: school_partnership1
          )
        end

        let!(:mentor_at_school_period1) do
          FactoryBot.create(
            :mentor_at_school_period,
            school: school1,
            teacher: teacher1,
            started_on: 30.days.ago,
            finished_on: 1.year.from_now
          )
        end
        let!(:mentor_training_period1) do
          FactoryBot.create(
            :training_period,
            :for_mentor,
            started_on: mentor_at_school_period1.started_on,
            finished_on: 5.days.ago,
            mentor_at_school_period: mentor_at_school_period1,
            school_partnership: school_partnership1
          )
        end
        let!(:mentor_training_period2) do
          FactoryBot.create(
            :training_period,
            :for_mentor,
            started_on: 15.days.from_now,
            finished_on: mentor_at_school_period1.finished_on,
            mentor_at_school_period: mentor_at_school_period1,
            school_partnership: school_partnership1
          )
        end

        it "creates metadata with the training period starting in the future" do
          refresh_metadata

          metadata = Metadata::TeacherLeadProvider.where(lead_provider: lead_provider1).sole
          expect(metadata).to have_attributes(
            teacher: teacher1,
            lead_provider: lead_provider1,
            latest_ect_training_period: ect_training_period2,
            latest_ect_contract_period: ect_training_period2.contract_period,
            latest_mentor_training_period: mentor_training_period2,
            latest_mentor_contract_period: mentor_training_period2.contract_period,
            api_mentor_id: nil
          )
        end
      end

      context "ect without mentor" do
        let!(:ect_at_school_period1) do
          FactoryBot.create(
            :ect_at_school_period,
            school: school1,
            teacher: teacher1
          )
        end
        let!(:ect_training_period1) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            started_on: ect_at_school_period1.started_on,
            finished_on: ect_at_school_period1.finished_on,
            ect_at_school_period: ect_at_school_period1,
            school_partnership: school_partnership1
          )
        end

        it "creates metadata with ect but no mentor training period" do
          refresh_metadata

          metadata = Metadata::TeacherLeadProvider.where(lead_provider: lead_provider1).sole
          expect(metadata).to have_attributes(
            teacher: teacher1,
            lead_provider: lead_provider1,
            latest_ect_training_period: ect_training_period1,
            latest_ect_contract_period: ect_training_period1.contract_period,
            latest_mentor_training_period: nil,
            latest_mentor_contract_period: nil,
            api_mentor_id: nil
          )
        end
      end

      context "teacher without any training periods" do
        it "creates metadata with nil latest training periods and api_mentor_id" do
          refresh_metadata

          metadata = Metadata::TeacherLeadProvider.where(lead_provider: lead_provider1).sole
          expect(metadata).to have_attributes(
            teacher: teacher1,
            lead_provider: lead_provider1,
            latest_ect_training_period: nil,
            latest_ect_contract_period: nil,
            latest_mentor_training_period: nil,
            latest_mentor_contract_period: nil,
            api_mentor_id: nil
          )
        end
      end

      context "when the latest ECT training period has mentorship periods" do
        let!(:ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            school: school1,
            teacher: teacher1,
            started_on: 1.year.ago,
            finished_on: nil
          )
        end
        let!(:mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            school: school1,
            started_on: 1.year.ago,
            finished_on: nil
          )
        end
        let!(:ect_training_period1) do
          FactoryBot.create(
            :training_period,
            :for_ect,
            started_on: ect_at_school_period.started_on + 1.month,
            finished_on: nil,
            ect_at_school_period:,
            school_partnership: school_partnership1
          )
        end
        let!(:latest_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on: ect_training_period1.started_on + 1.month,
            finished_on: nil
          )
        end

        before do
          # Previous mentorship period.
          FactoryBot.create(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: mentor_at_school_period,
            started_on: latest_mentorship_period.started_on - 1.month,
            finished_on: latest_mentorship_period.started_on
          )

          # Previous ECT training period.
          FactoryBot.create(
            :training_period,
            :for_ect,
            started_on: ect_at_school_period.started_on,
            finished_on: ect_training_period1.started_on,
            ect_at_school_period:,
            school_partnership: school_partnership1
          )
        end

        it "creates metadata with the correct/latest api_mentor_id" do
          refresh_metadata

          metadata = Metadata::TeacherLeadProvider.where(teacher: teacher1, lead_provider: lead_provider1).sole
          expect(metadata).to have_attributes(
            teacher: teacher1,
            lead_provider: lead_provider1,
            api_mentor_id: latest_mentorship_period.mentor.teacher.api_id
          )
        end
      end

      describe "#involved_in_school_transfer" do
        subject(:metadata) do
          Metadata::TeacherLeadProvider.where(lead_provider: lead_provider1).sole
        end

        context "when Teacher has some school transfers" do
          before do
            allow(Teachers::SchoolTransfers::History)
              .to receive(:transfers_for)
              .and_return(double(any?: true))

            refresh_metadata
          end

          it { is_expected.to be_involved_in_school_transfer }
        end

        context "when Teacher has no school transfers" do
          before do
            allow(Teachers::SchoolTransfers::History)
              .to receive(:transfers_for)
              .and_return(double(any?: false))

            refresh_metadata
          end

          it { is_expected.not_to be_involved_in_school_transfer }
        end
      end
    end
  end
end
