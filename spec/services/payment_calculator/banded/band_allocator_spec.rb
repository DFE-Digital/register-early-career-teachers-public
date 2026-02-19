RSpec.describe PaymentCalculator::Banded::BandAllocator do
  subject(:allocator) do
    described_class.new(
      bands:,
      declarations: Declaration.where(id: current_declaration_ids),
      previous_declarations: Declaration.where(id: previous_declaration_ids)
    )
  end

  let(:banded_fee_structure) { FactoryBot.create(:contract_banded_fee_structure) }
  let!(:band_a) { FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, min_declarations: 1, max_declarations: 2) }
  let!(:band_b) { FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, min_declarations: 3, max_declarations: 4) }
  let!(:band_c) { FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, min_declarations: 5, max_declarations: 6) }
  let(:bands) { banded_fee_structure.bands.order(:min_declarations) }

  let(:current_declaration_ids) { [] }
  let(:previous_declaration_ids) { [] }

  describe "#band_allocations" do
    context "with no declarations" do
      it "returns an empty hash when no declaration types are present" do
        expect(allocator.band_allocations).to eq({})
      end
    end

    context "when current billable fits in band A" do
      let(:current_declarations) { FactoryBot.create_list(:declaration, 1, :eligible) }
      let(:current_declaration_ids) { current_declarations.map(&:id) }

      it "allocates entirely to band A" do
        started = allocator.band_allocations.fetch("started")

        expect(started[0].billable_count).to eq(1)
        expect(started[1].billable_count).to eq(0)
        expect(started[2].billable_count).to eq(0)
      end
    end

    context "when current billable overflows to band B" do
      let(:current_declarations) { FactoryBot.create_list(:declaration, 3, :eligible) }
      let(:current_declaration_ids) { current_declarations.map(&:id) }

      it "fills band A to capacity then overflows to band B" do
        started = allocator.band_allocations.fetch("started")

        expect(started[0].billable_count).to eq(2)
        expect(started[1].billable_count).to eq(1)
        expect(started[2].billable_count).to eq(0)
      end
    end

    context "when previous billable declarations take capacity" do
      let(:previous_declarations) { FactoryBot.create_list(:declaration, 1, :eligible) }
      let(:previous_declaration_ids) { previous_declarations.map(&:id) }

      let(:current_declarations) { FactoryBot.create_list(:declaration, 2, :eligible) }
      let(:current_declaration_ids) { current_declarations.map(&:id) }

      it "places current billable into remaining capacity" do
        started = allocator.band_allocations.fetch("started")

        expect(started[0]).to have_attributes(previous_billable_count: 1, billable_count: 1)
        expect(started[1]).to have_attributes(previous_billable_count: 0, billable_count: 1)
        expect(started[2]).to have_attributes(previous_billable_count: 0, billable_count: 0)
      end
    end

    context "when refundable declarations drain from highest band first" do
      let(:previous_declarations) { FactoryBot.create_list(:declaration, 3, :eligible) }
      let(:previous_declaration_ids) { previous_declarations.map(&:id) }

      let(:current_declarations) { FactoryBot.create_list(:declaration, 2, :awaiting_clawback) }
      let(:current_declaration_ids) { current_declarations.map(&:id) }

      it "drains refundable from band B before band A" do
        started = allocator.band_allocations.fetch("started")

        expect(started[0]).to have_attributes(previous_billable_count: 2, refundable_count: 1)
        expect(started[1]).to have_attributes(previous_billable_count: 1, refundable_count: 1)
        expect(started[2]).to have_attributes(refundable_count: 0)
      end
    end

    context "with the full 4-step algorithm" do
      let(:previous_declarations) { FactoryBot.create_list(:declaration, 3, :eligible) }
      let(:previous_declaration_ids) { previous_declarations.map(&:id) }

      let(:current_declarations) { FactoryBot.create_list(:declaration, 3, :eligible) }
      let(:current_declaration_ids) { current_declarations.map(&:id) }

      it "fills previous first then current into remaining capacity" do
        started = allocator.band_allocations.fetch("started")

        # Step 1: prev eligible added to A(2), B(1)
        # Step 3: curr eligible added to B(1), C(2)
        expect(started[0]).to have_attributes(previous_billable_count: 2, billable_count: 0)
        expect(started[1]).to have_attributes(previous_billable_count: 1, billable_count: 1)
        expect(started[2]).to have_attributes(previous_billable_count: 0, billable_count: 2)
      end
    end

    context "with previous refundable freeing capacity" do
      let(:previous_billable) { FactoryBot.create_list(:declaration, 3, :eligible) }
      let(:previous_refundable) { FactoryBot.create_list(:declaration, 1, :awaiting_clawback) }
      let(:previous_declaration_ids) { previous_billable.map(&:id) + previous_refundable.map(&:id) }

      let(:current_billable) { FactoryBot.create_list(:declaration, 3, :eligible) }
      let(:current_refundable) { FactoryBot.create_list(:declaration, 1, :awaiting_clawback) }
      let(:current_declaration_ids) { current_billable.map(&:id) + current_refundable.map(&:id) }

      it "accounts for refunds when allocating" do
        started = allocator.band_allocations.fetch("started")

        # Step 1: prev eligible added to A(2), B(1)
        # Step 2: prev awaiting_clawback removed from B(1) → B net=0, avail=2
        # Step 3: curr eligible added to B(2), C(1)
        # Step 4: curr awaiting_clawback removed from C(1) → C net=0
        expect(started[0]).to have_attributes(
          previous_billable_count: 2, previous_refundable_count: 0,
          billable_count: 0, refundable_count: 0
        )
        expect(started[1]).to have_attributes(
          previous_billable_count: 1, previous_refundable_count: 1,
          billable_count: 2, refundable_count: 0
        )
        expect(started[2]).to have_attributes(
          previous_billable_count: 0, previous_refundable_count: 0,
          billable_count: 1, refundable_count: 1
        )
      end
    end

    context "when billable exceeds total capacity" do
      let(:current_declarations) { FactoryBot.create_list(:declaration, 8, :eligible) }
      let(:current_declaration_ids) { current_declarations.map(&:id) }

      it "fills all bands to capacity and ignores the excess" do
        started = allocator.band_allocations.fetch("started")

        expect(started[0].billable_count).to eq(2)
        expect(started[1].billable_count).to eq(2)
        expect(started[2].billable_count).to eq(2)
      end
    end

    context "when refundable exceeds billable" do
      let(:previous_declarations) { FactoryBot.create_list(:declaration, 1, :eligible) }
      let(:previous_declaration_ids) { previous_declarations.map(&:id) }

      let(:current_declarations) { FactoryBot.create_list(:declaration, 3, :awaiting_clawback) }
      let(:current_declaration_ids) { current_declarations.map(&:id) }

      it "drains only what is fetch and ignores the excess" do
        started = allocator.band_allocations.fetch("started")

        expect(started[0]).to have_attributes(previous_billable_count: 1, refundable_count: 1)
        expect(started[1]).to have_attributes(refundable_count: 0)
        expect(started[2]).to have_attributes(refundable_count: 0)
      end
    end

    context "when multiple declaration types are present" do
      let(:started_billable) { FactoryBot.create_list(:declaration, 3, :eligible, declaration_type: "started") }
      let(:completed_billable) { FactoryBot.create_list(:declaration, 1, :eligible, declaration_type: "completed") }
      let(:current_declaration_ids) { started_billable.map(&:id) + completed_billable.map(&:id) }

      it "allocates each type independently" do
        started = allocator.band_allocations.fetch("started")
        completed = allocator.band_allocations.fetch("completed")

        expect(started[0].billable_count).to eq(2)
        expect(started[1].billable_count).to eq(1)

        expect(completed[0].billable_count).to eq(1)
        expect(completed[1].billable_count).to eq(0)
      end
    end
  end
end
