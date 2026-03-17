const PRINT_LINK_SELECTOR = '[data-print-link]'

let originalDocumentTitle

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

const preparePageTitleRestore = () => {
  window.addEventListener('afterprint', restorePageTitle, { once: true })
  window.addEventListener('focus', restorePageTitle, { once: true })
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
  preparePageTitleRestore()
  window.print()
})
