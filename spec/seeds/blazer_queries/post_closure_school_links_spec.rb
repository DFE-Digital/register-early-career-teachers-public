require Rails.root.join("db/seeds/blazer_queries/post_closure_school_links")

RSpec.describe BlazerQueries::PostClosureSchoolLinks do
  let(:closed_on) { Date.new(2026, 6, 30) } # a summer date, so it stores as 23:00 the day before

  describe ".definitions" do
    subject(:definitions) { described_class.definitions }

    it "defines the school level and teacher level queries" do
      expect(definitions.pluck(:name)).to contain_exactly(
        described_class::SCHOOLS_QUERY_NAME,
        described_class::TEACHERS_QUERY_NAME
      )
    end

    it "only counts links that would have stopped us closing the school" do
      expect(definitions.pluck(:statement)).to all(
        include("ls.link_type IN ('Successor - amalgamated', 'Successor - merged', 'Successor - Split School', 'Successor')")
      )
    end

    it "produces statements that are valid SQL against the schema" do
      definitions.each do |definition|
        expect { ActiveRecord::Base.connection.select_all(definition[:statement]) }
          .not_to raise_error
      end
    end
  end

  describe "the closed schools query" do
    subject(:rows) { rows_for(described_class::SCHOOLS_QUERY_NAME) }

    context "when a school we closed has since been given a successor link" do
      let!(:school) { close_school!(urn: 100_001) }
      let!(:link) { link_to_successor!(school, link_type: GIAS::SchoolLink::SUCCESSOR_MERGED) }

      before { finish_at_closure!(school) }

      it "returns the closed school with the link that arrived too late" do
        expect(rows.fetch(0)).to include(
          "closed_school_urn" => 100_001,
          "closed_school_name" => school.gias_school.name,
          "closed_on" => closed_on,
          "link_type" => GIAS::SchoolLink::SUCCESSOR_MERGED,
          "link_urn" => link.link_urn,
          "link_school_name" => link.to_gias_school.name,
          "link_school_status" => "open",
          "link_school_registered_in_rect" => true,
          "teachers_affected" => 1
        )
      end
    end

    context "when the closure finished some periods and deleted others" do
      let!(:school) { close_school!(urn: 100_002) }

      before do
        link_to_successor!(school)
        2.times { finish_at_closure!(school, role: :ect) }
        finish_at_closure!(school, role: :mentor)
        delete_unstarted_at_closure!(school, role: :ect)
        delete_unstarted_at_closure!(school, role: :mentor)
      end

      it "counts the teachers, the ECT periods and the mentor periods" do
        expect(rows.fetch(0)).to include(
          "teachers_affected" => 5,
          "ect_periods_affected" => 3,
          "mentor_periods_affected" => 2
        )
      end
    end

    context "when the link arrived three weeks after the closure" do
      let!(:school) { close_school!(urn: 100_003) }

      before do
        link = link_to_successor!(school)
        link.update_columns(created_at: closed_on + 21.days, updated_at: closed_on + 21.days)
        finish_at_closure!(school)
      end

      it "reports the gap in days" do
        expect(rows.fetch(0)).to include("days_between_closure_and_link" => 21)
      end
    end

    context "when some of the affected teachers have been registered again" do
      let!(:school) { close_school!(urn: 100_040) }

      before do
        link = link_to_successor!(school)
        register_at!(School.find_by(urn: link.link_urn), teacher: finish_at_closure!(school).teacher)
        register_at!(FactoryBot.create(:school), teacher: finish_at_closure!(school).teacher)
        finish_at_closure!(school)
      end

      it "counts them apart from the teachers still needing action" do
        expect(rows.fetch(0)).to include(
          "teachers_affected" => 3,
          "teachers_registered_elsewhere_since" => 2,
          "teachers_registered_at_linked_school_since" => 1
        )
      end
    end

    context "when the teachers had already left before the school closed" do
      before do
        school = close_school!(urn: 100_004)
        link_to_successor!(school)
        finish_at_closure!(school, finished_on: closed_on - 1.month)
      end

      it { is_expected.to be_empty }
    end

    context "when no link has arrived since the closure" do
      before do
        school = close_school!(urn: 100_010)
        finish_at_closure!(school)
      end

      it { is_expected.to be_empty }
    end

    context "when the only link to arrive was a predecessor" do
      before do
        school = close_school!(urn: 100_011)
        link_to_successor!(school, link_type: GIAS::SchoolLink::PREDECESSOR_LINK_TYPES.first)
        finish_at_closure!(school)
      end

      it { is_expected.to be_empty }
    end

    context "when the only link to arrive would not have changed how we closed the school" do
      before do
        school = close_school!(urn: 100_012)
        link_to_successor!(school, link_type: "Sixth Form Centre Link")
        finish_at_closure!(school)
      end

      it { is_expected.to be_empty }
    end

    context "when we did not close the school ourselves" do
      before do
        school = close_school!(urn: 100_020, record_closure: false)
        link_to_successor!(school)
        finish_at_closure!(school)
      end

      it { is_expected.to be_empty }
    end

    context "when nobody was registered at the school when it closed" do
      before do
        school = close_school!(urn: 100_030)
        link_to_successor!(school)
      end

      it { is_expected.to be_empty }
    end
  end

  describe "the affected teachers query" do
    subject(:rows) { rows_for(described_class::TEACHERS_QUERY_NAME) }

    context "when the closure finished an ECT period and a mentor period" do
      let!(:school) { close_school!(urn: 200_001) }
      let!(:link) { link_to_successor!(school) }
      let!(:ect_period) do
        finish_at_closure!(school, teacher: FactoryBot.create(:teacher, trn: "1234567", corrected_name: "Alice Adams"))
      end

      before do
        finish_at_closure!(
          school,
          role: :mentor,
          teacher: FactoryBot.create(:teacher, trs_first_name: "Bob", trs_last_name: "Best", corrected_name: nil)
        )
      end

      it "returns a row for each role" do
        expect(rows.pluck("role")).to contain_exactly("ECT", "Mentor")
      end

      it "describes the teacher, their period and the school they should have moved to" do
        expect(rows.find { it["role"] == "ECT" }).to include(
          "closed_school_urn" => 200_001,
          "link_urn" => link.link_urn,
          "teacher_id" => ect_period.teacher_id,
          "trn" => "1234567",
          "teacher_name" => "Alice Adams",
          "what_happened" => "period finished on the closure date",
          "period_started_on" => closed_on - 1.year,
          "period_finished_on" => closed_on,
          "registered_elsewhere_since" => false,
          "registered_at_linked_school_since" => false
        )
      end

      it "falls back to the TRS name when the teacher has no corrected name" do
        expect(rows.find { it["role"] == "Mentor" }).to include("teacher_name" => "Bob Best")
      end
    end

    context "when the closure deleted a period that had not started" do
      let!(:school) { close_school!(urn: 200_002) }
      let!(:teacher) { delete_unstarted_at_closure!(school, role: :mentor) }

      before { link_to_successor!(school) }

      it "returns the teacher with no period dates" do
        expect(rows.fetch(0)).to include(
          "teacher_id" => teacher.id,
          "role" => "Mentor",
          "what_happened" => "period deleted before it started",
          "period_started_on" => nil,
          "period_finished_on" => nil
        )
      end
    end

    context "when the teacher has since been registered at the linked school" do
      let!(:school) { close_school!(urn: 200_003) }

      before do
        link = link_to_successor!(school)
        register_at!(School.find_by(urn: link.link_urn), teacher: finish_at_closure!(school).teacher)
      end

      it "flags them as needing no further action" do
        expect(rows.fetch(0)).to include(
          "registered_elsewhere_since" => true,
          "registered_at_linked_school_since" => true
        )
      end
    end
  end

  describe ".sync!" do
    it "creates each query as an active query against the main data source" do
      expect { described_class.sync! }.to change(Blazer::Query, :count).by(2)

      query = Blazer::Query.find_by(name: described_class::SCHOOLS_QUERY_NAME)
      expect(query).to have_attributes(status: "active", data_source: "main")
      expect(query.statement).to be_present
    end

    it "is idempotent and refreshes the stored statement on re-run" do
      described_class.sync!
      Blazer::Query.find_by(name: described_class::TEACHERS_QUERY_NAME).update!(statement: "SELECT 1;")

      expect { described_class.sync! }.not_to change(Blazer::Query, :count)

      refreshed = Blazer::Query.find_by(name: described_class::TEACHERS_QUERY_NAME)
      expect(refreshed.statement).to include("FROM late_links l")
    end
  end

  def rows_for(name)
    statement = described_class.definitions.find { |definition| definition[:name] == name }.fetch(:statement)
    ActiveRecord::Base.connection.select_all(statement).to_a
  end

  def close_school!(urn:, closed_on: self.closed_on, record_closure: true)
    gias_school = FactoryBot.create(:gias_school, urn:, status: "closed", closed_on:)
    school = FactoryBot.create(:school, urn:, gias_school:, create_contract_period: false)

    if record_closure
      FactoryBot.create(
        :event,
        event_type: "school_closed",
        author_type: "system",
        school:,
        happened_at: closed_on,
        metadata: { gias_school_urn: urn, gias_school_name: gias_school.name }
      )
    end

    school
  end

  def link_to_successor!(school, link_type: GIAS::SchoolLink::SUCCESSOR, successor_urn: nil, status: "open", registered: true)
    successor_urn ||= school.urn + 1
    successor_gias_school = FactoryBot.create(:gias_school, urn: successor_urn, status:)
    FactoryBot.create(:school, urn: successor_urn, gias_school: successor_gias_school, create_contract_period: false) if registered

    FactoryBot.create(
      :gias_school_link,
      from_gias_school: school.gias_school,
      to_gias_school: successor_gias_school,
      link_type:,
      link_date: closed_on - 1.week
    )
  end

  def finish_at_closure!(school, role: :ect, finished_on: closed_on, **attrs)
    factory = (role == :ect) ? :ect_at_school_period : :mentor_at_school_period

    FactoryBot.create(factory, school:, started_on: closed_on - 1.year, finished_on:, **attrs)
  end

  def delete_unstarted_at_closure!(school, role: :ect, teacher: FactoryBot.create(:teacher))
    event_type = (role == :ect) ? "teacher_ect_at_school_period_deleted" : "teacher_mentor_at_school_period_deleted"

    FactoryBot.create(:event, event_type:, author_type: "system", school:, teacher:, happened_at: closed_on)
    teacher
  end

  def register_at!(school, teacher:, started_on: closed_on + 1.day)
    FactoryBot.create(:ect_at_school_period, teacher:, school:, started_on:, finished_on: nil)
  end
end
