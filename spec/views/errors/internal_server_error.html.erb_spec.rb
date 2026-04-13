it "displays support email" do
  expect(rendered).to have_link(
    "teacher.induction@education.gov.uk", href: "mailto:teacher.induction@education.gov.uk"
  )
  expect(rendered).to have_link(
    "continuing-professional-development@digital.education.gov.uk", href: "mailto:continuing-professional-development@digital.education.gov.uk",
  )
end