# TODO: remove before merge
AppropriateBody.primary_key = "id"
InductionPeriod.primary_key = "id"
Event.primary_key = "id"
Teacher.primary_key = "id"

west_lakes = AppropriateBody.find_by(name: "West Lakes Academy")
one_cumbria = AppropriateBody.find_by(name: "One Cumbria Teaching School Hub")
cut_off_date = Date.new(2024, 9, 1)

# TODO: remove before merge
RIAB::FullTransferInductionPeriods.new(from: west_lakes, to: one_cumbria, on: cut_off_date).debug
RIAB::FullTransferInductionPeriods.new(from: west_lakes, to: one_cumbria, on: cut_off_date).call(rollback: true)
RIAB::PartialTransferInductionPeriods.new(from: west_lakes, to: one_cumbria, on: cut_off_date).debug
RIAB::PartialTransferInductionPeriods.new(from: west_lakes, to: one_cumbria, on: cut_off_date).call(rollback: true)

# TODO: uncomment before merge
# RIAB::FullTransferInductionPeriods.new(from: west_lakes, to: one_cumbria, on: cut_off_date).call
# RIAB::PartialTransferInductionPeriods.new(from: west_lakes, to: one_cumbria, on: cut_off_date).call
