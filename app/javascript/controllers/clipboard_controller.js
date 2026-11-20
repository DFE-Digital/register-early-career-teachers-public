import { Controller } from "@hotwired/stimulus"

export default class ClipboardController extends Controller {
  static targets = ["source", "button", "status"]

  connect() {
    this.buttonTarget.hidden = !navigator.clipboard
  }

  async copy() {
    const label = this.sourceTarget.labels[0].textContent

    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
      this.statusTarget.textContent = `${label} copied`
    } catch {
      this.statusTarget.textContent = `${label} could not be copied, select the text and copy it`
    }
  }
}
