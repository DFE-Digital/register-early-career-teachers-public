import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "checkbox", "form" ]

  clickedCheckbox(event) {
    this.updateCheckboxStates(event.currentTarget)
    this.formTarget.submit()
  }

  updateCheckboxStates(clickedCheckbox) {
    const checked = clickedCheckbox.checked

    this.checkboxTargets.forEach(checkbox => {
      if (checkbox === clickedCheckbox) return

      if (!checked && clickedCheckbox.closest("li").contains(checkbox)) {
        checkbox.checked = false
      } else if (checked && checkbox.closest("li").contains(clickedCheckbox)) {
        checkbox.checked = true
      }
    })
  }
}
