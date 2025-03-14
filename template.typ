#let content = sys.inputs.text
#let font-name = "Iosevka NF"
#let paper-width = 12mm

// Function to calculate appropriate font size based on text length
#let calc-font-size(text-content) = {
  let base-size = 14pt
  let length-factor = calc.min(1.0, 5.25 / str.len(text-content))
  return base-size * length-factor
}


// Configure the document with fixed 12mm width
#set page(
  width: 12mm,
  height: 24mm,
  margin: (x: 0mm, y: 0mm)
)

#set par(leading: 0.35em)

// Calculate appropriate font size
#let font-size = calc-font-size(content)

// Configure the text
#set text(
  font: font-name,
  // Adjust font size to fit well on 12mm paper
  size: 14pt,
  fill: black,
  weight: "bold"
)

#align(center + horizon)[#rotate(90deg, content)]
