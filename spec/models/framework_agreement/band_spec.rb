RSpec.describe FrameworkAgreement::Band, type: :model do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }

  describe "associations" do
    it { is_expected.to belong_to(:framework_agreement) }
    it { is_expected.to have_many(:band_terms).class_name("Contract::BandedFeeStructure::BandTerm").inverse_of(:band) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:framework_agreement).with_message("Choose a lead provider") }

    it { is_expected.to validate_numericality_of(:allocation_order).is_greater_than(0).only_integer.with_message("Allocation order must be a number greater than zero") }

    it { is_expected.to validate_presence_of(:capacity).with_message("Capacity is required") }
    it { is_expected.to validate_numericality_of(:capacity).is_greater_than(0).only_integer.with_message("Capacity must be a number greater than zero") }

    context "changing capacity" do
      let(:band) { FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 500) }

      it "validates that capacity can only be increased" do
        band.capacity = 100
        expect(band).not_to be_valid
        expect(band.errors.full_messages).to include("Capacity can only be increased")

        band.capacity = 750
        expect(band).to be_valid
      end
    end
  end

  describe "immutability" do
    let!(:first_band) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }

    context "with only one band" do
      it "allows changing the capacity of the last band" do
        first_band.update!(capacity: 999)
        expect(first_band.reload.capacity).to eq 999
      end

      it "prevents changing the allocation order of the last band" do
        expect { first_band.update!(allocation_order: 2) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
      end
    end

    context "with multiple bands" do
      let!(:last_band) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }

      it "prevents changing the capacity of a band that is not the last" do
        expect { first_band.update!(capacity: 999) }.to raise_error(ActiveRecord::RecordNotSaved)
        expect(first_band.errors[:base]).to include("Only the last band can be updated")
      end

      it "prevents changing the allocation order of a band that is not the last" do
        expect { first_band.update!(allocation_order: 2) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
      end

      it "allows deleting the last band" do
        expect { last_band.destroy! }.to change(described_class, :count).by(-1)
      end

      it "prevents deleting a band that is not the last" do
        expect { first_band.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
        expect(first_band.errors[:base]).to include("Only the last band can be destroyed")
      end
    end
  end

  describe "#allocation_order" do
    it "auto-assigns the next position" do
      expect(FactoryBot.create(:framework_agreement_band, framework_agreement:).allocation_order).to eq 1
      expect(FactoryBot.create(:framework_agreement_band, framework_agreement:).allocation_order).to eq 2
      expect(FactoryBot.create(:framework_agreement_band, framework_agreement:).allocation_order).to eq 3
    end

    context "when the allocation order of a persisted band is edited" do
      subject(:band) do
        FactoryBot.create(:framework_agreement_band, framework_agreement:)
      end

      it "raises a read-only error" do
        expect { band.allocation_order = 2 }.to raise_error(ActiveRecord::ReadonlyAttributeError)
        expect { band.update!(allocation_order: 2) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
      end
    end
  end

  describe "#min_declarations" do
    subject { band.min_declarations }

    context "without allocation_order" do
      let(:band) do
        FactoryBot.build(:framework_agreement_band,
                         framework_agreement:,
                         allocation_order: nil)
      end

      it { is_expected.to be_nil }
    end

    context "with the first band" do
      let(:band) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }

      it { is_expected.to eq 1 }
    end

    context "with a subsequent band" do
      before do
        FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 100)
        FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 50)
      end

      let(:band) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }

      it "sums previous capacities plus one" do
        expect(band.min_declarations).to eq 151
      end
    end
  end

  describe "#max_declarations" do
    context "when unallocated" do
      subject { band.max_declarations }

      let(:band) { FactoryBot.build(:framework_agreement_band, framework_agreement:) }

      it { is_expected.to be_nil }
    end

    context "with the first band" do
      let(:band) { FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 100) }

      it "equals the capacity" do
        expect(band.max_declarations).to eq 100
      end
    end

    context "with a subsequent band" do
      before do
        FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 100)
        FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 50)
      end

      let(:band) { FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 200) }

      it "sums all capacities" do
        expect(band.max_declarations).to eq 350
      end
    end
  end

  describe "#letter" do
    before do
      FactoryBot.create_list(:framework_agreement_band, 6, framework_agreement:)
    end

    it "bands alphabetically in allocation order" do
      expect(framework_agreement.bands.map(&:letter)).to eq(%w[A B C D E F])
    end
  end

  describe "adding a new band" do
    context "when the contract period has not started" do
      it "permits adding a band" do
        expect {
          framework_agreement.bands.create(capacity: 400)
        }.to change(FrameworkAgreement::Band, :count).by(1)
      end

      context "when there is a contract in place" do
        let!(:contract) { FactoryBot.create(:contract, framework_agreement:) }

        it "prevents adding a band" do
          expect {
            framework_agreement.bands.create(capacity: 400)
          }.not_to change(FrameworkAgreement::Band, :count)
        end
      end
    end

    context "when the contract period has started" do
      it "prevents adding a band" do
        travel_to(contract_period.started_on + 1.day) do
          expect {
            framework_agreement.bands.create(capacity: 400)
          }.not_to change(FrameworkAgreement::Band, :count)
        end
      end

      context "when there is a contract in place" do
        let!(:contract) { FactoryBot.create(:contract, framework_agreement:) }

        it "prevents adding a band" do
          travel_to(contract_period.started_on + 1.day) do
            expect {
              framework_agreement.bands.create(capacity: 400)
            }.not_to change(FrameworkAgreement::Band, :count)
          end
        end
      end
    end
  end

  describe "removing the last band" do
    let!(:existing_band) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }

    context "when the contract period has not started" do
      it "permits removing a band" do
        expect {
          existing_band.destroy
        }.to change(FrameworkAgreement::Band, :count).by(-1)
      end

      context "when there is a contract in place" do
        let!(:contract) { FactoryBot.create(:contract, framework_agreement:) }

        it "prevents removing a band" do
          expect {
            existing_band.destroy
          }.not_to change(FrameworkAgreement::Band, :count)
        end
      end
    end

    context "when the contract period has started" do
      it "prevents removing a band" do
        travel_to(contract_period.started_on + 1.day) do
          expect {
            existing_band.destroy
          }.not_to change(FrameworkAgreement::Band, :count)
        end
      end

      context "when there is a contract in place" do
        let!(:contract) { FactoryBot.create(:contract, framework_agreement:) }

        it "prevents adding a band" do
          travel_to(contract_period.started_on + 1.day) do
            expect {
              existing_band.destroy
            }.not_to change(FrameworkAgreement::Band, :count)
          end
        end
      end
    end
  end

  describe "#last?" do
    let!(:band_a) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }
    let!(:band_b) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }
    let!(:band_c) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }

    context "when the band is the last in the allocation order" do
      it "returns true" do
        expect(band_c).to be_last
      end
    end

    context "when the band is not the last in the allocation order" do
      it "returns false" do
        expect(band_a).not_to be_last
        expect(band_b).not_to be_last
      end
    end
  end

  describe "#editable?" do
    let!(:band_a) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }
    let!(:band_b) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }
    let!(:band_c) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }

    context "when the band is the last in the allocation order" do
      it "returns true" do
        expect(band_c).to be_editable
      end
    end

    context "when the band is not the last in the allocation order" do
      it "returns false" do
        expect(band_a).not_to be_editable
        expect(band_b).not_to be_editable
      end
    end
  end

  describe "#deletable?" do
    let!(:band_a) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }
    let!(:band_b) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }
    let!(:band_c) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }

    context "when the framework agreement does not have any contracts" do
      context "and the contract period has not started" do
        context "when the band is the last in the allocation order" do
          it "returns true" do
            expect(band_c).to be_deletable
          end
        end

        context "when the band is not the last in the allocation order" do
          it "returns false" do
            expect(band_a).not_to be_deletable
            expect(band_b).not_to be_deletable
          end
        end
      end

      context "and the contract period has started" do
        it "returns false" do
          travel_to contract_period.started_on do
            expect(band_a).not_to be_deletable
            expect(band_b).not_to be_deletable
            expect(band_c).not_to be_deletable
          end
        end
      end
    end

    context "when the framework agreement has a contract" do
      before do
        FactoryBot.create(:contract, framework_agreement:)
      end

      context "and the contract period has not started" do
        it "returns false" do
          expect(band_a).not_to be_deletable
          expect(band_b).not_to be_deletable
          expect(band_c).not_to be_deletable
        end
      end

      context "and the contract period has started" do
        it "returns false" do
          travel_to contract_period.started_on do
            expect(band_a).not_to be_deletable
            expect(band_b).not_to be_deletable
            expect(band_c).not_to be_deletable
          end
        end
      end
    end
  end
end
