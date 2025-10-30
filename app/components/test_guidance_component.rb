class TestGuidanceComponent < ApplicationComponent
  renders_one :trs_example_teacher_details, "TRSExampleTeacherDetails"
  renders_one :trs_fake_api_instructions, "TRSFakeAPIInstructions"

  def render?
    Rails.application.config.enable_test_guidance &&
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
    EXEMPT_FROM_INDUCTION     = "Exempt from induction"
    FAILED_INDUCTION          = "Failed induction"
    FAILED_INDUCTION_IN_WALES = "Failed induction in Wales"
    NO_MENTOR_FUNDING         = "No mentor funding"
    NO_QTS                    = "No QTS"
    PASSED_INDUCTION          = "Passed induction"
    PROHIBITED_IN_PROGRESS    = "Prohibited from teaching (In progress)"
    PROHIBITED_PASSED         = "Prohibited from teaching (Passed)"

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
        ["Muhammed Ali",        "3002580", "04/03/1955", "BJ833983C", NO_MENTOR_FUNDING],
        ["Robson Scottie",      "3002582", "11/05/1980", "WX999679C", NO_MENTOR_FUNDING],
        ["Rebecca Jones",       "1209937", "12/10/1993", "J698546XA", PASSED_INDUCTION],
        ["Joseph Waller",       "1062313", "30/05/1988", "1A7T689J2", PASSED_INDUCTION],
        ["Jacqueline Bartlett", "2057184", "31/08/1976", "82063AJE7", EXEMPT_FROM_INDUCTION],
        ["George James",        "2136110", "29/07/1968", "BN19500R8", EXEMPT_FROM_INDUCTION],
        ["Carol Burns",         "1058354", "02/04/1991", "27313BJL9", FAILED_INDUCTION],
        ["Nicola Borschmann",   "2467487", "02/02/1975", "532B10J1A", FAILED_INDUCTION],
        ["John Smith",          "1247646", "19/06/1986", "6J8B903G8", FAILED_INDUCTION_IN_WALES],
        ["Jim Laney",           "3002065", "01/01/1990", "OA046772B", FAILED_INDUCTION_IN_WALES],
        ["Dona Msa",            "3003943", "02/02/1964", "AB722128C", NO_QTS],
        ["Claire Cool",         "3012235", "03/01/1993", "BB123456C", NO_QTS],
        ["Linda Belcher",       "3012238", "01/12/1980", "QQ123456C", NO_QTS],
        ["James Rocket",        "3012239", "26/11/1976", "AA223456C", NO_QTS],
        ["Buffy Summers",       "3012240", "09/09/1987", "AA333456C", NO_QTS],
        ["Ash Ketchum",         "3012241", "25/01/2000", "QQ553456C", NO_QTS],
        ["Jigglypuff Jewels",   "3012242", "05/01/1993", "QQ773456C", NO_QTS],
        ["Clefairy Cuddles",    "3012243", "09/01/1993", "QQ993456C", NO_QTS],
        ["Bulbasaur Brown",     "3012244", "19/01/1992", "QQ893456C", NO_QTS],
        ["Squirtle Samuels",    "3012245", "19/03/1992", "QQ123445C", NO_QTS],
        ["Ditto Debbie",        "3012246", "28/04/1970", "QQ783445C", NO_QTS],
        ["Butterfree Barnaby",  "3012247", "18/06/2002", "QQ799445C", NO_QTS],
        ["George Orwell",       "2632412", "16/02/1984", "",          PROHIBITED_IN_PROGRESS],
        ["Neils Clarke-Dolan",  "2908239", "12/08/1978", "",          PROHIBITED_PASSED],
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
