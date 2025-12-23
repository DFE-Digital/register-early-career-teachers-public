class ECF1HistoryExporter
  def initialize(trn:)
    @trn = trn
  end

  def export
    data = Migration::User
      .eager_load(:teacher_profile, participant_identities:)

    puts { "hello" => "world" }
  end
end
