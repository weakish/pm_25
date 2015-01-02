# Pm25

[![Gem Version](https://badge.fury.io/rb/pm_25.svg)](http://badge.fury.io/rb/pm_25)

A Ruby wrapper for pm25.in API and other PM 2.5 related utility functions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pm_25'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pm_25

## Usage

```ruby
require 'pm_25'
PM25.Func(args)
```

The following APIs of pm25.in are implemented:

- 1.1 `pm25` Get PM 2.5 info of all stations in the specified city.
- 1.11 `available_cities` Get a list of cites providing PM 2.5 data.
- 1.12 `all_cities` Get PM 2.5 data for all cities.
- 1.13 `aqi_ranking` Get average data for all cities. (Cities are sorted by
AQI.)

`1.1`, `1.11` etc are for reference of [pm25.in official api
documentation][api_doc].

[api_doc]: http://www.pm25.in/api_doc

I only implemented APIs I care, and I guess in most cases these is the APIs
you actually want to use.

However, if you do need other APIs, feel free to send a pull request.
You can use `PM25.access_api`. (Actually implementing other APIs is trivial
with this.)

pm25.in requires a token to access its api.
You can apply one at [here][api_doc].

`pm25` will look for a token in the following order:

- Token argument when invoking functions.
- Environment virable `PM25_IN_TOKEN`
- `"PM25_IN_TOKEN": 'your_token'` in `config.json` at the current directory.
- The default test token at [pm25.in official api documentation][api_doc].

Note that the test token is barely usable (too many people use it).

If you does not have a token, you can use `bing_pm25` to get the average
PM 2.5 value for the specified city.
This function uses data from bing.com, thus does not need a token.
For example:

```ruby
PM25.bing_pm25 '北京'
```

pm25.in uses CN standard for AQI category.
If you want to use US standard instead, use `pm25_level`.
For example:

```ruby
PM25.pm25_level(123)
```

It will return a hash containing:

- PM 2.5 value
- AQI category
- AQI category meaning
- suggested action

For other functions and usage details, check API documentation:

http://www.rubydoc.info/gems/pm25/

### Command line usage

We also provide a command line utility to query PM 2.5 info for the
specified city:

```sh
; PM25_IN_TOKEN='your_token' pm25 北京
北京: 106, Unhealthy
Everyone may begin to experience health effects; members of sensitive groups may
experience more serious health effects.
People with heart or lung disease, children and older adults should avoid
prolonged or heavy exertion. Everyone else should reduce prolonged or heavy
exertion.
```

If you does not provide a city argument, it will use environment variable `PM25_IN_CITY`.

If something goes wrong with pm25.in, (say, you does not provide a token), it
 will use bing.com instead.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/pm25/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
