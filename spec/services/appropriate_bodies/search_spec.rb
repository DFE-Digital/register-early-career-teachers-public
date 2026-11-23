describe AppropriateBodies::Search do
  describe "dealing with search terms" do
    subject { described_class.new(query_string) }

    let(:query_string) { nil }

    describe ".istip" do
      subject { described_class.istip }

      context "when ISTIP has been registered" do
        let!(:istip) { FactoryBot.create(:appropriate_body_period, :istip) }

        it "returns it" do
          expect(subject).to eq(istip)
        end
      end

      context "when ISTIP period name is nullified" do
        let!(:istip) { FactoryBot.create(:appropriate_body_period, :istip, name: nil) }

        it "finds it by the national body name" do
          expect(subject).to eq(istip)
        end
      end

      context "when ISTIP period name is overridden" do
        let!(:istip) { FactoryBot.create(:appropriate_body_period, :istip, name: "Renamed Period") }

        it "still finds it by the national body name" do
          expect(subject).to eq(istip)
        end
      end

      context "when ISTIP has not been registered" do
        it "raises an exception" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound, "ISTIP appropriate body period not found!")
        end
      end
    end

    describe "#search" do
      subject(:results) { described_class.new(query).search }

      let(:query) { nil }

      def period_named_by_tsh(name)
        teaching_school_hub = FactoryBot.create(:teaching_school_hub, name:)
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub, :nameless,
                          teaching_school_hub:)
      end

      def period_named_by_period(name)
        FactoryBot.create(:appropriate_body_period, :teaching_school_hub,
                          name:)
      end

      def period_named_by_nb(name)
        national_body = FactoryBot.create(:national_body, name:)
        FactoryBot.create(:appropriate_body_period, :national, :nameless,
                          national_body:)
      end

      def period_named_by_la(name)
        local_authority = FactoryBot.create(:local_authority, name:)
        FactoryBot.create(:appropriate_body_period, :local_authority, :nameless,
                          local_authority:)
      end

      def period_named_by_ts(name)
        gias_school = FactoryBot.create(:gias_school, :eligible_type, :in_england, name:)
        provisioning_school = FactoryBot.create(:school, :eligible, gias_school:)
        FactoryBot.create(:appropriate_body_period, :teaching_school, :nameless,
                          provisioning_school:)
      end

      context "when nothing is searched for" do
        let(:query) { " " }
        let!(:period) { period_named_by_tsh("Example Hub") }

        it { is_expected.to contain_exactly(period) }
      end

      context "when the period carries its own name" do
        let(:query) { "of its own" }
        let!(:period) { period_named_by_period("A name of its own") }

        it { is_expected.to contain_exactly(period) }
      end

      context "when the hub supplies the name" do
        let(:query) { "example hub" }
        let!(:period) { period_named_by_tsh("Example Hub") }

        it { is_expected.to contain_exactly(period) }
      end

      context "when the national body supplies the name" do
        let(:query) { "example body" }
        let!(:period) { period_named_by_nb("Example Body") }

        it { is_expected.to contain_exactly(period) }
      end

      context "when the local authority supplies the name" do
        let(:query) { "example authority" }
        let!(:period) { period_named_by_la("Example Authority") }

        it { is_expected.to contain_exactly(period) }
      end

      context "when the school supplies the name" do
        let(:query) { "example school" }
        let!(:period) { period_named_by_ts("Example School") }

        it { is_expected.to contain_exactly(period) }
      end

      context "when the query contains a wildcard" do
        let(:query) { "%" }
        let!(:period) { period_named_by_tsh("100% Hub") }

        it "treats it as a literal character" do
          expect(results).to contain_exactly(period)
        end
      end

      context "when the periods display different names" do
        let!(:nameless) { period_named_by_tsh("Alpha Hub") }
        let!(:named) { period_named_by_period("Zeta Body") }

        it "orders by the displayed name, not the column" do
          expect(results.to_a).to eq([nameless, named])
        end
      end
    end

    describe "#find_by_dfe_sign_in_organisation_id" do
      it "uses the provided ID to find the right appropriate body" do
        allow(AppropriateBodyPeriod).to receive(:find_by).with(dfe_sign_in_organisation_id: "abc123").and_call_original

        subject.find_by_dfe_sign_in_organisation_id("abc123")

        expect(AppropriateBodyPeriod).to have_received(:find_by).with(dfe_sign_in_organisation_id: "abc123")
      end
    end
  end
end
