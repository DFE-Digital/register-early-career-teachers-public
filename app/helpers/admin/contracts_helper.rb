module Admin::ContractsHelper
  def contract_heading(contract)
    contract_name = contract.ittecf_ectp_contract_type? ? "ITTECF ECTP" : "ECF"
    vat_rate = number_to_percentage(contract.applicable_vat_rate * 100, precision: 0)
    "#{contract_name} (#{vat_rate} VAT)"
  end
end
