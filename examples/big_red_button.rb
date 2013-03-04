require 'rubygems'
require '../lib/dream_cheeky_button'

DreamCheekyButton.run do
  open do
    puts "open"
  end

  close do
    puts "closed"
  end

  push do
    puts "pushed"
  end
end