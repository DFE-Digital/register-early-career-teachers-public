require Rails.root.join("db/scripts/populate_appropriate_body_period_dates")

RSpec.describe PopulateAppropriateBodyPeriodDates do
  subject(:script) { described_class.new }

  let(:csv_path) { Rails.root.join("tmp/appropriate_body_period_dates.csv") }

  after { FileUtils.rm_f(csv_path) }

  def create_appropriate_body_period(trait, **attributes)
    FactoryBot.build(:appropriate_body_period, trait,
                     started_on: nil,
                     finished_on: nil,
                     **attributes).tap { |period| period.save!(validate: false) }
  end

  describe "#call" do
    context "when no interval is set" do
      let!(:appropriate_body_period) do
        create_appropriate_body_period(body_type, **existing_dates).tap do |period|
          period.provisioning_school.gias_school.update!(school_dates) if school_dates.any?
        end
      end

      let(:existing_dates) { {} }
      let(:school_dates) { {} }

      before { script.call }

      context "with a teaching school hub" do
        let(:body_type) { :teaching_school_hub }

        context "without any school dates" do
          it "starts an ongoing period when hubs were introduced" do
            expect(appropriate_body_period.reload).to have_attributes(
              started_on: Date.new(2021, 9, 1),
              finished_on: nil
            )
          end
        end
      end

      context "with a teaching school" do
        let(:body_type) { :teaching_school }

        context "without any school dates" do
          it "starts the period when they were introduced and finishes when they were retired" do
            expect(appropriate_body_period.reload).to have_attributes(
              started_on: Date.new(1999, 9, 1),
              finished_on: Date.new(2021, 8, 31)
            )
          end
        end

        context "when the provisioning school opened after 1999" do
          let(:school_dates) { { opened_on: Date.new(2015, 9, 1) } }

          it "starts the period when the school opened" do
            expect(appropriate_body_period.reload).to have_attributes(
              started_on: school_dates[:opened_on],
              finished_on: Date.new(2021, 8, 31)
            )
          end
        end

        context "when the provisioning school closed before 2021" do
          let(:school_dates) { { closed_on: Date.new(2018, 8, 31) } }

          it "ends the period when the school closed" do
            expect(appropriate_body_period.reload).to have_attributes(
              started_on: Date.new(1999, 9, 1),
              finished_on: school_dates[:closed_on]
            )
          end
        end
      end

      context "with a local authority" do
        let(:body_type) { :local_authority }

        it "starts the period when they were introduced and finishes when they were retired" do
          expect(appropriate_body_period.reload).to have_attributes(
            started_on: Date.new(2012, 8, 31),
            finished_on: Date.new(2023, 9, 1)
          )
        end

        context "when a start date already exists" do
          let(:existing_dates) { { started_on: Date.new(2001, 1, 1) } }

          it "is a no-op" do
            expect(appropriate_body_period.reload).to have_attributes(
              started_on: Date.new(2001, 1, 1),
              finished_on: nil
            )
          end
        end

        context "when an end date already exists" do
          let(:existing_dates) { { finished_on: Date.new(2023, 1, 1) } }

          it "overwrites the dates" do
            expect(appropriate_body_period.reload).to have_attributes(
              started_on: Date.new(2012, 8, 31),
              finished_on: Date.new(2023, 9, 1)
            )
          end
        end
      end
    end

    context "with national bodies" do
      let!(:istip) { create_appropriate_body_period(:istip) }
      let!(:esp) { create_appropriate_body_period(:esp) }
      let!(:nta) { create_appropriate_body_period(:nta) }

      before { script.call }

      it "populates each body's start and end date" do
        expect(istip.reload).to have_attributes(
          started_on: Date.new(2011, 8, 31),
          finished_on: nil
        )
        expect(esp.reload).to have_attributes(
          started_on: Date.new(2024, 4, 1),
          finished_on: nil
        )
        expect(nta.reload).to have_attributes(
          started_on: Date.new(2013, 8, 31),
          finished_on: Date.new(2024, 9, 1)
        )
      end
    end

    context "when any date is not valid" do
      let!(:local_authority) { create_appropriate_body_period(:local_authority) }
      let!(:teaching_school) { create_appropriate_body_period(:teaching_school) }

      before { teaching_school.provisioning_school.gias_school.update!(opened_on: Date.new(2023, 9, 1)) }

      it "aborts the transaction" do
        expect { script.call }.to raise_error(ActiveRecord::RecordInvalid, /The end date must be later than the start date/)
        expect(local_authority.reload).to have_attributes(started_on: nil, finished_on: nil)
        expect(teaching_school.reload).to have_attributes(started_on: nil, finished_on: nil)
        expect(File).not_to exist(csv_path)
      end
    end

    context "when the script is called twice" do
      let!(:appropriate_body_period) { create_appropriate_body_period(:teaching_school_hub) }

      it "is a no-op" do
        script.call
        after_first_run = appropriate_body_period.reload.attributes
        script.call

        expect(appropriate_body_period.reload.attributes).to eq(after_first_run)
      end
    end
  end

  describe "reporting" do
    let!(:appropriate_body_period) { create_appropriate_body_period(:local_authority) }

    before { script.call }

    it "generates a CSV" do
      rows = CSV.read(csv_path, headers: true)
      expect(rows.headers).to eq(%w[id name body_type provisioning_school_urn started_on finished_on])
      expect(rows.map(&:to_h)).to contain_exactly(
        {
          "id" => appropriate_body_period.id.to_s,
          "name" => appropriate_body_period.name,
          "body_type" => "local_authority",
          "provisioning_school_urn" => nil,
          "started_on" => "2012-08-31",
          "finished_on" => "2023-09-01"
        }
      )
    end
  end
end
