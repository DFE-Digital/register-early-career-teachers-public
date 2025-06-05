class TestGuidanceComponent < ViewComponent::Base
  renders_one :trs_example_teacher_details, "TRSExampleTeacherDetails"
  renders_one :trs_fake_api_instructions, "TRSFakeAPIInstructions"

  def render?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('TEST_GUIDANCE', false)) &&
      (content.present? || trs_example_teacher_details.present? || trs_fake_api_instructions.present?)
  end

  class TRSExampleTeacherDetails < ViewComponent::Base
    def head
      ["TRN", "Date of birth", "National Insurance Number", "Notes"]
    end

    def rows
      [
        ["1000890", "15/01/1997", "JL049125A", "Induction completed"],
        ["3002564", "05/07/1991", "JK028223B", "Exempt from induction"],
        ["3001899", "16/07/1991", "JL056123C", "Failed induction"],
        ["3003943", "02/02/1964", "AB722128C", "No QTS"],
        ["1000787", "01/04/1984", "JL056123B", "Alerts but not prohibited"],
        ["3002586", "03/02/1977", "OA647867D", ""],
        ["3002585", "02/01/1966", "MA251209B", ""],
        ["3002584", "24/11/1955", "RE937588C", ""],
        ["3002583", "24/09/1977", "PG050037C", ""],
        ["3002582", "11/05/1980", "WX999679C", "Exempt from mentor funding"],
        ["3002580", "04/03/1955", "BJ833983C", "Exempt from mentor funding"],
        ["3002579", "01/08/2001", "WJ584009B", ""],
        ["3002578", "10/09/1977", "CB196295D", ""],
        ["3002577", "02/12/2000", "BT524135A", ""],
        ["3002576", "04/03/1999", "GE377928A", ""],
        ["2632412", "16/02/1984", "", "Prohibited from teaching"],
        ["2908239", "12/08/1978", "", "Prohibited from teaching"],
      ]
    end

    def rows_with_buttons
      rows.map do |row|
        trn, dob, national_insurance_number = row
        row + [populate_button(trn, dob, national_insurance_number)]
      end
    end

    def populate_button(trn, dob, national_insurance_number)
      tag.button 'Select',
                 class: 'govuk-button govuk-button--secondary govuk-button--small populate-find-ect-form-button',
                 type: 'button',
                 data: { trn:, dob:, national_insurance_number: }
    end

    def call
      safe_join([
        tag.h3('Information to review this journey', class: 'govuk-heading-m'),
        tag.p('To successfully locate an ECT from the TRS API, use credentials from the table below:'),
        govuk_table(head:, rows: rows_with_buttons),
        javascript_include_tag('populate-find-ect-form', data: { turbo_track: 'reload' }, defer: true)
      ])
    end
  end

  class TRSFakeAPIInstructions < ViewComponent::Base
    def call
      safe_join([
        tag.h3("Information to review this journey", class: "govuk-heading-m"),
        tag.p("Enter any TRN with the date of birth 03-02-1977 to register a random ECT.", class: "govuk-body"),
        tag.p("The following TRNs are special and will result in an early exit.", class: "govuk-body"),
        govuk_list(
          [
            '7000001 (QTS not awarded)',
            '7000002 (teacher not found)',
            '7000003 (prohibited from teaching)',
            '7000004 (teacher has been deactivated in TRS)',
          ],
          type: 'bullet'
        )
      ])
    end
  end
end
