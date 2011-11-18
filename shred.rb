require 'chunky_png'
include ChunkyPNG

file, shreds = ARGV
image = Image.from_file(path)

extension = File.extname(path)
output_path = path.sub(extension, "-shredded#{extension}")

shredded = Image.new(image.width, image.height)

shred_width = width/shreds
sequence = range(0, SHREDS)
shuffle(sequence)

(0...shreds).to_a.shuffle.each_with_index do |source_index, shred_index|
  
end

for i, shred_index in enumerate(sequence):
      shred_x1, shred_y1 = shred_width * shred_index, 0
      shred_x2, shred_y2 = shred_x1 + shred_width, height
          region =image.crop((shred_x1, shred_y1, shred_x2, shred_y2))
              shredded.paste(region, (shred_width * i, 0))

              shredded.save(“sample_shredded.png”)
end
