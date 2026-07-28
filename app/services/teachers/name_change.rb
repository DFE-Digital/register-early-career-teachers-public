module Teachers
  class NameChange
    def initialize(current_name, new_name)
      @current_name = current_name.to_s
      @new_name = new_name.to_s
    end

    def significant?
      first_word_changed? && last_word_changed?
    end

  private

    attr_reader :current_name, :new_name

    def first_word_changed?
      normalise(words(current_name).first) != normalise(words(new_name).first)
    end

    def last_word_changed?
      normalise(words(current_name).last) != normalise(words(new_name).last)
    end

    def words(name)
      name.split
    end

    def normalise(word)
      I18n.transliterate(word.to_s).downcase.gsub(/[^a-z0-9]/, "")
    end
  end
end
