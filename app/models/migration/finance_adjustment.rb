module Migration
  class FinanceAdjustment < Migration::Base
    belongs_to :statement
  end
end
