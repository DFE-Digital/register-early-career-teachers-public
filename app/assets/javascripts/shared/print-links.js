const PRINT_LINK_SELECTOR = '[data-print-link]'

let originalDocumentTitle
let originalDetailsState = []

const setPageTitle = (link) => {
  const { printFilename } = link.dataset

  if (!printFilename) {
    return
  }

  if (originalDocumentTitle === undefined) {
    originalDocumentTitle = document.title
  }

  document.title = printFilename
}

const restorePageTitle = () => {
  if (originalDocumentTitle === undefined) {
    return
  }

  document.title = originalDocumentTitle
  originalDocumentTitle = undefined
}

const expandDetailsForPrint = () => {
  if (originalDetailsState.length > 0) {
    return
  }

  originalDetailsState = Array.from(document.querySelectorAll('details')).map((detail) => {
    const { open } = detail
    detail.open = true

    return { detail, open }
  })
}

const restoreDetailsState = () => {
  if (originalDetailsState.length === 0) {
    return
  }

  originalDetailsState.forEach(({ detail, open }) => {
    detail.open = open
  })

  originalDetailsState = []
}

const restorePageState = () => {
  restorePageTitle()
  restoreDetailsState()
}

const preparePageStateRestore = () => {
  window.addEventListener('afterprint', restorePageState, { once: true })
  window.addEventListener('focus', restorePageState, { once: true })
}

const printLinkFor = (event) => {
  const target = event.target
  const targetElement = target instanceof window.Element ? target : target?.parentElement

  return targetElement?.closest(PRINT_LINK_SELECTOR) ?? null
}

const ignorePrintClick = (event) => {
  return event.metaKey || event.ctrlKey || event.shiftKey || event.button !== 0
}

document.addEventListener('click', (event) => {
  const link = printLinkFor(event)

  if (!link) {
    return
  }

  if (ignorePrintClick(event)) {
    return
  }

  event.preventDefault()
  setPageTitle(link)
  expandDetailsForPrint()
  preparePageStateRestore()
  window.print()
})
