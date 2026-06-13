describe GIAS::School do
  describe "db table" do
    it "has name 'gias_schools'" do
      expect(described_class.table_name).to eq("gias_schools")
    end
  end

  describe "db columns" do
    it { is_expected.to have_db_column(:address_line1).of_type(:string) }
    it { is_expected.to have_db_column(:address_line2).of_type(:string) }
    it { is_expected.to have_db_column(:address_line3).of_type(:string) }
    it { is_expected.to have_db_column(:administrative_district_name).of_type(:string) }
    it { is_expected.to have_db_column(:closed_on).of_type(:date) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:eligible).of_type(:boolean).with_options(null: false) }
    it { is_expected.to have_db_column(:establishment_number).of_type(:integer) }
    it { is_expected.to have_db_column(:in_england).of_type(:boolean).with_options(null: false) }
    it { is_expected.to have_db_column(:local_authority_code).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:local_authority_name).of_type(:string) }
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:opened_on).of_type(:date) }
    it { is_expected.to have_db_column(:phase_name).of_type(:string) }
    it { is_expected.to have_db_column(:postcode).of_type(:string) }
    it { is_expected.to have_db_column(:primary_contact_email).of_type(:string) }
    it { is_expected.to have_db_column(:secondary_contact_email).of_type(:string) }
    it { is_expected.to have_db_column(:section_41_approved).of_type(:boolean).with_options(null: false) }
    it { is_expected.to have_db_column(:status).of_type(:enum).with_options(default: "open", null: false) }
    it { is_expected.to have_db_column(:type_name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:ukprn).of_type(:integer) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:urn).of_type(:integer).with_options(primary: true) }
    it { is_expected.to have_db_column(:website).of_type(:string) }
  end

  describe "declarative touch" do
    let(:instance) { FactoryBot.create(:gias_school, :with_school) }
    let(:target) { instance.contract_period_metadata }

    before { Metadata::Handlers::School.new(instance.school).refresh_metadata! }

    it_behaves_like "a declarative touch model", when_changing: %i[name], timestamp_attribute: :api_updated_at
  end

  describe "db indexes" do
    it { is_expected.to have_db_index(:name) }
    it { is_expected.to have_db_index(:ukprn).unique }
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:status)
                       .with_values(open: "open",
                                    closed: "closed",
                                    proposed_to_close: "proposed_to_close",
                                    proposed_to_open: "proposed_to_open")
                       .backed_by_column_of_type(:enum)
                       .with_suffix
                       .validating
    }
  end

  describe "associations" do
    it { is_expected.to have_one(:school).with_primary_key(:urn).with_foreign_key(:urn).inverse_of(:gias_school) }
    it { is_expected.to have_many(:gias_school_links).with_foreign_key(:urn).dependent(:destroy).class_name("GIAS::SchoolLink").inverse_of(:from_gias_school) }
    it { is_expected.to have_many(:contract_period_metadata).class_name("Metadata::SchoolContractPeriod").through(:school) }
    it { is_expected.to have_many(:successor_links).class_name("GIAS::SchoolLink").with_foreign_key(:urn).with_primary_key(:urn).conditions(link_type: GIAS::SchoolLink::SUCCESSOR_LINK_TYPES) }
    it { is_expected.to have_many(:predecessor_links).class_name("GIAS::SchoolLink").with_foreign_key(:urn).with_primary_key(:urn).conditions(link_type: GIAS::SchoolLink::PREDECESSOR_LINK_TYPES) }
    it { is_expected.to have_many(:successors).through(:successor_links).source(:to_gias_school).class_name("GIAS::School") }
    it { is_expected.to have_many(:predecessors).through(:predecessor_links).source(:from_gias_school).class_name("GIAS::School") }
  end

  describe "validations" do
    subject { FactoryBot.create(:gias_school) }

    it { is_expected.to validate_numericality_of(:local_authority_code).only_integer }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:establishment_number).only_integer.allow_nil }

    it {
      is_expected.to validate_inclusion_of(:type_name)
                       .in_array(GIAS::Types::ALL_TYPES)
                       .with_message("is not a valid school type")
    }

    it { is_expected.to validate_numericality_of(:ukprn).only_integer.allow_nil }
    it { is_expected.to validate_uniqueness_of(:ukprn).allow_nil }
    it { is_expected.to validate_numericality_of(:urn).only_integer }
    it { is_expected.to validate_uniqueness_of(:urn) }
  end

  describe "instance methods" do
    describe "#open?" do
      context "when the status is :open" do
        subject { FactoryBot.create(:gias_school, status: :open) }

        it { is_expected.to be_open }
      end

      context "when the status is :proposed_to_close" do
        subject { FactoryBot.create(:gias_school, status: :proposed_to_close) }

        it { is_expected.to be_open }
      end

      context "when the status is not :open or :proposed_to_close" do
        subject { FactoryBot.create(:gias_school, :not_open) }

        it { is_expected.not_to be_open }
      end
    end

    describe "#closed?" do
      context "when the status is :closed" do
        subject { FactoryBot.create(:gias_school, status: :closed) }

        it { is_expected.to be_closed }
      end

      context "when the status is :proposed_to_open" do
        subject { FactoryBot.create(:gias_school, status: :proposed_to_open) }

        it { is_expected.to be_closed }
      end

      context "when the status is not :closed or :proposed_to_open" do
        subject { FactoryBot.create(:gias_school, :open) }

        it { is_expected.not_to be_closed }
      end
    end

    describe "#successor" do
      subject { gias_school.successor }

      let(:gias_school) { FactoryBot.create(:gias_school) }

      context "when the school has one successor" do
        let(:successor) { FactoryBot.create(:gias_school) }

        before { FactoryBot.create(:gias_school_link, :successor, from_gias_school: gias_school, to_gias_school: successor) }

        it { is_expected.to eq(successor) }
      end

      context "when the school has two successor links" do
        before do
          FactoryBot.create(:gias_school_link, :successor_split, from_gias_school: gias_school)
          FactoryBot.create(:gias_school_link, :successor_split, from_gias_school: gias_school)
        end

        it { is_expected.to be_nil }
      end

      context "when the school has several links only one of which is a successor" do
        let(:successor) { FactoryBot.create(:gias_school) }

        before do
          FactoryBot.create(:gias_school_link, :successor, from_gias_school: gias_school, to_gias_school: successor)
          FactoryBot.create(:gias_school_link, :predecessor, from_gias_school: gias_school)
        end

        it { is_expected.to eq(successor) }
      end

      context "when the school has no links" do
        it { is_expected.to be_nil }
      end

      context "when the school has no successor links" do
        before { FactoryBot.create(:gias_school_link, :predecessor, from_gias_school: gias_school) }

        it { is_expected.to be_nil }
      end
    end

    describe "#closeable?" do
      subject { gias_school }

      let(:gias_school) { FactoryBot.create(:gias_school, status: :closed, closed_on:) }
      let(:closed_on) { Date.current }

      context "when the school has closed today, has no successors and no closure event recorded" do
        it { is_expected.to be_closeable }
      end

      context "when the school has closed today but has a successor" do
        before do
          FactoryBot.create(:gias_school_link, :successor, from_gias_school: gias_school)
        end

        it { is_expected.not_to be_closeable }
      end

      context "when the school has closed today but has a closure event recorded" do
        let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :closed) }

        before do
          FactoryBot.create(:event, event_type: :school_closed, school: gias_school.school)
        end

        it { is_expected.not_to be_closeable }
      end

      context "when the school is not closed" do
        let(:gias_school) { FactoryBot.create(:gias_school, status: :proposed_to_close) }

        it { is_expected.not_to be_closeable }
      end

      context "when the school closed in the past but it has not yet been recorded" do
        let(:closed_on) { Date.yesterday }

        it { is_expected.to be_closeable }
      end

      context "when the school closes in the future" do
        let(:closed_on) { Date.tomorrow }

        it { is_expected.not_to be_closeable }
      end
    end

    describe "#openable?" do
      subject { gias_school }

      let(:gias_school) { FactoryBot.create(:gias_school, status: :open, opened_on:) }
      let(:opened_on) { Date.current }

      context "when the school is open, has no predecessors or successors and no associated school" do
        it { is_expected.to be_openable }
      end

      context "when the school is open but has a predecessor" do
        before do
          FactoryBot.create(:gias_school_link, :predecessor, from_gias_school: gias_school)
        end

        it { is_expected.not_to be_openable }
      end

      context "when the school is open but has a successor" do
        before do
          FactoryBot.create(:gias_school_link, :successor, from_gias_school: gias_school)
        end

        it { is_expected.not_to be_openable }
      end

      context "when the school is open but already has an associated school" do
        let(:gias_school) { FactoryBot.create(:gias_school, :with_school, status: :open) }

        it { is_expected.not_to be_openable }
      end

      context "when the school is not open" do
        let(:gias_school) { FactoryBot.create(:gias_school, status: :closed) }

        it { is_expected.not_to be_openable }
      end

      context "when the school opens in the future" do
        let(:opened_on) { Date.tomorrow }

        it { is_expected.not_to be_openable }
      end

      context "when the school opened in the past but it has not yet been associated with a school record" do
        let(:opened_on) { Date.yesterday }

        it { is_expected.to be_openable }
      end
    end

    describe "#replaceable?" do
      subject { gias_school }

      context "when the school is closed" do
        let(:gias_school) { FactoryBot.create(:gias_school, status: :closed, closed_on:) }
        let(:closed_on) { Date.current }

        it { is_expected.not_to be_replaceable }

        context "when there is a unique successor" do
          let(:successor) { FactoryBot.create(:gias_school, status: :open, opened_on:) }
          let(:opened_on) { Date.current }

          before do
            FactoryBot.create(:gias_school_link, :successor_unique, from_gias_school: gias_school, to_gias_school: successor)
          end

          context "when the successor is open without an associated school" do
            it { is_expected.to be_replaceable }
          end

          context "when the school closed in the past but it has not yet been recorded and the successor is open without an associated school" do
            let(:closed_on) { Date.yesterday }

            it { is_expected.to be_replaceable }
          end

          context "when the successor is not open" do
            let(:successor) { FactoryBot.create(:gias_school, status: :proposed_to_open, opened_on:) }

            it { is_expected.not_to be_replaceable }
          end

          context "when the successor already has an associated school" do
            let(:successor) { FactoryBot.create(:gias_school, :with_school, status: :open, opened_on:) }

            it { is_expected.not_to be_replaceable }
          end

          context "when the successor opens in the future" do
            let(:opened_on) { Date.tomorrow }

            it { is_expected.not_to be_replaceable }
          end

          context "when the successor opened in the past but it has not yet been associated with a school record" do
            let(:opened_on) { Date.yesterday }

            it { is_expected.to be_replaceable }
          end
        end

        context "when there is a non-unique successor" do
          let(:successor) { FactoryBot.create(:gias_school, status: :open, opened_on: Date.current) }

          context "when the school is being merged" do
            before do
              FactoryBot.create(:gias_school_link, :successor_merged, from_gias_school: gias_school, to_gias_school: successor)
            end

            it { is_expected.not_to be_replaceable }
          end

          context "when the school is being amalgamated" do
            before do
              FactoryBot.create(:gias_school_link, :successor_amalgamated, from_gias_school: gias_school, to_gias_school: successor)
            end

            it { is_expected.not_to be_replaceable }
          end

          context "when the school is being split" do
            before do
              FactoryBot.create(:gias_school_link, :successor_split, from_gias_school: gias_school, to_gias_school: successor)
            end

            it { is_expected.not_to be_replaceable }
          end

          context "when there are multiple successors" do
            before do
              FactoryBot.create(:gias_school_link, :successor_unique, from_gias_school: gias_school, to_gias_school: successor)
              FactoryBot.create(:gias_school_link, :successor, from_gias_school: gias_school)
            end

            it { is_expected.not_to be_replaceable }
          end
        end
      end

      context "when the school is not closed" do
        let(:gias_school) { FactoryBot.create(:gias_school, status: :proposed_to_close) }

        it { is_expected.not_to be_replaceable }
      end

      context "when the school closes in the future" do
        let(:gias_school) { FactoryBot.create(:gias_school, status: :closed, closed_on: Date.tomorrow) }

        it { is_expected.not_to be_replaceable }
      end
    end

    describe "#school_not_yet_opened?" do
      subject { gias_school.school_not_yet_opened? }

      let(:gias_school) { FactoryBot.create(:gias_school) }

      context "when the school does not have a school record" do
        it { is_expected.to be true }
      end

      context "when the school has a school record" do
        let(:gias_school) { FactoryBot.create(:gias_school, :with_school) }

        it { is_expected.to be false }
      end
    end

    describe "#closed_on_or_before_today?" do
      subject { gias_school.closed_on_or_before_today? }

      let(:gias_school) { FactoryBot.create(:gias_school, closed_on:) }

      context "when the school does not have a closed_on date" do
        let(:closed_on) { nil }

        it { is_expected.to be_falsy }
      end

      context "when the school closed yesterday" do
        let(:closed_on) { Date.yesterday }

        it { is_expected.to be_truthy }
      end

      context "when the school closes today" do
        let(:closed_on) { Date.current }

        it { is_expected.to be_truthy }
      end

      context "when the school closes tomorrow" do
        let(:closed_on) { Date.tomorrow }

        it { is_expected.to be_falsy }
      end
    end

    describe "#opened_on_or_before_today?" do
      subject { gias_school.opened_on_or_before_today? }

      let(:gias_school) { FactoryBot.create(:gias_school, opened_on:) }

      context "when the school does not have an opened_on date" do
        let(:opened_on) { nil }

        it { is_expected.to be_falsy }
      end

      context "when the school opened yesterday" do
        let(:opened_on) { Date.yesterday }

        it { is_expected.to be_truthy }
      end

      context "when the school opens today" do
        let(:opened_on) { Date.current }

        it { is_expected.to be_truthy }
      end

      context "when the school opens tomorrow" do
        let(:opened_on) { Date.tomorrow }

        it { is_expected.to be_falsy }
      end
    end
  end

  describe "scopes" do
    describe ".ordered_by_name" do
      it "amends the query so results are ordered by name, ascending" do
        expect(GIAS::School.ordered_by_name.to_sql).to end_with('ORDER BY "gias_schools"."name" ASC')
      end
    end
  end
end
