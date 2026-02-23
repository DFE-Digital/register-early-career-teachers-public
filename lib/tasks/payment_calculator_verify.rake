require "csv"

def create_training_period(school_partnership)
  FactoryBot.create(:training_period, :for_ect, school_partnership:)
end

# Creates a refundable (awaiting_clawback) declaration without the factory trait
# to avoid auto-creating statements that collide with our controlled statements.
def create_clawback_declaration(school_partnership:, paid_out_statement:, clawback_statement:, **extras)
  FactoryBot.create(
    :declaration,
    payment_status: :paid,
    clawback_status: :awaiting_clawback,
    training_period: create_training_period(school_partnership),
    payment_statement: paid_out_statement,
    clawback_statement:,
    **extras
  )
end

namespace :payment_calculator do
  desc "Export PaymentCalculator::Banded results as CSV using ECF1 method names for comparison"
  task verify: :environment do
    require "factory_bot_rails"

    ActiveRecord::Base.transaction do
      # ── 1. Seed Data ────────────────────────────────────────────────────

      school_partnership = FactoryBot.create(:school_partnership, :for_year, year: 2025)
      active_lead_provider = school_partnership.active_lead_provider

      # Banded fee structure (monthly_service_fee nil → forces ServiceFees calculation)
      banded_fee_structure = Contract::BandedFeeStructure.create!(
        recruitment_target: 200,
        uplift_fee_per_declaration: 100.00,
        monthly_service_fee: nil,
        setup_fee: 500.00
      )

      # Bands A, B, C (reset association cache before each to avoid inverse_of validation issue)
      [
        { min_declarations: 1, max_declarations: 100, fee_per_declaration: 800.00 },
        { min_declarations: 101, max_declarations: 200, fee_per_declaration: 600.00 },
        { min_declarations: 201, max_declarations: 300, fee_per_declaration: 400.00 },
      ].each do |attrs|
        banded_fee_structure.bands.reset
        Contract::BandedFeeStructure::Band.create!(
          banded_fee_structure:,
          output_fee_ratio: 0.60,
          service_fee_ratio: 0.40,
          **attrs
        )
      end
      banded_fee_structure.bands.reset

      # Contract (ecf type)
      contract = FactoryBot.create(
        :contract,
        :for_ecf,
        active_lead_provider:,
        vat_rate: 0.20,
        banded_fee_structure:
      )

      # Statements: paid-out (for clawback declarations' payment_statement), previous, current
      # Using explicit month/year values that won't collide with each other
      paid_out_statement = FactoryBot.create(
        :statement,
        active_lead_provider:,
        contract:,
        month: 1,
        year: 2025,
        payment_date: Date.new(2025, 2, 1),
        status: :paid
      )

      previous_statement = FactoryBot.create(
        :statement,
        active_lead_provider:,
        contract:,
        month: 5,
        year: 2025,
        payment_date: Date.new(2025, 6, 1),
        status: :paid
      )

      current_statement = FactoryBot.create(
        :statement,
        active_lead_provider:,
        contract:,
        month: 6,
        year: 2025,
        payment_date: Date.new(2025, 7, 1),
        status: :payable
      )

      # ── Previous statement declarations ─────────────────────────────────

      # 10x started/eligible (billable) on previous statement
      10.times { FactoryBot.create(:declaration, :eligible, declaration_type: "started", training_period: create_training_period(school_partnership), payment_statement: previous_statement) }

      # 5x retained-1/payable (billable) on previous statement
      5.times { FactoryBot.create(:declaration, :payable, declaration_type: "retained-1", training_period: create_training_period(school_partnership), payment_statement: previous_statement) }

      # 2x started/awaiting_clawback (refundable) on previous statement
      2.times { create_clawback_declaration(school_partnership:, paid_out_statement:, clawback_statement: previous_statement, declaration_type: "started") }

      # ── Current statement declarations ──────────────────────────────────

      # 5x started/eligible (billable)
      5.times { FactoryBot.create(:declaration, :eligible, declaration_type: "started", training_period: create_training_period(school_partnership), payment_statement: current_statement) }

      # 3x started/payable with sparsity uplift
      3.times { FactoryBot.create(:declaration, :payable, declaration_type: "started", training_period: create_training_period(school_partnership), payment_statement: current_statement, sparsity_uplift: true) }

      # 2x started/payable with pupil premium uplift
      2.times { FactoryBot.create(:declaration, :payable, declaration_type: "started", training_period: create_training_period(school_partnership), payment_statement: current_statement, pupil_premium_uplift: true) }

      # 3x retained-1/eligible (billable)
      3.times { FactoryBot.create(:declaration, :eligible, declaration_type: "retained-1", training_period: create_training_period(school_partnership), payment_statement: current_statement) }

      # 4x retained-2/payable (billable)
      4.times { FactoryBot.create(:declaration, :payable, declaration_type: "retained-2", training_period: create_training_period(school_partnership), payment_statement: current_statement) }

      # 2x completed/eligible (billable)
      2.times { FactoryBot.create(:declaration, :eligible, declaration_type: "completed", training_period: create_training_period(school_partnership), payment_statement: current_statement) }

      # 3x started/awaiting_clawback (refundable) on current statement
      3.times { create_clawback_declaration(school_partnership:, paid_out_statement:, clawback_statement: current_statement, declaration_type: "started") }

      # 1x started/awaiting_clawback with sparsity uplift (refundable)
      create_clawback_declaration(school_partnership:, paid_out_statement:, clawback_statement: current_statement, declaration_type: "started", sparsity_uplift: true)

      # 1x completed/awaiting_clawback (refundable) on current statement
      create_clawback_declaration(school_partnership:, paid_out_statement:, clawback_statement: current_statement, declaration_type: "completed")

      # ── Adjustments on current statement ────────────────────────────────

      Statement::Adjustment.create!(statement: current_statement, payment_type: "Adjustment 1", amount: 150.00)
      Statement::Adjustment.create!(statement: current_statement, payment_type: "Adjustment 2", amount: -50.00)

      # ── 2. Run Calculator ───────────────────────────────────────────────

      calculator = PaymentCalculator::Banded.new(
        statement: current_statement,
        banded_fee_structure:,
        declaration_selector: ->(declarations) { declarations.all }
      )

      outputs = calculator.outputs
      uplifts = calculator.uplifts
      service_fees = PaymentCalculator::ServiceFees.new(banded_fee_structure:)

      # ── 3. Generate CSV ─────────────────────────────────────────────────

      # Ordered bands (A, B, C) by min_declarations
      ordered_bands = banded_fee_structure.bands.sort_by(&:min_declarations)
      # band_labels = ordered_bands.each_with_index.to_h { |band, i| [band.id, ("a".ord + i).chr] }

      # ECF1 uses underscored type names (retained_1), RECT uses dashes (retained-1).
      ecf_type = ->(type) { type.tr("-", "_") }

      # Canonical declaration type order matching ECF1
      declaration_types = %w[started retained-1 retained-2 retained-3 retained-4 completed extended-1 extended-2 extended-3]

      # Index DTOs by (declaration_type, band_id) for ordered lookup
      dto_index = outputs.declaration_type_outputs.index_by { |dto| [dto.declaration_type, dto.band_allocation.band.id] }

      csv_string = CSV.generate do |csv|
        csv << %w[section ecf_method rect_method value]

        # ── BandingCalculator per declaration_type per band ─────────────
        # ECF1: BandingCalculator#previous_count(letter), #count(letter),
        #        #additions(letter), #subtractions(letter)
        declaration_types.each do |dec_type|
          type = ecf_type.call(dec_type)
          ordered_bands.each_with_index do |band, i|
            letter = ("a".ord + i).chr
            dto = dto_index[[dec_type, band.id]]
            alloc = dto&.band_allocation

            prev_count = alloc ? alloc.previous_billable_count - alloc.previous_refundable_count : 0
            additions = alloc&.billable_count || 0
            subtractions = alloc&.refundable_count || 0
            count = alloc&.net_billable_count || 0

            csv << ["banding", "#{type}_previous_count_#{letter}", "band_allocation.previous_billable_count - previous_refundable_count", prev_count]
            csv << ["banding", "#{type}_additions_#{letter}", "band_allocation.billable_count", additions]
            csv << ["banding", "#{type}_subtractions_#{letter}", "band_allocation.refundable_count", subtractions]
            csv << ["banding", "#{type}_count_#{letter}", "band_allocation.net_billable_count", count]
          end

          # ── StatementCalculator per declaration_type per band ───────────
          # ECF1: statement_calculator.started_band_a_fee_per_declaration
          # ECF1: statement_calculator.started_band_a_additions (same as banding additions)
          # ECF1: statement_calculator.started_band_a_subtractions (same as banding subtractions)
          type = ecf_type.call(dec_type)
          ordered_bands.each_with_index do |band, i|
            letter = ("a".ord + i).chr
            dto = dto_index[[dec_type, band.id]]
            alloc = dto&.band_allocation

            fee = dto ? sprintf("%.2f", dto.output_fee_per_declaration) : "0.00"
            additions = alloc&.billable_count || 0
            subtractions = alloc&.refundable_count || 0

            csv << ["statement", "#{type}_band_#{letter}_fee_per_declaration", "declaration_type_output.output_fee_per_declaration", fee]
            csv << ["statement", "#{type}_band_#{letter}_additions", "declaration_type_output.band_allocation.billable_count", additions]
            csv << ["statement", "#{type}_band_#{letter}_subtractions", "declaration_type_output.band_allocation.refundable_count", subtractions]
          end

          # ── StatementCalculator per declaration_type totals ─────────────
          # ECF1: statement_calculator.additions_for_started (sum of additions * fee across bands)
          # ECF1: statement_calculator.deductions_for_started (sum of subtractions * fee across bands)
          type = ecf_type.call(dec_type)
          dtos = ordered_bands.filter_map { |band| dto_index[[dec_type, band.id]] }
          additions_total = dtos.sum(&:total_billable_amount)
          deductions_total = dtos.sum(&:total_refundable_amount)

          csv << ["statement", "additions_for_#{type}", "sum(declaration_type_output.total_billable_amount)", sprintf("%.2f", additions_total)]
          csv << ["statement", "deductions_for_#{type}", "sum(declaration_type_output.total_refundable_amount)", sprintf("%.2f", deductions_total)]
        end

        # ── StatementCalculator output totals ───────────────────────────
        # ECF1: statement_calculator.output_fee (sum of all additions_for_X)
        csv << ["statement", "output_fee", "outputs.total_billable_amount", sprintf("%.2f", outputs.total_billable_amount)]

        # ECF1: statement_calculator.clawback_deductions (sum of all deductions_for_X)
        csv << ["statement", "clawback_deductions", "outputs.total_refundable_amount", sprintf("%.2f", outputs.total_refundable_amount)]

        # ── StatementCalculator uplift ──────────────────────────────────
        # ECF1: statement_calculator.uplift_fee_per_declaration
        csv << ["statement", "uplift_fee_per_declaration", "banded_fee_structure.uplift_fee_per_declaration", banded_fee_structure.uplift_fee_per_declaration]

        # ECF1: statement_calculator.uplift_additions_count
        csv << ["statement", "uplift_additions_count", "uplifts.billable_count", uplifts.billable_count]

        # ECF1: statement_calculator.uplift_deductions_count
        csv << ["statement", "uplift_deductions_count", "uplifts.refundable_count", uplifts.refundable_count]

        # ECF1: statement_calculator.uplift_count (net)
        csv << ["statement", "uplift_count", "uplifts.net_count", uplifts.net_count]

        # ECF1: statement_calculator.uplift_payment (additions * fee)
        csv << ["statement", "uplift_payment", "uplifts.total_billable_amount", sprintf("%.2f", uplifts.total_billable_amount)]

        # ECF1: statement_calculator.uplift_clawback_deductions (negative: -deductions * fee)
        csv << ["statement", "uplift_clawback_deductions", "-uplifts.total_refundable_amount", sprintf("%.2f", -uplifts.total_refundable_amount)]

        # ECF1: statement_calculator.total_for_uplift
        csv << ["statement", "total_for_uplift", "uplifts.total_net_amount", sprintf("%.2f", uplifts.total_net_amount)]

        # ── StatementCalculator adjustments ─────────────────────────────
        # ECF1: statement_calculator.adjustments_total = -clawback_deductions + uplift_clawback_deductions
        adjustments_total = -outputs.total_refundable_amount + (-uplifts.total_refundable_amount)
        csv << ["statement", "adjustments_total", "-(outputs.total_refundable_amount + uplifts.total_refundable_amount)", sprintf("%.2f", adjustments_total)]

        # ECF1: statement_calculator.additional_adjustments_total
        csv << ["statement", "additional_adjustments_total", "calculator.total_manual_adjustments_amount", sprintf("%.2f", calculator.total_manual_adjustments_amount)]

        # ── StatementCalculator service fee ─────────────────────────────
        # ECF1: statement_calculator.service_fee
        csv << ["statement", "service_fee", "calculator.monthly_service_fee", sprintf("%.2f", calculator.monthly_service_fee)]

        # ECF1: calculated_service_fee (bands.sum { |b| b.service_fee_total / 29 })
        csv << ["statement", "calculated_service_fee", "service_fees.monthly_amount", sprintf("%.2f", service_fees.monthly_amount)]

        # ── StatementCalculator setup fee ───────────────────────────────
        csv << ["statement", "set_up_fee", "calculator.setup_fee", sprintf("%.2f", calculator.setup_fee)]

        # ── StatementCalculator totals ──────────────────────────────────
        # ECF1: statement_calculator.total (without VAT)
        csv << ["statement", "total", "calculator.total_amount(with_vat: false)", sprintf("%.2f", calculator.total_amount(with_vat: false))]

        # ECF1: vat
        vat = calculator.total_amount(with_vat: true) - calculator.total_amount(with_vat: false)
        csv << ["statement", "vat", "total_amount(with_vat: true) - total_amount(with_vat: false)", sprintf("%.2f", vat)]

        # ECF1: total(with_vat: true)
        csv << ["statement", "total_with_vat", "calculator.total_amount(with_vat: true)", sprintf("%.2f", calculator.total_amount(with_vat: true))]
      end

      output_path = Rails.root.join("rect_output.csv")
      File.write(output_path, csv_string)
      puts "Written to #{output_path}"

      raise ActiveRecord::Rollback
    end
  end
end
