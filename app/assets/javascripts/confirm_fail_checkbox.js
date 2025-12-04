document.addEventListener('DOMContentLoaded', () => {
  const failCheckbox = document.querySelector('#confirm_fail_checkbox')
  const continueButton = document.querySelector('.govuk-button')

  if (failCheckbox) {
    failCheckbox.addEventListener('change', () => {
      continueButton.disabled = !failCheckbox.checked
    })
  }

  const moveElement = document.getElementById('move_ul_into_form_section');
  if (moveElement) {
    const targetLabel = document.querySelector('label[for="appropriate-bodies-record-fail-number-of-terms-field-error"], label[for="appropriate-bodies-record-fail-number-of-terms-field"]');
  
    const formGroup = targetLabel.closest('.govuk-form-group');
    formGroup.insertBefore(moveElement, formGroup.firstElementChild.nextElementSibling);
  }
})
