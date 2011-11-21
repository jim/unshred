require 'minitest/spec'
require 'minitest/autorun'

shredded_path = File.expand_path('../shredded', __FILE__)
tmp_path = File.expand_path('../tmp', __FILE__)
shredded_images = Dir[shredded_path + "/*.png"]

def images_should_match(first, second)
  output = `gm compare -verbose -metric mae #{first} #{second}`
  output.include?('Total: 0.0000000000        0.0').must_equal(true, "#{first} and #{second} differed")
end

describe 'Unshredding' do
  before do
    `mkdir -p #{tmp_path}`
  end

  after do
    `rm #{tmp_path}/*.png`
  end

  shredded_images.each do |shredded_path|
    it "should unshred #{File.basename(shredded_path)}" do
      unshredded_path = shredded_path.sub('shredded', 'tmp').sub('shredded', 'restored')
      original_path = shredded_path.sub('shredded', 'original').sub('_shredded', '')

      `ruby bin/unshred #{shredded_path} -o #{unshredded_path}`

      images_should_match(unshredded_path, original_path)
    end
  end
end
