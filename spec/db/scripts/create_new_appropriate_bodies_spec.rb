require Rails.root.join("db/scripts/create_new_appropriate_bodies")

RSpec.describe CreateNewAppropriateBodies do
  describe "#call" do
    let(:migrator) { described_class.new }

    context "with existing national appropriate bodies" do
      let!(:ab) { FactoryBot.create(:appropriate_body_period, :istip) }

      it "creates national bodies" do
        expect { migrator.call }.to change(NationalBody, :count).by(1)

        expect(NationalBody.find_by(name: ab.name)).to be_present
      end
    end

    context "with existing local authority bodies" do
      let!(:ab) { FactoryBot.create(:appropriate_body_period, :local_authority) }

      it "creates local authorities" do
        expect { migrator.call }.to change(LocalAuthority, :count).by(1)

        expect(LocalAuthority.find_by(name: ab.name)).to be_present
      end
    end

    context "with a collated list of teaching school hub names" do
      let(:migrator) do
        described_class.new(["Star Teaching School Hub"])
      end

      it "creates teaching school hubs from the provided list" do
        expect { migrator.call }.to change(TeachingSchoolHub, :count).by(1)

        expect(TeachingSchoolHub.find_by(name: "Star Teaching School Hub")).to be_present
      end

      it "is idempotent" do
        migrator.call

        expect { migrator.call }.not_to change(TeachingSchoolHub, :count)
      end
    end
  end
end
