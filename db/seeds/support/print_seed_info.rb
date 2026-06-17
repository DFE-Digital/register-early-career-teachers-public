def print_seed_info(text, indent: 0, colour: nil, blank_lines_before: 0, error: false)
  return if Rails.env.test?

  emoji = error ? "❌️" : "🌱"

  prefix = emoji + " "

  blank_lines_before.times { puts "#{emoji}\n" }

  if colour
    puts prefix + (" " * indent) + Colourize.text(text, colour)
  else
    puts prefix + (" " * indent) + text
  end
end
