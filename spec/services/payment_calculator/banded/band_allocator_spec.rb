RSpec.describe PaymentCalculator::Banded::BandAllocator do
  subject(:allocator) do
    described_class.new(
      bands:,
      billable_declarations: Declaration.where(id: current_billable_ids),
      refundable_declarations: Declaration.where(id: current_refundable_ids),
      previous_billable_declarations: Declaration.where(id: previous_billable_ids),
      previous_refundable_declarations: Declaration.where(id: previous_refundable_ids)
    )
  end

  let(:banded_fee_structure) { FactoryBot.create(:contract_banded_fee_structure) }
  let!(:band_a) { FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, min_declarations: 1, max_declarations: 2) }
  let!(:band_b) { FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, min_declarations: 3, max_declarations: 4) }
  let!(:band_c) { FactoryBot.create(:contract_banded_fee_structure_band, banded_fee_structure:, min_declarations: 5, max_declarations: 6) }
  let(:bands) { banded_fee_structure.bands.order(:min_declarations) }

  let(:current_billable_ids) { [] }
  let(:current_refundable_ids) { [] }
  let(:previous_billable_ids) { [] }
  let(:previous_refundable_ids) { [] }

  describe "#band_allocations_by_declaration_type" do
    context "with no declarations" do
      it "returns empty allocations" do
        allocations = allocator.band_allocations_by_declaration_type

        expect(allocations).to be_empty
      end
    end

    context "when current billable fits in band A" do
      let(:current_declarations) { FactoryBot.create_list(:declaration, 1, :eligible) }
      let(:current_billable_ids) { current_declarations.map(&:id) }

      it "allocates entirely to band A" do
        started = allocator.band_allocations_by_declaration_type.select { it.declaration_type == "started" }

        expect(started[0].billable_count).to eq(1)
        expect(started[1].billable_count).to eq(0)
        expect(started[2].billable_count).to eq(0)
      end
    end

    context "when current billable overflows to band B" do
      let(:current_declarations) { FactoryBot.create_list(:declaration, 3, :eligible) }
      let(:current_billable_ids) { current_declarations.map(&:id) }

      it "fills band A to capacity then overflows to band B" do
        started = allocator.band_allocations_by_declaration_type.select { it.declaration_type == "started" }

        expect(started[0].billable_count).to eq(2)
        expect(started[1].billable_count).to eq(1)
        expect(started[2].billable_count).to eq(0)
      end
    end

    context "when previous billable declarations take capacity" do
      let(:previous_declarations) { FactoryBot.create_list(:declaration, 1, :eligible) }
      let(:previous_billable_ids) { previous_declarations.map(&:id) }

      let(:current_declarations) { FactoryBot.create_list(:declaration, 2, :eligible) }
      let(:current_billable_ids) { current_declarations.map(&:id) }

      it "places current billable into remaining capacity" do
        started = allocator.band_allocations_by_declaration_type.select { it.declaration_type == "started" }

        expect(started[0]).to have_attributes(previous_billable_count: 1, billable_count: 1)
        expect(started[1]).to have_attributes(previous_billable_count: 0, billable_count: 1)
        expect(started[2]).to have_attributes(previous_billable_count: 0, billable_count: 0)
      end
    end

    context "when refundable declarations drain from highest band first" do
      let(:previous_declarations) { FactoryBot.create_list(:declaration, 3, :eligible) }
      let(:previous_billable_ids) { previous_declarations.map(&:id) }

      let(:current_declarations) { FactoryBot.create_list(:declaration, 2, :awaiting_clawback) }
      let(:current_billable_ids) { current_declarations.map(&:id) }
      let(:current_refundable_ids) { current_declarations.map(&:id) }

      it "drains refundable from highest band" do
        started = allocator.band_allocations_by_declaration_type.select { it.declaration_type == "started" }

        # awaiting_clawback declarations are both billable (payment_status: paid) and refundable
        # Step 1: prev eligible (3) → A(2), B(1)
        # Step 3: curr billable (2) → B(1), C(1)
        # Step 4: curr refundable (2) → drain from C(1), B(1)
        expect(started[0]).to have_attributes(previous_billable_count: 2, billable_count: 0, refundable_count: 0)
        expect(started[1]).to have_attributes(previous_billable_count: 1, billable_count: 1, refundable_count: 1)
        expect(started[2]).to have_attributes(billable_count: 1, refundable_count: 1)
      end
    end

    context "with the full 4-step algorithm" do
      let(:previous_declarations) { FactoryBot.create_list(:declaration, 3, :eligible) }
      let(:previous_billable_ids) { previous_declarations.map(&:id) }

      let(:current_declarations) { FactoryBot.create_list(:declaration, 3, :eligible) }
      let(:current_billable_ids) { current_declarations.map(&:id) }

      it "fills previous first then current into remaining capacity" do
        started = allocator.band_allocations_by_declaration_type.select { it.declaration_type == "started" }

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
      let(:previous_billable_ids) { previous_billable.map(&:id) + previous_refundable.map(&:id) }
      let(:previous_refundable_ids) { previous_refundable.map(&:id) }

      let(:current_billable) { FactoryBot.create_list(:declaration, 3, :eligible) }
      let(:current_refundable) { FactoryBot.create_list(:declaration, 1, :awaiting_clawback) }
      let(:current_billable_ids) { current_billable.map(&:id) + current_refundable.map(&:id) }
      let(:current_refundable_ids) { current_refundable.map(&:id) }

      it "accounts for refunds when allocating" do
        started = allocator.band_allocations_by_declaration_type.select { it.declaration_type == "started" }

        # awaiting_clawback declarations are both billable (payment_status: paid) and refundable
        # Step 1: prev billable (3 eligible + 1 awaiting_clawback = 4) → A(2), B(2)
        # Step 2: prev refundable (1 awaiting_clawback) removed from B(1) → B net=1, avail=1
        # Step 3: curr billable (3 eligible + 1 awaiting_clawback = 4) → B(1), C(2), 1 dropped
        # Step 4: curr refundable (1 awaiting_clawback) removed from C(1)
        expect(started[0]).to have_attributes(
          previous_billable_count: 2, previous_refundable_count: 0,
          billable_count: 0, refundable_count: 0
        )
        expect(started[1]).to have_attributes(
          previous_billable_count: 2, previous_refundable_count: 1,
          billable_count: 1, refundable_count: 0
        )
        expect(started[2]).to have_attributes(
          previous_billable_count: 0, previous_refundable_count: 0,
          billable_count: 2, refundable_count: 1
        )
      end
    end

    context "when billable exceeds total capacity" do
      let(:current_declarations) { FactoryBot.create_list(:declaration, 8, :eligible) }
      let(:current_billable_ids) { current_declarations.map(&:id) }

      it "fills all bands to capacity and ignores the excess" do
        started = allocator.band_allocations_by_declaration_type.select { it.declaration_type == "started" }

        expect(started[0].billable_count).to eq(2)
        expect(started[1].billable_count).to eq(2)
        expect(started[2].billable_count).to eq(2)
      end
    end

    context "when refundable exceeds billable" do
      let(:previous_declarations) { FactoryBot.create_list(:declaration, 1, :eligible) }
      let(:previous_billable_ids) { previous_declarations.map(&:id) }

      let(:current_declarations) { FactoryBot.create_list(:declaration, 3, :awaiting_clawback) }
      let(:current_billable_ids) { current_declarations.map(&:id) }
      let(:current_refundable_ids) { current_declarations.map(&:id) }

      it "drains only what is available and ignores the excess" do
        started = allocator.band_allocations_by_declaration_type.select { it.declaration_type == "started" }

        # awaiting_clawback declarations are both billable (3) and refundable (3)
        # Step 1: prev billable (1) → A(1)
        # Step 3: curr billable (3) → A(1), B(2)
        # Step 4: curr refundable (3) → drain from B(2), A(1) — net goes to zero
        expect(started[0]).to have_attributes(previous_billable_count: 1, billable_count: 1, refundable_count: 1)
        expect(started[1]).to have_attributes(billable_count: 2, refundable_count: 2)
        expect(started[2]).to have_attributes(refundable_count: 0)
      end
    end

    context "when multiple declaration types are present" do
      let(:started_billable) { FactoryBot.create_list(:declaration, 3, :eligible, declaration_type: "started") }
      let(:completed_billable) { FactoryBot.create_list(:declaration, 1, :eligible, declaration_type: "completed") }
      let(:current_billable_ids) { started_billable.map(&:id) + completed_billable.map(&:id) }

      it "allocates each type independently" do
        started = allocator.band_allocations_by_declaration_type.select { it.declaration_type == "started" }
        completed = allocator.band_allocations_by_declaration_type.select { it.declaration_type == "completed" }

        expect(started[0].billable_count).to eq(2)
        expect(started[1].billable_count).to eq(1)

        expect(completed[0].billable_count).to eq(1)
        expect(completed[1].billable_count).to eq(0)
      end
    end
  end
end
