module Milestones
  class Destroy
    attr_reader :milestone, :author

    def initialize(author:, milestone:)
      @author = author
      @milestone = milestone
    end

    def destroy!
      ActiveRecord::Base.transaction do
        record_event!
        milestone.destroy!
      end
    end

  private

    def record_event!
      Events::Record.record_milestone_deleted_event!(author:, milestone:)
    end
  end
end
