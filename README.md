# Unshred

This is a solution to the [Instagram Image Unshredding Challenge](http://instagram-engineering.tumblr.com/post/12651721845/instagram-engineering-challenge-the-unshredder).

## Requirements

* Ruby 1.9
* ChunkyPNG

All commands assume you are in the project directory, as I haven't
bothered to make this a real gem.

## Usage

This code works well for photographic images, but has some trouble with the old
TV test image.

Shred width detection is supported. To unshred an image:

    ruby bin/unshred path_to_image [-o OUTPUT_PATH]

Shredding of normal images is also supported:

    ruby bin/unshred path_to_image -s -w SHRED_WIDTH [-o OUTPUT_PATH]

To see the valid shred widths, run the previous command and omit the
`-w` option.

## Tests

    ruby test/unshred_test.rb

There is currently one failing test (the TV test image).
