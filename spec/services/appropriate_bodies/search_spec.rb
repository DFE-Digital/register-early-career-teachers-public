describe AppropriateBodies::Search do
  describe "dealing with search terms" do
    subject { described_class.new(query_string) }

    let(:query_string) { nil }

    describe ".istip" do
      subject { described_class.istip }

      context "when ISTIP has been registered" do
        let!(:istip) { FactoryBot.create(:appropriate_body, :istip) }

        it "returns it" do
          expect(subject).to eq(istip)
        end
      end

      context "when ISTIP has not been registered" do
        it "raises an exception" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound, "ISTIP appropriate body period not found!")
        end
      end
    end

    describe ".esp" do
      subject { described_class.esp }

      context "when ESP has been registered" do
        let!(:esp) { FactoryBot.create(:appropriate_body, :esp) }

        it "returns it" do
          expect(subject).to eq(esp)
        end
      end

      context "when ESP has not been registered" do
        it "raises an exception" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound, "ESP appropriate body period not found!")
        end
      end
    end

    describe "#search" do
      context "when the search string is blank" do
        let(:query_string) { " " }

        it "applies no conditions and returns all appropriate bodies" do
          subject.search

          expect(subject.search.to_sql).to start_with(%(SELECT "appropriate_body_periods".* FROM "appropriate_body_periods" ORDER BY))
        end
      end

      context "when the search string contains some text" do
        let(:query_string) { "Captain Scrummy" }

        it "initiates a full text search with the given search string" do
          expect(subject.search.to_sql).to include(%{WHERE (name ILIKE '%Captain Scrummy%')})
        end
      end

      context "ordering" do
        before { allow(AppropriateBodyPeriod).to receive(:where).and_call_original }

        it "defaults to order by name ascending" do
          expect(subject.search.to_sql).to include(%(ORDER BY "appropriate_body_periods"."name" ASC))
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
