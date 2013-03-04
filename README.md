# dream_cheeky_button

A gem for handling the Dream Cheeky Big Red Button.
Based on code from https://github.com/derrick/dream_cheeky


## Support

Only tested on Ubuntu with the Big Red Button

## Usage

```ruby
require 'rubygems'
require 'dream_cheeky_button'

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
```
