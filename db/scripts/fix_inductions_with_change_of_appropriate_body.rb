west_lakes = AppropriateBodyPeriod.find_by(name: "West Lakes Academy")
one_cumbria = AppropriateBodyPeriod.find_by(name: "One Cumbria Teaching School Hub")
cut_off_date = Date.new(2024, 9, 1)

InductionPeriods::FullTransferInductionPeriods.new(from: west_lakes, to: one_cumbria, on: cut_off_date).call
InductionPeriods::PartialTransferInductionPeriods.new(from: west_lakes, to: one_cumbria, on: cut_off_date).call
