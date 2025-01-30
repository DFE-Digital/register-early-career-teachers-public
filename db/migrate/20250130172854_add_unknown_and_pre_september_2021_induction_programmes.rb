class AddUnknownAndPreSeptember2021InductionProgrammes < ActiveRecord::Migration[8.0]
  def change
    # these two new types are here to support records imported from DQT
    # some are after September 2021 and have no induction programme; they're not
    # really 'valid' but we need to record them
    add_enum_value :induction_programme, 'unknown'
    # any that started before september 2021 and have no induction programme
    # are valid, because the ECF induction programmes didn't exist when they
    # were openend - again they don't need fixing but should be recorded
    add_enum_value :induction_programme, 'pre_september_2021'
  end
end
