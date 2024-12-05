# Net::Hippie

[![Gem Version](https://badge.fury.io/rb/net-hippie.svg)](https://rubygems.org/gems/net-hippie)
[![Build Status](https://github.com/xlgmokha/net-hippie/workflows/Test/badge.svg)](https://github.com/xlgmokha/net-hippie/actions)

`Net::Hippie` is a light weight wrapper around `net/http` that defaults to
sending `JSON` messages.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'net-hippie'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install net-hippie

## Usage

```ruby
require 'net/hippie'

Net::Hippie.logger = Logger.new(STDERR)

headers = {
  'Accept' => 'application/vnd.haveibeenpwned.v2+json'
}

uri = 'https://haveibeenpwned.com/api/breaches'
response = Net::Hippie.get(uri, headers: headers)
puts JSON.parse(response.body)
```

```ruby
response = Net::Hippie.post(
  'https://example.org',
  body: { name: 'hippie' }
)
puts JSON.parse(response.body)
```

Net::Hippie also supports TLS with client authentication.

```ruby
client = Net::Hippie::Client.new(
  certificate: ENV['CLIENT_CERTFICIATE'],
  key: ENV['CLIENT_KEY']
)
```

If your private key is encrypted you may include a passphrase to decrypt it.

```ruby
client = Net::Hippie::Client.new(
  certificate: ENV['CLIENT_CERTFICIATE'],
  key: ENV['CLIENT_KEY'],
  passphrase: ENV['CLIENT_KEY_PASSPHRASE']
)
```

To disable logging you will need to override the default logger.

```ruby
client = Net::Hippie::Client.new(logger: nil)
```

### Basic Auth

```ruby
Net::Hippie.get(
  'https://www.example.org',
  headers: {
    'Authorization' => Net::Hippie.basic_auth('username', 'password')
  }
)
```

### Bearer Auth

```ruby
headers = { 'Authorization' => Net::Hippie.bearer_auth('token') }
Net::Hippie.get('https://www.example.org', headers: headers)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/test` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bin/shipit`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/xlgmokha/net-hippie.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
