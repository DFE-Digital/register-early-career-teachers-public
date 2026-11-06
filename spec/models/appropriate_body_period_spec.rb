describe AppropriateBodyPeriod do
  describe "enums" do
    it do
      expect(subject).to define_enum_for(:body_type)
                           .with_values({ local_authority: "local_authority",
                                          national: "national",
                                          teaching_school: "teaching_school",
                                          teaching_school_hub: "teaching_school_hub" })
                           .validating
                           .backed_by_column_of_type(:enum)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:dfe_sign_in_organisation) }
    it { is_expected.to belong_to(:provisioning_school) }
    it { is_expected.to have_many(:induction_periods) }
    it { is_expected.to have_many(:pending_induction_submissions) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:oauth_authorizations).class_name("API::OAuth::Authorization").dependent(:destroy) }
    it { is_expected.to have_many(:unclaimed_ect_at_school_periods).class_name("ECTAtSchoolPeriod").with_foreign_key(:school_reported_appropriate_body_id) }
    it { is_expected.to have_many(:region_awards).class_name("Region::Award").dependent(:destroy) }
    it { is_expected.to have_many(:regions).through(:region_awards) }
    it { is_expected.to have_many(:lead_schools).through(:region_awards).source(:school) }
  end

  describe "scopes" do
    before do
      FactoryBot.create(:appropriate_body_period, :national)
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub)
      FactoryBot.create(:appropriate_body_period, :teaching_school_hub, :inactive)
      FactoryBot.create(:appropriate_body_period, :local_authority)
    end

    it "filters by type and activity" do
      expect(described_class.national.count).to be(1)
      expect(described_class.teaching_school_hub.count).to be(2)
      expect(described_class.local_authority.count).to be(1)
      expect(described_class.active.count).to be(2)
      expect(described_class.inactive.count).to be(2)
    end
  end

  describe "predicates" do
    describe "#active?" do
      context "when `dfe_sign_in_organisation_id` is present" do
        subject(:appropriate_body_period) do
          FactoryBot.build_stubbed(
            :appropriate_body_period,
            dfe_sign_in_organisation_id: SecureRandom.uuid
          )
        end

        it { is_expected.to be_active }
      end

      context "when `dfe_sign_in_organisation_id` is missing" do
        subject(:appropriate_body_period) do
          FactoryBot.build_stubbed(
            :appropriate_body_period,
            dfe_sign_in_organisation_id: nil
          )
        end

        it { is_expected.not_to be_active }
      end
    end
  end

  describe "interval" do
    describe "date order validation" do
      subject(:appropriate_body_period) do
        FactoryBot.build(:appropriate_body_period, :teaching_school_hub, started_on:, finished_on:)
      end

      context "when the end date is before the start date" do
        let(:started_on) { Date.new(2024, 1, 1) }
        let(:finished_on) { Date.new(2023, 1, 1) }

        it { is_expected.to have_error(:finished_on, "The end date must be later than the start date (1 January 2024)") }
      end

      context "when only the start date is known" do
        let(:started_on) { Date.new(2021, 9, 1) }
        let(:finished_on) { nil }

        it { is_expected.to be_valid }
      end
    end

    describe "presence" do
      subject(:appropriate_body_period) do
        FactoryBot.build(:appropriate_body_period, body_trait, started_on:, finished_on:)
      end

      let(:started_on) { nil }
      let(:finished_on) { nil }

      %i[local_authority national teaching_school teaching_school_hub].each do |body_trait|
        context "with a #{body_trait.to_s.humanize(capitalize: false)} period" do
          let(:body_trait) { body_trait }

          it "reports the missing start date" do
            expect(appropriate_body_period).to have_error(:started_on, "can't be blank")
          end
        end
      end

      %i[local_authority teaching_school].each do |body_trait|
        context "with a #{body_trait.to_s.humanize(capitalize: false)} period that has no end date" do
          let(:body_trait) { body_trait }
          let(:started_on) { Date.new(2013, 9, 1) }

          it "reports the missing end date" do
            expect(appropriate_body_period).to have_error(:finished_on, "can't be blank")
          end
        end
      end

      %i[national teaching_school_hub].each do |body_trait|
        context "with a #{body_trait.to_s.humanize(capitalize: false)} period that has no end date" do
          let(:body_trait) { body_trait }
          let(:started_on) { Date.new(2021, 9, 1) }

          it { is_expected.to be_valid }
        end
      end
    end

    describe "overlap validation" do
      subject(:appropriate_body_period) do
        FactoryBot.build(:appropriate_body_period, :teaching_school_hub,
                         provisioning_school:,
                         started_on:,
                         finished_on:)
      end

      let(:provisioning_school) { FactoryBot.create(:school) }
      let(:started_on) { Date.new(2022, 9, 1) }
      let(:finished_on) { nil }

      context "when a teaching school hub period for the same provisioning school overlaps" do
        before do
          FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                            provisioning_school:,
                            started_on: Date.new(2021, 9, 1),
                            finished_on: Date.new(2023, 8, 31))
        end

        it "raises an error" do
          expect(appropriate_body_period).to have_error(:started_on, "Start date cannot overlap another appropriate body period")
        end
      end

      context "when the previous period for the same school ends the day before" do
        before do
          FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                            provisioning_school:,
                            started_on: Date.new(2021, 9, 1),
                            finished_on: Date.new(2023, 8, 31))
        end

        let(:started_on) { Date.new(2023, 9, 1) }

        it { is_expected.to be_valid }
      end

      context "when the overlapping period belongs to a different school" do
        before do
          FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                            started_on: Date.new(2021, 9, 1),
                            finished_on: Date.new(2023, 8, 31))
        end

        it { is_expected.to be_valid }
      end
    end

    describe "scopes" do
      let!(:current_period) do
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          started_on: Date.new(2021, 9, 1),
                          finished_on: nil)
      end
      let!(:closed_period) do
        FactoryBot.create(:appropriate_body_period, :teaching_school,
                          started_on: Date.new(2015, 9, 1),
                          finished_on: Date.new(2021, 8, 31))
      end

      it "separates finished and unfinished periods" do
        expect(described_class.unfinished).to contain_exactly(current_period)
        expect(described_class.finished).to contain_exactly(closed_period)
      end

      it "reports an open-ended period as current" do
        expect(described_class.contains_today).to contain_exactly(current_period)
      end

      it "finds the period containing a given date" do
        expect(described_class.contains_date(Date.new(2018, 1, 1))).to contain_exactly(closed_period)
      end

      it "includes the last day the appropriate body operated" do
        expect(described_class.contains_date(Date.new(2021, 8, 31))).to contain_exactly(closed_period)
      end
    end
  end

  describe "validations" do
    describe "name", skip: "during data cleanse" do
      subject(:appropriate_body_period) { FactoryBot.build(:appropriate_body_period) }

      it { is_expected.to validate_uniqueness_of(:name).allow_nil }
    end

    it "does not allow a retired type to contain today" do
      %i[local_authority teaching_school].each do |trait|
        period = FactoryBot.build(:appropriate_body_period, trait,
                                  started_on: Time.zone.today,
                                  finished_on: nil)

        expect(period).not_to be_valid
      end
    end

    context "when the type is local authority" do
      subject(:appropriate_body_period) do
        FactoryBot.build(:appropriate_body_period, :local_authority,
                         started_on:,
                         finished_on:)
      end

      let(:started_on) { Date.new(1999, 9, 1) }
      let(:finished_on) { Date.new(2024, 8, 31) }

      it { is_expected.to be_valid }

      it "requires a local authority" do
        appropriate_body_period.local_authority = nil
        expect(appropriate_body_period).to have_error(:local_authority, "can't be blank")
      end

      it "rejects a provisioning school" do
        appropriate_body_period.provisioning_school = FactoryBot.create(:school)
        expect(appropriate_body_period).to have_error(:provisioning_school, "must be blank")
      end

      it "rejects a teaching school hub" do
        appropriate_body_period.teaching_school_hub = FactoryBot.create(:teaching_school_hub)
        expect(appropriate_body_period).to have_error(:teaching_school_hub, "must be blank")
      end

      it "rejects a national body" do
        appropriate_body_period.national_body = FactoryBot.create(:national_body)
        expect(appropriate_body_period).to have_error(:national_body, "must be blank")
      end

      context "when it starts before 1 September 1999" do
        let(:started_on) { Date.new(1999, 8, 31) }

        it { is_expected.to have_error(:started_on, "Local authority appropriate bodies must start on or after 1 September 1999") }
      end

      context "when it finishes after 31 August 2024" do
        let(:finished_on) { Date.new(2024, 9, 1) }

        it { is_expected.to have_error(:finished_on, "Local authority appropriate bodies must finish on or before 31 August 2024") }
      end

      context "when it starts after 31 August 2024" do
        let(:started_on) { Date.new(2024, 9, 1) }
        let(:finished_on) { Date.new(2024, 9, 1) }

        it { is_expected.to have_error(:started_on, "A local authority appropriate body must start on or before 31 August 2024") }
      end

      context "when it starts on 31 August 2024" do
        let(:started_on) { Date.new(2024, 8, 31) }

        it { is_expected.to be_valid }
      end

      context "when both dates are unknown" do
        let(:started_on) { nil }
        let(:finished_on) { nil }

        it "is not valid, because a local authority period is a closed record" do
          expect(appropriate_body_period).to have_error(:started_on, "can't be blank")
          expect(appropriate_body_period).to have_error(:finished_on, "can't be blank")
        end
      end
    end

    context "when the type is national" do
      subject(:appropriate_body_period) { FactoryBot.build(:appropriate_body_period, :national) }

      it { is_expected.to be_valid }

      it "requires a national body" do
        appropriate_body_period.national_body = nil
        expect(appropriate_body_period).to have_error(:national_body, "can't be blank")
      end

      it "rejects a provisioning school" do
        appropriate_body_period.provisioning_school = FactoryBot.create(:school)
        expect(appropriate_body_period).to have_error(:provisioning_school, "must be blank")
      end

      it "rejects a teaching school hub" do
        appropriate_body_period.teaching_school_hub = FactoryBot.create(:teaching_school_hub)
        expect(appropriate_body_period).to have_error(:teaching_school_hub, "must be blank")
      end

      it "rejects a local authority" do
        appropriate_body_period.local_authority = FactoryBot.create(:local_authority)
        expect(appropriate_body_period).to have_error(:local_authority, "must be blank")
      end
    end

    context "when the type is teaching school hub" do
      subject(:appropriate_body_period) do
        FactoryBot.build(:appropriate_body_period, :teaching_school_hub,
                         provisioning_school:,
                         started_on:,
                         finished_on:)
      end

      let(:provisioning_school) { FactoryBot.create(:school) }
      let(:started_on) { Date.new(2021, 9, 1) }
      let(:finished_on) { nil }

      it "requires a teaching school hub" do
        appropriate_body_period.teaching_school_hub = nil
        expect(appropriate_body_period).to have_error(:teaching_school_hub, "can't be blank")
      end

      it "requires a provisioning school" do
        appropriate_body_period.provisioning_school = nil
        expect(appropriate_body_period).to have_error(:provisioning_school, "can't be blank")
      end

      it "rejects a local authority" do
        appropriate_body_period.local_authority = FactoryBot.create(:local_authority)
        expect(appropriate_body_period).to have_error(:local_authority, "must be blank")
      end

      it "rejects a national body" do
        appropriate_body_period.national_body = FactoryBot.create(:national_body)
        expect(appropriate_body_period).to have_error(:national_body, "must be blank")
      end

      context "when it starts before 1 September 2021" do
        let(:started_on) { Date.new(2021, 8, 31) }

        it { is_expected.to have_error(:started_on, "Teaching school hub appropriate bodies must start on or after 1 September 2021") }
      end

      context "when it starts on 1 September 2021" do
        it { is_expected.to be_valid }
      end

      context "when the start date is unknown" do
        let(:started_on) { nil }

        it { is_expected.to have_error(:started_on, "can't be blank") }
      end

      context "when it starts before the provisioning school opened" do
        before { provisioning_school.gias_school.update!(opened_on: Date.new(2022, 9, 1)) }

        it { is_expected.to have_error(:started_on, "The start date cannot be earlier than the school opened (1 September 2022)") }
      end

      context "when it starts on the day the provisioning school opened" do
        before { provisioning_school.gias_school.update!(opened_on: Date.new(2021, 9, 1)) }

        it { is_expected.to be_valid }
      end

      context "when the opening date of the provisioning school is unknown" do
        before { provisioning_school.gias_school.update!(opened_on: nil) }

        it { is_expected.to be_valid }
      end

      context "when it finishes, because hubs are ongoing" do
        let(:finished_on) { Date.new(2024, 9, 1) }

        it { is_expected.to be_valid }
      end

      context "when it finishes after the provisioning school closed" do
        let(:finished_on) { Date.new(2024, 9, 1) }

        before { provisioning_school.gias_school.update!(closed_on: Date.new(2024, 8, 31)) }

        it { is_expected.to have_error(:finished_on, "The end date cannot be later than the school closed (31 August 2024)") }
      end

      context "when it finishes on the day the provisioning school closed" do
        let(:finished_on) { Date.new(2024, 8, 31) }

        before { provisioning_school.gias_school.update!(closed_on: Date.new(2024, 8, 31)) }

        it { is_expected.to be_valid }
      end
    end

    context "when the type is teaching school" do
      subject(:appropriate_body_period) do
        FactoryBot.build(:appropriate_body_period, :teaching_school,
                         provisioning_school:,
                         started_on:,
                         finished_on:)
      end

      let(:provisioning_school) { FactoryBot.create(:school) }
      let(:started_on) { Date.new(2010, 9, 1) }
      let(:finished_on) { Date.new(2021, 8, 31) }

      it "requires a provisioning school" do
        appropriate_body_period.provisioning_school = nil
        expect(appropriate_body_period).to have_error(:provisioning_school, "can't be blank")
      end

      it "rejects a teaching school hub" do
        appropriate_body_period.teaching_school_hub = FactoryBot.create(:teaching_school_hub)
        expect(appropriate_body_period).to have_error(:teaching_school_hub, "must be blank")
      end

      it "rejects a local authority" do
        appropriate_body_period.local_authority = FactoryBot.create(:local_authority)
        expect(appropriate_body_period).to have_error(:local_authority, "must be blank")
      end

      it "rejects a national body" do
        appropriate_body_period.national_body = FactoryBot.create(:national_body)
        expect(appropriate_body_period).to have_error(:national_body, "must be blank")
      end

      context "when it starts before 1 September 1999" do
        let(:started_on) { Date.new(1999, 8, 31) }

        it { is_expected.to have_error(:started_on, "Teaching school appropriate bodies must start on or after 1 September 1999") }
      end

      context "when it starts on 1 September 1999" do
        let(:started_on) { Date.new(1999, 9, 1) }

        it { is_expected.to be_valid }
      end

      context "when it finishes after 31 August 2021" do
        let(:finished_on) { Date.new(2021, 9, 1) }

        it { is_expected.to have_error(:finished_on, "Teaching school appropriate bodies must finish on or before 31 August 2021") }
      end

      context "when it finishes on 31 August 2021" do
        let(:finished_on) { Date.new(2021, 8, 31) }

        it { is_expected.to be_valid }
      end

      context "when it finishes after the provisioning school closed" do
        let(:finished_on) { Date.new(2020, 9, 1) }

        before { provisioning_school.gias_school.update!(closed_on: Date.new(2020, 8, 31)) }

        it { is_expected.to have_error(:finished_on, "The end date cannot be later than the school closed (31 August 2020)") }
      end

      context "when it finishes on the day the provisioning school closed" do
        let(:finished_on) { Date.new(2020, 8, 31) }

        before { provisioning_school.gias_school.update!(closed_on: Date.new(2020, 8, 31)) }

        it { is_expected.to be_valid }
      end

      context "when the closing date of the provisioning school is unknown" do
        let(:finished_on) { Date.new(2021, 8, 31) }

        before { provisioning_school.gias_school.update!(closed_on: nil) }

        it { is_expected.to be_valid }
      end

      context "when it starts before the provisioning school opened" do
        let(:started_on) { Date.new(2010, 9, 1) }

        before { provisioning_school.gias_school.update!(opened_on: Date.new(2012, 9, 1)) }

        it { is_expected.to have_error(:started_on, "The start date cannot be earlier than the school opened (1 September 2012)") }
      end

      context "when it starts on the day the provisioning school opened" do
        let(:started_on) { Date.new(2012, 9, 1) }

        before { provisioning_school.gias_school.update!(opened_on: Date.new(2012, 9, 1)) }

        it { is_expected.to be_valid }
      end

      context "when the opening date of the provisioning school is unknown" do
        it { is_expected.to be_valid }
      end

      context "when there is no provisioning school" do
        let(:provisioning_school) { nil }

        it { is_expected.to have_error(:provisioning_school, "can't be blank") }
      end

      context "when it starts after 31 August 2021" do
        let(:started_on) { Date.new(2021, 9, 1) }

        it { is_expected.to have_error(:started_on, "Teaching school appropriate bodies must start on or before 31 August 2021") }
      end

      context "when it starts and finishes on 31 August 2021" do
        let(:started_on) { Date.new(2021, 8, 31) }

        it { is_expected.to be_valid }
      end

      context "when the start date is unknown" do
        let(:started_on) { nil }

        it { is_expected.to have_error(:started_on, "can't be blank") }
      end

      context "when the end date is unknown" do
        let(:finished_on) { nil }

        it { is_expected.to have_error(:finished_on, "can't be blank") }
      end
    end
  end

  describe "#name" do
    let(:national_body) { FactoryBot.create(:national_body) }

    it "may be omitted" do
      expect { described_class.create!(name: nil, started_on: Date.new(2021, 9, 1), body_type: "national", national_body:) }
        .to change(described_class, :count).by(1)
    end
  end

  describe "normalizing" do
    subject { FactoryBot.build(:appropriate_body_period, name: " Some appropriate body ") }

    it "removes leading and trailing spaces from the name" do
      expect(subject.name).to eql("Some appropriate body")
    end
  end

  describe "teaching school hub regional awards" do
    let(:appropriate_body_period) { FactoryBot.create(:appropriate_body_period, :teaching_school_hub) }
    let(:school) { FactoryBot.create(:school) }
    let(:region) { FactoryBot.create(:region) }
    let(:other_region) { FactoryBot.create(:region) }

    before do
      FactoryBot.create(:region_award, appropriate_body_period:, school:, region:)
      FactoryBot.create(:region_award, appropriate_body_period:, school:, region: other_region)
    end

    it "lists lead schools and regions collapsing multi-region schools" do
      expect(appropriate_body_period.lead_schools).to contain_exactly(school)
      expect(appropriate_body_period.regions).to contain_exactly(region, other_region)
    end
  end

  describe "naming a hub that runs concurrent periods" do
    let(:teaching_school_hub) { FactoryBot.create(:teaching_school_hub, name: "Acme TSH") }

    def hub_period(name:, hub: teaching_school_hub, **attributes)
      FactoryBot.build(:appropriate_body_period, :teaching_school_hub,
                       teaching_school_hub: hub,
                       provisioning_school: FactoryBot.create(:school),
                       name:,
                       **attributes)
    end

    context "when the hub has one period" do
      it "does not require a name" do
        expect(hub_period(name: nil)).to be_valid
      end

      it "allows an existing period to lose its name" do
        period = hub_period(name: "Acme TSH East")
        period.save!

        period.update!(name: nil)

        expect(period.reload.name).to be_nil
      end

      it "allows a new hub to start with an unnamed first period" do
        hub = FactoryBot.create(:teaching_school_hub, name: "New TSH")
        period = FactoryBot.build(:appropriate_body_period, :teaching_school_hub,
                                  teaching_school_hub: hub,
                                  provisioning_school: FactoryBot.create(:school),
                                  name: nil)

        period.save!

        expect(period.reload.name).to be_nil
        expect(hub.appropriate_body_periods.count).to eq(1)
      end
    end

    context "when another period for the hub overlaps it" do
      before do
        hub_period(name: "Acme TSH East",
                   started_on: Date.new(2021, 9, 1),
                   finished_on: nil).save!
      end

      it "requires a name" do
        expect(hub_period(name: nil,
                          started_on: Date.new(2022, 9, 1),
                          finished_on: nil)).to have_error(
                            :name,
                            "Another active appropriate body in the teaching school hub exists, choose a name."
                          )
      end

      it "accepts a name that tells the two periods apart" do
        expect(hub_period(name: "Acme TSH West",
                          started_on: Date.new(2022, 9, 1),
                          finished_on: nil)).to be_valid
      end

      it "stops a named period losing its name by update" do
        period = hub_period(name: "Acme TSH West",
                            started_on: Date.new(2022, 9, 1),
                            finished_on: nil)
        period.save!
        period.name = nil

        expect(period).not_to be_valid
      end
    end

    context "when the name of an earlier period is reused" do
      before do
        hub_period(name: "Acme TSH East",
                   started_on: Date.new(2021, 9, 1),
                   finished_on: Date.new(2021, 12, 31)).save!
      end

      it "is allowed, because the two periods never run at the same time" do
        expect(hub_period(name: "Acme TSH East",
                          started_on: Date.new(2022, 1, 1),
                          finished_on: nil)).to be_valid
      end

      # The factory finds or initialises by name, so a duplicate has to be built without it.
      def duplicate_period
        AppropriateBodyPeriod.new(body_type: "teaching_school_hub",
                                  teaching_school_hub:,
                                  provisioning_school: FactoryBot.create(:school),
                                  name: "Acme TSH East",
                                  started_on: Date.new(2021, 10, 1),
                                  finished_on: nil,
                                  dfe_sign_in_organisation_id: SecureRandom.uuid)
      end

      it "is refused when the periods overlap" do
        expect(duplicate_period).to have_error(
          :name,
          "Another active appropriate body in the teaching school hub uses this name."
        )
      end

      it "is refused by the database when validations are skipped" do
        expect { duplicate_period.save!(validate: false) }
          .to raise_error(ActiveRecord::StatementInvalid, /appropriate_body_periods_unique_names_for_concurrent_periods/)
      end
    end

    context "when the earlier period for the hub finished before this one started" do
      before do
        hub_period(name: "Acme TSH East",
                   started_on: Date.new(2021, 9, 1),
                   finished_on: Date.new(2021, 12, 31)).save!
      end

      it "does not require a name, because the periods never run at the same time" do
        expect(hub_period(name: nil,
                          started_on: Date.new(2022, 1, 1),
                          finished_on: nil)).to be_valid
      end
    end

    context "when another hub uses the same name at the same time" do
      before do
        hub_period(name: "Acme TSH East",
                   hub: FactoryBot.create(:teaching_school_hub, name: "Other TSH"),
                   started_on: Date.new(2021, 9, 1),
                   finished_on: nil).save!
      end

      it "is allowed, because the two hubs are unrelated" do
        expect(hub_period(name: "Acme TSH East",
                          started_on: Date.new(2021, 9, 1),
                          finished_on: nil)).to be_valid
      end
    end

    context "when the overlapping period belongs to a different hub" do
      before do
        hub_period(name: "Other TSH North",
                   hub: FactoryBot.create(:teaching_school_hub, name: "Other TSH"),
                   started_on: Date.new(2021, 9, 1),
                   finished_on: nil).save!
      end

      it "does not require a name" do
        expect(hub_period(name: nil,
                          started_on: Date.new(2021, 9, 1),
                          finished_on: nil)).to be_valid
      end
    end
  end

  describe "#display_name" do
    subject(:display_name) { appropriate_body_period.display_name }

    let(:teaching_school_hub) do
      FactoryBot.create(:teaching_school_hub, name: "Bright Futures Teaching School Hub")
    end
    let(:provisioning_school) do
      FactoryBot.create(:school, gias_school: FactoryBot.create(:gias_school, name: "Provisioning School"))
    end
    let(:appropriate_body_period) do
      FactoryBot.create(:appropriate_body_period, name:, teaching_school_hub:, provisioning_school:)
    end

    context "when the period has a name of its own" do
      let(:name) { "Star Institute" }

      it "prefers it to the parent organisation name" do
        expect(display_name).to eq("Star Institute")
      end

      context "when the period is a legacy teaching school that has since been renamed" do
        let(:appropriate_body_period) do
          FactoryBot.create(:appropriate_body_period, :teaching_school, name:, provisioning_school:)
        end

        it "shows the name the school had then, and not the school's name now" do
          expect(display_name).to eq("Star Institute")
        end
      end
    end

    context "when the period has no name of its own" do
      let(:name) { nil }

      it "delegates to the teaching school hub" do
        expect(display_name).to eq("Bright Futures Teaching School Hub")
      end

      context "when the period is backed by a national body" do
        let(:national_body) { FactoryBot.create(:national_body, name: "National Body X") }
        let(:appropriate_body_period) do
          FactoryBot.create(:appropriate_body_period, :national, name: nil, national_body:)
        end

        it "delegates to the national body" do
          expect(display_name).to eq("National Body X")
        end
      end

      context "when the period is backed by a local authority" do
        let(:local_authority) { FactoryBot.create(:local_authority, name: "Some Local Authority") }
        let(:appropriate_body_period) do
          FactoryBot.create(:appropriate_body_period, :local_authority, name: nil, local_authority:)
        end

        it "delegates to the local authority" do
          expect(display_name).to eq("Some Local Authority")
        end
      end

      context "when the period is a legacy teaching school" do
        let(:appropriate_body_period) do
          FactoryBot.create(:appropriate_body_period, :teaching_school, name: nil, provisioning_school:)
        end

        it "delegates to the provisioning school" do
          expect(display_name).to eq("Provisioning School")
        end
      end

      context "when the period has no parent organisation" do
        let(:appropriate_body_period) do
          # A legacy row: the current rules require a parent organisation, so write it without validations.
          FactoryBot.build(:appropriate_body_period, name: nil, teaching_school_hub: nil, provisioning_school: nil)
                    .tap { |period| period.save!(validate: false) }
        end

        it "returns nil" do
          expect(display_name).to be_nil
        end
      end
    end
  end
end
