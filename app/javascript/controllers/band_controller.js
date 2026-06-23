import { Controller } from "@hotwired/stimulus"

export default class BandController extends Controller {
  static targets = ["outputPercentage", "servicePercentage"]

  connect() {
    const target = this.servicePercentageTarget
    target.readOnly = true
    target.tabIndex = -1
    target.style.opacity = "0.5"
    target.style.cursor = "not-allowed"
    target.style.backgroundColor = "transparent"
  }

  updateServiceFee() {
    const output = Number.parseFloat(this.outputPercentageTarget.value)
    this.servicePercentageTarget.value = Number.isNaN(output) ? "" : (100 - output).toFixed(2)
  }
}
