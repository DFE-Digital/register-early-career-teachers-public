namespace :extensions do
  desc "Generate induction extension events for post-release ABs"
  task backfill: :environment do
    logger = Logger.new($stdout)
    logger.info "Backfilling InductionExtension events..."
    author = Events::SystemAuthor.new

    # teacher_id      appropriate_body_id   induction_extension_id
    data = [
      [28_670, 	      388, 	                1160],
      [23_641, 	      469, 	                1169],
      [23_789, 	      386, 	                1161],
      [28_396, 	      62,                   1170],
      [12_789, 	      390, 	                1162],
      [18_534, 	      288, 	                1171],
      [32_529, 	      347, 	                1163],
      [68_234, 	      326, 	                1164],
      [29_393, 	      396, 	                1165],
      [24_108, 	      330, 	                1166],
      [35_991, 	      330, 	                1167],
      [70_688, 	      416, 	                1168],
    ]

    data.map do |teacher_id, appropriate_body_id, induction_extension_id|
      teacher = Teacher.find(teacher_id)
      appropriate_body = AppropriateBody.find(appropriate_body_id)
      induction_extension = InductionExtension.find(induction_extension_id)
      full_name = Teachers::Name.new(teacher).full_name
      logger.info "#{appropriate_body.name} extended #{full_name}'s induction by #{induction_extension.number_of_terms}"

      Events::Record.record_appropriate_body_adds_induction_extension_event!(
        author:,
        appropriate_body:,
        teacher:,
        induction_extension:,
        modifications: [
          { 'number_of_terms' => [0.0, induction_extension.number_of_terms] }
        ],
        happened_at: induction_extension.created_at
      )
    end
  end
end
