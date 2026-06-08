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
    it { is_expected.to have_many(:predecessor_links).with_foreign_key(:link_urn).with_primary_key(:urn).class_name("GIAS::SchoolLink").inverse_of(:to_gias_school) }
    it { is_expected.to have_many(:successors).through(:gias_school_links).source(:to_gias_school).class_name("GIAS::School") }
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

        before { FactoryBot.create(:gias_school_link, from_gias_school: gias_school, to_gias_school: successor) }

        it { is_expected.to eq(successor) }
      end

      context "when the school has more than one successor" do
        before do
          FactoryBot.create(:gias_school_link, from_gias_school: gias_school)
          FactoryBot.create(:gias_school_link, from_gias_school: gias_school)
        end

        it { is_expected.to be_nil }
      end

      context "when the school has no successors" do
        it { is_expected.to be_nil }
      end

      context "when the school has a predecessor but no successors" do
        before { FactoryBot.create(:gias_school_link, to_gias_school: gias_school) }

        it { is_expected.to be_nil }
      end
    end
  end

  describe "scopes" do
    let(:gias_school_with_successor) { FactoryBot.create(:gias_school_link).from_gias_school }
    let(:gias_school_without_successor) { FactoryBot.create(:gias_school) }
    let(:open_gias_school) { FactoryBot.create(:gias_school, status: :open) }
    let(:closed_gias_school) { FactoryBot.create(:gias_school, status: :closed) }

    describe ".ordered_by_name" do
      it "amends the query so results are ordered by name, ascending" do
        expect(GIAS::School.ordered_by_name.to_sql).to end_with('ORDER BY "gias_schools"."name" ASC')
      end
    end

    describe ".openable" do
      subject { GIAS::School.openable }

      let(:open_gias_school_with_predecessors) { FactoryBot.create(:gias_school_link).to_gias_school }
      let(:open_gias_school_with_successors) { FactoryBot.create(:gias_school_link).from_gias_school }

      before do
        open_gias_school_with_predecessors.update!(status: :open)
        open_gias_school_with_successors.update!(status: :open)
      end

      it { is_expected.to include(open_gias_school) }
      it { is_expected.not_to include(closed_gias_school) }
      it { is_expected.not_to include(open_gias_school_with_predecessors) }
      it { is_expected.not_to include(open_gias_school_with_successors) }
    end

    describe ".closeable" do
      subject { GIAS::School.closeable }

      let(:closed_gias_school_with_sucessors) do
        FactoryBot.create(:gias_school_link,
                          from_gias_school: FactoryBot.create(:gias_school, status: :closed)).from_gias_school
      end

      it { is_expected.to include(closed_gias_school) }
      it { is_expected.not_to include(open_gias_school) }
      it { is_expected.not_to include(closed_gias_school_with_sucessors) }
    end

    describe ".replaceable" do
      subject { GIAS::School.replaceable }

      let(:closed_gias_school_with_one_successor) do
        FactoryBot.create(:gias_school_link,
                          from_gias_school: FactoryBot.create(:gias_school, status: :closed)).from_gias_school
      end

      let(:open_gias_school_with_one_successor) do
        FactoryBot.create(:gias_school_link,
                          from_gias_school: FactoryBot.create(:gias_school, status: :open)).from_gias_school
      end

      let(:closed_gias_school_with_multiple_successors) { FactoryBot.create(:gias_school, status: :closed) }
      let(:open_gias_school_with_multiple_successors) { FactoryBot.create(:gias_school, status: :open) }

      before do
        FactoryBot.create(:gias_school_link, from_gias_school: closed_gias_school_with_multiple_successors)
        FactoryBot.create(:gias_school_link, from_gias_school: closed_gias_school_with_multiple_successors)
        FactoryBot.create(:gias_school_link, from_gias_school: open_gias_school_with_multiple_successors)
        FactoryBot.create(:gias_school_link, from_gias_school: open_gias_school_with_multiple_successors)
      end

      it { is_expected.to include(closed_gias_school_with_one_successor) }
      it { is_expected.to include(closed_gias_school_with_multiple_successors) }
      it { is_expected.not_to include(open_gias_school_with_one_successor) }
      it { is_expected.not_to include(open_gias_school_with_multiple_successors) }
      it { is_expected.not_to include(open_gias_school) }
      it { is_expected.not_to include(closed_gias_school) }
    end
  end
end
