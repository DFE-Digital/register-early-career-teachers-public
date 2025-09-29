class TestGuidanceComponent < ApplicationComponent
  renders_one :trs_example_teacher_details, "TRSExampleTeacherDetails"
  renders_one :trs_fake_api_instructions, "TRSFakeAPIInstructions"

  def render?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('TEST_GUIDANCE', false)) &&
      (content.present? || trs_example_teacher_details.present? || trs_fake_api_instructions.present?)
  end

  class TRSFakeAPIInstructions < ApplicationComponent
    def list
      [
        '7000001 (QTS not awarded)',
        '7000002 (teacher not found)',
        '7000003 (prohibited from teaching)',
        '7000004 (teacher has been deactivated in TRS)',
        '7000005 (teacher has alerts but is not prohibited)',
        '7000006 (teacher is exempt from mentor funding)',
        '7000007 (teacher has passed their induction)',
        '7000008 (teacher has failed their induction)',
        '7000009 (teacher is exempt from training)',
        '7000010 (teacher has failed their induction in Wales)',
      ]
    end
  end

  class TRSExampleTeacherDetails < ApplicationComponent
    def head
      ["Name", "TRN", "Date of birth", "National Insurance Number", "Notes", ""]
    end

    def rows
      [
        ["Chloe Nolan",         "3002586", "03/02/1977", "OA647867D", ""],
        ["Delilah Frost",       "3002585", "02/01/1966", "MA251209B", ""],
        ["Theo Willis",         "3002584", "24/11/1955", "RE937588C", ""],
        ["Marvin Fuller",       "3002583", "24/09/1977", "PG050037C", ""],
        ["Daisy Dudley",        "3002576", "04/03/1999", "GE377928A", ""],
        ["Jonas Bloggs",        "3002577", "02/12/2000", "BT524135A", ""],
        ["Cynthia Parks",       "3002578", "10/09/1977", "CB196295D", ""],
        ["Taylor Hawkins",      "3002579", "01/08/2001", "WJ584009B", ""],
        ["Muhammed Ali",        "3002580", "04/03/1955", "BJ833983C", "No mentor funding"],
        ["Robson Scottie",      "3002582", "11/05/1980", "WX999679C", "No mentor funding"],
        ["Rebecca Jones",       "1209937", "12/10/1993", "J698546XA", "Passed induction"],
        ["Joseph Waller",       "1062313", "30/05/1988", "1A7T689J2", "Passed induction"],
        ["Jacqueline Bartlett", "2057184", "31/08/1976", "82063AJE7", "Exempt from induction"],
        ["George James",        "2136110", "29/07/1968", "BN19500R8", "Exempt from induction"],
        ["Carol Burns",         "1058354", "02/04/1991", "27313BJL9", "Failed induction"],
        ["Nicola Borschmann",   "2467487", "02/02/1975", "532B10J1A", "Failed induction"],
        ["John Smith",          "1247646", "19/06/1986", "6J8B903G8", "Failed induction in Wales"],
        ["Jim Laney",           "3002065", "01/01/1990", "OA046772B", "Failed induction in Wales"],
        ["Dona Msa",            "3003943", "02/02/1964", "AB722128C", "No QTS"],
        ["George Orwell",       "2632412", "16/02/1984", "",          "Prohibited from teaching"],
        ["Neils Clarke-Dolan",  "2908239", "12/08/1978", "",          "Prohibited from teaching"],
      ]
    end

    def rows_with_buttons
      rows.map do |row|
        _name, trn, dob, national_insurance_number, _notes = row
        row + [populate_button(trn, dob, national_insurance_number)]
      end
    end

    def populate_button(trn, dob, national_insurance_number)
      tag.button 'Select',
                 class: 'govuk-button govuk-button--secondary govuk-button--small populate-find-ect-form-button',
                 type: 'button',
                 data: { trn:, dob:, national_insurance_number: }
    end
  end
end
