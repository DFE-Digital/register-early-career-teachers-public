# Add initial Statement::AuditNote records
# Thexe are not currently designed to be added or edited in the UI,
# but are to show some context to contract managers on particular statements
#
# NOTE: To best preserve formatting, the son-of-patch tool wasn't used for this
#

Statement::AuditNote.create!(
  statement_id: 616,
  body: <<~NOTE.squish
    Known discrepancy with what was invoiced following data migration to RECT service in April 2026: +£4,896.54
    <br/></br/>
    x1 started declaration (955c45ff-32f3-4f58-8219-5804d7a5de4f) included for payment in ECF1 service but was unable
    to be represented in the RECT service
    <br/></br/>
    x15 started declarations priced at £0 in ECF1 service and priced £272.03+VAT in RECT service because RECT recognises
    a higher ceiling to Band D than was present at the time of invoicing
  NOTE
)

Statement::AuditNote.create!(
  statement_id: 114,
  body: <<~NOTE.squish
    Known discrepancy with what was invoiced following data migration to RECT service in April 2026: +£10,119.52
    <br/></br/>
    x31 started declarations priced at £0 in ECF1 service and priced £272.03+VAT in RECT service because RECT recognises
    a higher ceiling to Band D than was present at the time of invoicing
  NOTE
)

Statement::AuditNote.create!(
  statement_id: 852,
  body: <<~NOTE.squish
    Known discrepancy with what was invoiced following data migration to RECT service in April 2026: +£171.40
    <br/></br/>
    Retained-1 declaration (0e907957-5c0f-43f4-8604-9a6d9b745d3b) included for payment in ECF1 service but was unable
    to be represented in the RECT service
  NOTE
)

Statement::AuditNote.create!(
  statement_id: 458,
  body: <<~NOTE.squish
    Known discrepancy with what was invoiced following data migration to RECT service in April 2026: -£171.40
    <br/></br/>
    Retained-1 declaration (0e907957-5c0f-43f4-8604-9a6d9b745d3b) included for clawback in ECF1 service but was unable
    to be represented in the RECT service
  NOTE
)

Statement::AuditNote.create!(
  statement_id: 506,
  body: <<~NOTE.squish
    Known discrepancy with what was invoiced following data migration to RECT service in April 2026: +£104.33
    <br/></br/>
    Retained-1 declaration (ed8fef62-3a53-4b2d-8230-97a64e90847c) included for payment in ECF1 service but was unable
    to be represented in the RECT service
  NOTE
)

Statement::AuditNote.create!(
  statement_id: 471,
  body: <<~NOTE.squish
    Known discrepancy with what was invoiced following data migration to RECT service in April 2026: -£104.33
    <br/></br/>
    Retained-1 declaration (ed8fef62-3a53-4b2d-8230-97a64e90847c) included for clawback in ECF1 service but was unable
    to be represented in the RECT service
  NOTE
)

Statement::AuditNote.create!(
  statement_id: 795,
  body: <<~NOTE.squish
    Known discrepancy with what was invoiced following data migration to RECT service in April 2026: -£120.00
    <br/></br/>
    x1 additional uplift fee included for payment in ECF1 service but was unable to be represented in the RECT service
  NOTE
)
