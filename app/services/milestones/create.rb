module Milestones
  class Create
    attr_reader :author,
                :milestone

    def initialize(author:, schedule:, params:)
      @author = author
      @milestone = Milestone.new(schedule:, **params)
    end

    def create!
      ActiveRecord::Base.transaction do
        milestone.save!
        record_event!
      end

      milestone
    end

  private

    def record_event!
      Events::Record.record_milestone_added_event!(author:, milestone:)
    end
  end
end
