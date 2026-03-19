module TestGuidance
  class TRSFakeAPIInstructions < ApplicationComponent
    def list
      [
        "7000001 (QTS not awarded)",
        "7000002 (teacher not found)",
        "7000003 (prohibited from teaching)",
        "7000004 (teacher has been deactivated in TRS)",
        "7000005 (teacher has alerts but is not prohibited)",
        "7000006 (teacher is exempt from mentor funding)",
        "7000007 (teacher has passed their induction)",
        "7000008 (teacher has failed their induction)",
        "7000009 (teacher is exempt from training)",
        "7000010 (teacher has failed their induction in Wales)",
        "7000011 (teacher has been merged in TRS)",
      ]
    end
  end
end
