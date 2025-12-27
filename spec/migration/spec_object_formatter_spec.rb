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
        now: Time.zone.local(#{now.year}, #{now.month}, #{now.day}, #{now.hour}, #{now.min}, #{now.sec})
      }
    EXPECTED_OUTPUT
  end

  it "works recursively" do
    input = { outer: { today:, now: } }

    expect(SpecObjectFormatter.new(input).formatted_object).to include("Date.new", "Time.zone.local")
  end

  it "works with arrays of hashes" do
    input = { dates: [{ today: }, { today: }, { now: }] }

    formatted_object = SpecObjectFormatter.new(input).formatted_object

    expect(formatted_object).to include("Date.new").twice
    expect(formatted_object).to include("Time.zone.local").once
  end

  it "calls inspect on any other objects" do
    input = { test: :test }

    expect(SpecObjectFormatter.new(input).formatted_object).to eql(<<~EXPECTED_OUTPUT.strip)
      {
        test: :test
      }
    EXPECTED_OUTPUT
  end

  describe "anonymising results" do
    it "replaces TRNs with a placeholder" do
      input = { a: "a", trn: "9876543", b: "b" }

      expect(SpecObjectFormatter.new(input).formatted_object).to eql(<<~EXPECTED_OUTPUT.strip)
        {
          a: "a",
          trn: "1111111",
          b: "b"
        }
      EXPECTED_OUTPUT
    end

    it "replaces names with a placeholder" do
      input = { a: "a", full_name: "Charlie Cox", b: "b" }

      expect(SpecObjectFormatter.new(input).formatted_object).to eql(<<~EXPECTED_OUTPUT.strip)
        {
          a: "a",
          full_name: "A Teacher",
          b: "b"
        }
      EXPECTED_OUTPUT
    end

    it "replaces SchoolData with a fake school and reuses the same information if repeated" do
      input = {
        data: [
          {
            school: {
              urn: 111_111,
              name: "The first school"
            }
          },
          {
            school: {
              urn: 222_222,
              name: "The second school"
            }
          },
          {
            school: {
              urn: 111_111,
              name: "The first school"
            }
          }
        ]
      }

      expect(SpecObjectFormatter.new(input).formatted_object).to eql(<<~EXPECTED_OUTPUT.strip)
        {
          data: [
            {
              school: {
                urn: "100001",
                name: "School 1"
              }
            },
            {
              school: {
                urn: "100002",
                name: "School 2"
              }
            },
            {
              school: {
                urn: "100001",
                name: "School 1"
              }
            }
          ]
        }
      EXPECTED_OUTPUT
    end
  end
end
