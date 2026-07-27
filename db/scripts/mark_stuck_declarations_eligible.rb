# There are declarations from ECF1 that migrated in a submitted
# state because there was no induction start date at the time.
# Subsequently an induction start date was recevied but the declarations
# were not moved to 'eligible'.
#
#
# $ kubectl exec -it <pod-name> -- bin/rails runner db/scripts/mark_stuck_declarations_eligible.rb
log = nil

def stuck_declarations_by_teacher
  Declaration
    .where(payment_status: "no_payment", voided_by_user: nil)
    .joins(:contract_period, :ect_teacher)
    .where(contract_period: { year: [2023, 2024, 2025] })
    .where.not(ect_teacher: { trs_induction_start_date: nil })
    .includes(:lead_provider, :contract_period, :ect_teacher)
    .group_by { |declaration| declaration.ect_teacher.id }
end

begin
  author = Events::SystemAuthor.new

  log = File.open(Rails.root.join("tmp/mark_stuck_declarations_eligible-#{Time.zone.now.to_fs(:iso8601)}.log"), "w")

  teacher_declarations = stuck_declarations_by_teacher

  teacher_declarations.each do |id, declarations|
    log.puts("Teacher ID: #{id}")
    declarations.each do |declaration|
      log.puts(" - Marking declaration: #{declaration.id} (#{declaration.declaration_type}) for #{declaration.contract_period.year} eligible")
    end

    Declarations::Actions::MarkDeclarationsEligible.new(declarations:, author:).mark
  rescue StandardError => e
    log.puts("*** Error: #{e.message} ***")
  end

  log.puts
  log.puts("Teachers: #{teacher_declarations.keys.count} | Declarations: #{teacher_declarations.values.sum(&:count)}")
ensure
  log.close unless log.nil?
end
