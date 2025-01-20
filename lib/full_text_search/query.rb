module FullTextSearch
  class Query
    def initialize(string)
      @string = string
    end

    # splits a string and adds the suffix ':*', which allows
    # us to search for partial words, so 'Jo' would match 'John'
    # and 'Joey'
    #
    # the segments are joined with '&' so 'Jo Sm' would return
    # 'John Smith' but not 'Joan Jones'
    #
    # https://www.postgresql.org/docs/current/datatype-textsearch.html#DATATYPE-TSQUERY
    def search_by_all_prefixes
      @string.split.map { |w| w + ":*" }.join(" & ")
    end
  end
end
