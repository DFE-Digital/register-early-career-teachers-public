import { Controller } from "@hotwired/stimulus"

export default class BandController extends Controller {
  static targets = ["outputPercentage", "servicePercentage"]

  // Ensure output_fee_percentage is 0..100
  // Update service_fee_percentage with delta
  updateServiceFee() {
    let output = Number.parseFloat(this.outputPercentageTarget.value)

    if (Number.isNaN(output)) {
      this.servicePercentageTarget.value = ""
      return
    }

    output = Math.max(0, Math.min(100, Math.round(output)))
    this.outputPercentageTarget.value = output
    this.servicePercentageTarget.value = (100 - output)
  }
}
