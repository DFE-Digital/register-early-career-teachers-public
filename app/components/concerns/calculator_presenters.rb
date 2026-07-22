module CalculatorPresenters
  extend ActiveSupport::Concern

private

  def presenter_for(calculator)
    presenter_class =
      if contract.ecf_contract_type?
        self.class::ECFPresenter
      elsif calculator.flat_rate?
        self.class::FlatRatePresenter
      elsif calculator.banded?
        self.class::BandedPresenter
      else
        raise ArgumentError, "Unknown calculator type: #{calculator.class}"
      end

    presenter_class.new(calculator)
  end
end
