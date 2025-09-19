RSpec.describe Metadata::Handlers::Teacher do
  let(:instance) { described_class.new(teacher) }
  let!(:teacher) { FactoryBot.create(:teacher) }

  include_context "supports refreshing all metadata", :teacher, Teacher do
    let(:object) { teacher }
  end

  describe ".destroy_all_metadata!" do
    subject(:destroy_all_metadata) { described_class.destroy_all_metadata! }

    it "destroys all metadata for the teacher" do
      expect { destroy_all_metadata }.to change(Metadata::Teacher, :count).from(1).to(0)
    end
  end

  describe "#refresh_metadata!" do
    subject(:refresh_metadata) { instance.refresh_metadata! }

    describe "Teacher" do
      before { Metadata::Teacher.destroy_all }

      include_context "supports tracking metadata upsert changes", Metadata::Teacher do
        let(:handler) { instance }

        def perform_refresh_metadata
          refresh_metadata
        end
      end

      it "creates metadata" do
        expect { refresh_metadata }.to change(Metadata::Teacher, :count).by(1)
      end

      describe "created metadata attributes" do
        before { refresh_metadata }

        it { expect(Metadata::Teacher.last).to have_attributes(teacher:, induction_started_on: nil, induction_finished_on: nil) }

        context "when there is an induction period without an outcome" do
          let!(:induction_period) { FactoryBot.create(:induction_period, started_on: 1.year.ago, finished_on: 1.month.ago, teacher:) }

          it { expect(Metadata::Teacher.last).to have_attributes(teacher:, induction_started_on: induction_period.started_on, induction_finished_on: nil) }
        end

        context "when there is an induction period with an outcome" do
          let!(:induction_period) { FactoryBot.create(:induction_period, :pass, started_on: 1.year.ago, finished_on: 1.month.ago, teacher:) }

          it { expect(Metadata::Teacher.last).to have_attributes(teacher:, induction_started_on: induction_period.started_on, induction_finished_on: induction_period.finished_on) }
        end

        context "when there are multiple induction periods, all without an outcome" do
          let!(:earliest_induction_period) { FactoryBot.create(:induction_period, started_on: 6.months.ago, finished_on: 3.months.ago, teacher:) }
          let!(:latest_induction_period) { FactoryBot.create(:induction_period, started_on: 3.months.ago, finished_on: 1.day.ago, teacher:) }

          it { expect(Metadata::Teacher.last).to have_attributes(teacher:, induction_started_on: earliest_induction_period.started_on, induction_finished_on: nil) }
        end

        context "when there are multiple induction periods, with and without outcomes" do
          let!(:earliest_induction_period) { FactoryBot.create(:induction_period, started_on: 6.months.ago, finished_on: 3.months.ago, teacher:) }
          let!(:latest_induction_period) { FactoryBot.create(:induction_period, :pass, started_on: 3.months.ago, finished_on: 1.day.ago, teacher:) }

          it { expect(Metadata::Teacher.last).to have_attributes(teacher:, induction_started_on: earliest_induction_period.started_on, induction_finished_on: latest_induction_period.finished_on) }
        end
      end

      context "when metadata already exists" do
        before { instance.refresh_metadata! }

        it "does not create metadata" do
          expect { refresh_metadata }.not_to change(Metadata::Teacher, :count)
        end

        it "updates the metadata when the induction period changes" do
          induction_period = FactoryBot.create(:induction_period, :pass, teacher:, started_on: 1.month.ago, finished_on: 1.day.ago)

          Metadata::Teacher.bypass_update_restrictions { teacher.metadata.update!(induction_started_on: nil, induction_finished_on: nil) }

          expect { refresh_metadata }.to change { teacher.reload.metadata.induction_started_on }.from(nil).to(induction_period.started_on)
            .and change { teacher.reload.metadata.induction_finished_on }.from(nil).to(induction_period.finished_on)
        end

        it "does not update the metadata if no changes are made" do
          expect { refresh_metadata }.not_to(change { teacher.reload.metadata.attributes })
        end
      end
    end
  end
end
