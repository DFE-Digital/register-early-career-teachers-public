RSpec.describe Colourize do
  describe ".text" do
    Colourize::COLOURS.each_key do |key|
      it "wraps text in ANSI colour code #{key}" do
        expect(described_class.text("Mary had a little lamb", key)).to eq "\e[#{Colourize::COLOURS[key]};#{Colourize::MODES[:bold]}mMary had a little lamb\e[#{Colourize::MODES[:clear]}m"
      end
    end

    it "uses bold as the default mode" do
      expect(described_class.text("Woah!", :cyan)).to eq "\e[#{Colourize::COLOURS[:cyan]};#{Colourize::MODES[:bold]}mWoah!\e[#{Colourize::MODES[:clear]}m"
    end

    it "handles a single mode option" do
      expect(described_class.text("Amazing!", :red, :italic)).to eq "\e[#{Colourize::COLOURS[:red]};#{Colourize::MODES[:italic]}mAmazing!\e[#{Colourize::MODES[:clear]}m"
    end

    it "handles multiple mode options" do
      modes = %i[bold underline]

      expect(described_class.text("Ka-pow!", :green, modes)).to eq "\e[#{Colourize::COLOURS[:green]};#{Colourize::MODES.values_at(*modes).join(';')}mKa-pow!\e[#{Colourize::MODES[:clear]}m"
    end

    it "handles a nil mode param" do
      expect(described_class.text("Wowzers!", :magenta, nil)).to eq "\e[#{Colourize::COLOURS[:magenta]}mWowzers!\e[#{Colourize::MODES[:clear]}m"
    end
  end
end
