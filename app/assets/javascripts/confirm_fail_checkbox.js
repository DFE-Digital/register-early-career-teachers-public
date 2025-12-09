document.addEventListener('DOMContentLoaded', () => {
  const failCheckbox = document.querySelector('#confirm_fail_checkbox');
  const continueButton = document.querySelector('.govuk-button');

  failCheckbox.addEventListener('click', () => {
    if (failCheckbox.checked) {
      continueButton.removeAttribute('disabled');
      continueButton.setAttribute('aria-disabled', 'false');
    } else {
      continueButton.setAttribute('disabled', 'disabled');
      continueButton.setAttribute('aria-disabled', 'true');
    }
  })
})
