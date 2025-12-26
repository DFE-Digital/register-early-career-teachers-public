describe SpecObjectFormatter do
  let(:today) { Date.current }
  let(:now) { Time.zone.now }

  it "formats a hash and prints the keys and values" do
    input = { hello: "world" }

    expect(SpecObjectFormatter.new(input).formatted_object).to eql(<<~EXPECTED_OUTPUT.strip)
      {
        hello: "world"
      }
    EXPECTED_OUTPUT
  end

  it "formats dates as Ruby constructors" do
    input = { today: }

    expect(SpecObjectFormatter.new(input).formatted_object).to eql(<<~EXPECTED_OUTPUT.strip)
      {
        today: Date.new(#{today.year}, #{today.month}, #{today.day})
      }
    EXPECTED_OUTPUT
  end

  it "formats times as Ruby constructors" do
    input = { now: }

    expect(SpecObjectFormatter.new(input).formatted_object).to eql(<<~EXPECTED_OUTPUT.strip)
      {
        now: Time.new(#{now.year}, #{now.month}, #{now.day}, #{now.hour}, #{now.min}, #{now.sec})
      }
    EXPECTED_OUTPUT
  end

  it "works recursively" do
    input = { outer: { today:, now: } }

    expect(SpecObjectFormatter.new(input).formatted_object).to include("Date.new", "Time.new")
  end

  it "works with arrays of hashes" do
    input = { dates: [{ today: }, { today: }, { now: }] }

    formatted_object = SpecObjectFormatter.new(input).formatted_object

    expect(formatted_object).to include("Date.new").twice
    expect(formatted_object).to include("Time.new").once
  end

  it "calls inspect on any other objects" do
    input = { test: :test }

    expect(SpecObjectFormatter.new(input).formatted_object).to eql(<<~EXPECTED_OUTPUT.strip)
      {
        test: :test
      }
    EXPECTED_OUTPUT
  end
end
