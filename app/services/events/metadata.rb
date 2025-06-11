class Events::Metadata
  include Enumerable

  attr_reader :author, :appropriate_body, :description, :mentor_id, :mentee_id,
              :batch_id, :batch_type, :batch_status, :file_name, :file_size,
              :file_type, :rows, :total, :skipped, :passed, :failed, :released

  def initialize(author: nil, appropriate_body: nil, **attributes)
    @author = author
    @appropriate_body = appropriate_body

    # Set any additional attributes
    @description = attributes[:description]
    @mentor_id = attributes[:mentor_id]
    @mentee_id = attributes[:mentee_id]
    @batch_id = attributes[:batch_id]
    @batch_type = attributes[:batch_type]
    @batch_status = attributes[:batch_status]
    @file_name = attributes[:file_name]
    @file_size = attributes[:file_size]
    @file_type = attributes[:file_type]
    @rows = attributes[:rows]
    @total = attributes[:total]
    @skipped = attributes[:skipped]
    @passed = attributes[:passed]
    @failed = attributes[:failed]
    @released = attributes[:released]
  end

  # Make it behave like a hash
  delegate :[], to: :to_hash

  def each(&block)
    to_hash.each(&block)
  end

  def to_hash
    {
      author:,
      appropriate_body:,
      description:,
      mentor_id:,
      mentee_id:,
      batch_id:,
      batch_type:,
      batch_status:,
      file_name:,
      file_size:,
      file_type:,
      rows:,
      total:,
      skipped:,
      passed:,
      failed:,
      released:
    }.compact
  end
end
