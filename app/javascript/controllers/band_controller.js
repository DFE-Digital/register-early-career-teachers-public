import { Controller } from "@hotwired/stimulus"

export default class BandController extends Controller {
  static targets = ["outputPercentage", "servicePercentage", "serviceFeeStatus"]
  static values = { announceDelay: { type: Number, default: 750 } }

  connect() {
    this.servicePercentageTarget.value = this.#serviceFeePercentage()
  }

  disconnect() {
    clearTimeout(this.announceTimeout)
  }

  updateServiceFee() {
    const serviceFee = this.#serviceFeePercentage()

    this.servicePercentageTarget.value = serviceFee
    this.#announce(serviceFee)
  }

  roundAndCapOutputFee() {
    const outputFee = this.#roundedAndCappedOutputFee()

    if (outputFee === null) return

    this.outputPercentageTarget.value = outputFee
    this.updateServiceFee()
  }

  #announce(serviceFee) {
    clearTimeout(this.announceTimeout)

    this.announceTimeout = setTimeout(() => {
      this.serviceFeeStatusTarget.textContent = serviceFee === "" ? "" : `Service fee ${serviceFee}%`
    }, this.announceDelayValue)
  }

  #serviceFeePercentage() {
    const outputFee = this.#outputFee()

    if (outputFee === null || outputFee < 0 || outputFee > 100) return ""

    return String(100 - Math.round(outputFee))
  }

  #roundedAndCappedOutputFee() {
    const outputFee = this.#outputFee()

    if (outputFee === null) return null

    return Math.max(0, Math.min(100, Math.round(outputFee)))
  }

  #outputFee() {
    const outputFee = Number.parseFloat(this.outputPercentageTarget.value)

    return Number.isNaN(outputFee) ? null : outputFee
  }
}
