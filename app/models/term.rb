class Term < Data.define(:first_day, :last_day)
  class << self
    def in_year(year)
      [
        new(Date.new(year, 6, 1), Date.new(year, 12, 31)),
        new(Date.new(year, 1, 1), Date.new(year,  3, 31)),
        new(Date.new(year, 4, 1), Date.new(year,  5, 31)),
      ]
    end

    def containing(date)
      in_year(date.year).find { it.cover? date }
    end

    def current = containing(Date.current)
  end

  def cover?(date) = (first_day..last_day).cover?(date)
end
