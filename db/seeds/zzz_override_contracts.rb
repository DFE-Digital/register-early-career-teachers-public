# TODO: REMOVE THIS
cp_2025 = ContractPeriod.find_by!(year: 2025)
cp_2026 = ContractPeriod.find_by!(year: 2026)

cp_2025.update!(finished_on: Date.new(2026, 3, 10))
cp_2026.update!(started_on: Date.new(2026, 3, 11))
