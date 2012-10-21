# yahoo_sports
Ruby library for parsing stats from Yahoo! Sports pages. Currently supports
MLB, NBA, NFL and NHL stats and info.

[Source](http://github.com/chetan/yahoo_sports) available on github

## SYNOPSIS:

```ruby
require "yahoo_sports"
team = YahooSports::NHL.get_team_stats("nyr")
team.name # => "New York Rangers"
team.standing # => "11-9-1"
team.position # => "4th Atlantic"
team.last5[0].team # => "Edmonton Oilers (7-7-1)"
team.last5[0].status # => "W 4 - 2"
```

## FEATURES:

* Pull previous day and current days games for each sport
* Pull specific team information (full name, standing, game schedule)

## INSTALL:

```bash
# ruby 1.8
gem install yahoo_sports

# ruby 1.9
gem install yahoo_sports19
```

## DOCUMENTATION

Documentation is available online at [rdoc.info](http://rdoc.info/projects/chetan/yahoo_sports) or by running ```rake docs```

== LICENSE:

(The MIT License)

Copyright (c) 2012 Pixelcop Research, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
