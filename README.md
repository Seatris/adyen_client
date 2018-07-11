# A simple client that talks to the Adyen API

[![Inline docs](http://inch-ci.org/github/Overbryd/adyen_client.svg?branch=master)](http://inch-ci.org/github/Overbryd/adyen_client)

> Does not try to be smart, stays close to the documentation while adhering to Ruby conventions.

## Setup & Configuration

`gem install adyen_client`

In your Gemfile:

`gem "adyen_client"`

Require and configure the client:

```ruby
require "adyen_client"

# Block style
AdyenClient.configure do |c|
  c.environment = :test
  c.username = "ws_123456@Company.FooBar"
  c.password = "correctbatteryhorsestaple"
  c.cse_public_key = "10001|..."
  c.default_merchant_account = "FooBar123"
  c.default_currency = "EUR"
end

# Hash style works too, string or symbol keys
AdyenClient.configure(environment: :test, username: "ws_123456@Company.FooBar", ...)

# That comes in handy to configure the client from a YAML file
AdyenClient.configure(YAML.load_file(Rails.root.join("config", "adyen.yml"))[Rails.env.to_s])

# You can override all default_* options for each instance of a client
client = AdyenClient.new(merchant_account: "FooBarSubMerchant123")
eur_client = AdyenClient.new(currency: "EUR")
```

## Examples

### Simple payment

```ruby
client = AdyenClient.new
response = client.authorise(amount: 100, encrypted_card: "adyenjs_0_1_15$OlmG...")
if response.authorised?
  puts "( ﾉ ﾟｰﾟ)ﾉ"
else
  puts "(－‸ლ)"
end
```

### Setup a recurring contract, charge users later

```ruby
user = User.create(email: "john@doe.com", last_ip: request.remote_ip)

client = AdyenClient.new
response = client.create_recurring_contract(encrypted_card: "adyenjs_0_1_15$OlmG...", shopper: {
  reference: user.id,
  email: user.email,
  ip: user.last_ip # optional but recommended
})
if response.authorised?
  # now we know the users card is valid
else
  # something is wrong with the users card or we got an error
end
```

Later, we want to charge the user based on that contract.

```ruby
user = User.find_by_email("john@doe.com")

client = AdyenClient.new
response = client.authorise_recurring_payment(amount: 1699, shopper: { reference: user.id })
if response.authorised?
  # we know the payment is on its way
else
  # something is wrong, maybe we got an error
end
```

## Tests

Run tests with minitest:

```bash
ruby -Ilib:test spec/unit/adyen_client_response_spec.rb
ruby -Ilib:test spec/unit/adyen_client_spec.rb
ruby -Ilib:test spec/unit/adyen_client_utils_spec.rb
```


## Documentation

All publicly usable [methods and classes are documented here](http://rdoc.info/projects/Overbryd/adyen_client).

This library does not try to be too smart, it simply provides a layer of abstraction on top of the Adyen JSON API.
Also the default `AdyenClient::Response` class basically just wraps the JSON response.
The only work it does is converting `camelCase` keys to `sneak_case`, removing unnecessary object nestings and providing you with a convenience `authorised?` method.

If you want a more sophisticated response class, you can easily hook up your own.
The only method you need to provide is `::parse`. It will receive one argument, the [`HTTParty::Response`](http://www.rubydoc.info/github/jnunemaker/httparty/HTTParty/Response) for the given request.

```ruby
class MyAdyenResponse
  def self.parse(http_response)
    # ... your fancy code
  end
end
```

Hook it up by initialising the client like this: `AdyenClient.new(response_class: MyAdyenResponse)`.

Similar, if you want nothing else than the bare `HTTParty::Response`, initialise the client with: `response_class: nil`.


## Contributing

I am very happy to receive pull requests or bug reports for problems with the library.
Please make sure you are only reporting an actual issue with the library itself, I cannot help with your payment flow or advise you on anything related to the Adyen API.

## Disclaimer

I am not associated with Adyen in any way.
If you have problems with your adyen account or your payment flow, please contact the very helpful Adyen support using `support ät adyen.com`.

Please make yourself comfortable [with the Adyen documentation](https://docs.adyen.com/) on how you want to setup your payment flow.

## License

The MIT License (MIT), Copyright (c) 2015 Lukas Rieder

See [`LICENSE`](https://github.com/Overbryd/adyen_client/blob/master/LICENSE).

