module PaymentCalculator
  class Banded::Uplifts
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :declarations
    attribute :uplift_fee_per_declaration

    def billable_count = @billable_count ||= filtered_declarations.billable.size
    def refundable_count = @refundable_count ||= filtered_declarations.refundable.size
    def net_count = billable_count - refundable_count

    def total_billable_amount = billable_count * uplift_fee_per_declaration
    def total_refundable_amount = refundable_count * uplift_fee_per_declaration
    def total_net_amount = total_billable_amount - total_refundable_amount

  private

    def filtered_declarations = declarations
      .where(pupil_premium_uplift: true)
      .or(declarations.where(sparsity_uplift: true))
  end
end
