[![Gem Version](https://badge.fury.io/rb/pscb_integration.svg)](https://badge.fury.io/rb/pscb_integration)
[![Build Status](https://travis-ci.org/holyketzer/pscb_integration.svg?branch=master)](https://travis-ci.org/holyketzer/pscb_integration)
[![Code Climate](https://codeclimate.com/github/holyketzer/pscb_integration/badges/gpa.svg)](https://codeclimate.com/github/holyketzer/pscb_integration)
[![Test Coverage](https://codeclimate.com/github/holyketzer/pscb_integration/badges/coverage.svg)](https://codeclimate.com/github/holyketzer/pscb_integration/coverage)

# PSCB Integration

PSCB bank payment service integration (trade acquiring). 

Official documentation http://docs.pscb.ru/oos/

Offer https://pscb.ru/corp/services/payment_service/platezhi-v-internete/.

## Disclamer

Stay awhile and listen. Are you sure that you need this stuff?

### Pro:

* 3% fee for Visa/MasterCard payments

### Cons:

* During 1.5 years of our expirience PSCB lost all client's reccurent bingings twice. We lost a lot of revenue because of this.
* **Very slow** personal account web site, it takes tens of seconds to load a page.
* API looks not solid and have a lack of consistency, it has several ways to return errors in response 
* PSCB send demo environment payment callbacks to your production server, and if you don't handle them, they send you email like 'We have got invalid response for our HTTP-callbacks', so they can't completely split demo and production environments

### Your choise

It's up to you. Probably Yandex.Kassa will be better option, its [API](https://tech.yandex.ru/money/doc/payment-solution/shop-config/intro-docpage/) looks much more solid and reliable (it's Yandex anyway) but it has higher fee 3.5% on [base plan](https://kassa.yandex.ru/fees) for bank cards. But if you revenue more than 1 million RUB per month then only 2.8%. I suppose the choice is obvious here.


## Installation

I see you decided to try. Good luck and best wishes.

Add this line to your application's Gemfile:

```ruby
gem 'pscb_integration'
```

And then execute:

    $ bundle

## Usage

### Configuration

Configure it in `<you app folder>/config/initializers/pscb.rb` with:

```ruby
PscbIntegration.setup do |config|
  config.host = 'https://oos.pscb.ru'
  config.market_place = '<your market place id>'
  config.secret_key = '<your secret key>'
  config.demo_secret_key = '<your secret key for demo env>'
  config.confirm_payment_callback = PaymentService.method(:confirm_pscb_payment_callback)
end
```

If your application didn't setup `PscbIntegration` configuration with `setup` block then `PscbIntegration::ConfigurationError` will be raised during first attempt to call of any method.

### Handling payment status notification

Mount engine in your `routes.rb` file as you wish, e.g.:

```ruby
namespace :integration_api do
  mount PscbIntegration::Engine => '/'
end
```

Implement callback function assigned to `confirm_pscb_payment_callback`:

Arguments:
`payment` - hash with payment details from PSCB:

|Property          | Description|
|------------------|-------------------------------------|
|`orderId`         | Unique order id generated by merchant|
|`showOrderId`     | Not uniqe order id generated by merchant to show it to customer|
|`paymentId`       | Order id generated by PSCB|
|`account`         | Customer id on merchant side|
|`marketPlace`     | Merchant id on PSCB side|
|`paymentMethod`   | Payment method|
|`state`           | [Payment state](http://docs.pscb.ru/oos/api.html#api-dopolnitelnyh-vozmozhnostej-merchanta-sostoyaniya-platezha)|
|`stateDate`       | Date of last state changing ISO8601|
|`amount`          | Order amount|
|`recurrencyToken` | Recurrency token|

`is_demo` - if `true` then payment is from demo environment else from production.

Callback should return `true` if you system accepts and confirms payment, and `false` (`nil`) in case of rejecting. Example:

```ruby
def confirm_pscb_payment_callback(payment, is_demo)
  if (order = OrderModel.find_by(uid: payment['orderId']))
    # Some state machine transition
    order.apply_status(payment['state'])
  end
end
```

### Build payment url

[PSCB API documentation](http://docs.pscb.ru/oos/api.html#api-pskb-onlajn-dlya-merchantov-api-platezhnoj-stranicy)

```ruby
client = PscbIntegration::Client.new

url = client.build_payment_url(
  nonce: SecureRandom.hex(5), # Salt to avoid replay attack
  customerAccount: user.id, # Some user id
  customerRating: 5, # Customer rating 
  customerEmail: user.email, # Customer email
  customerPhone: user.phone, # Customer phone
  orderId: '123456', # Unique order id
  details: 'Some paymnet', # Payment details comment
  amount: 500, # Amount in RUB
  paymentMethod: 'ac', # Payment menthod
  recurrentable: true, # Payment can be repeated by merchant
  data: {
    debug: 1, # show debug info in customer browser 
  }
)
```

### Pull order status

[PSCB API documentation](http://docs.pscb.ru/oos/api.html#api-dopolnitelnyh-vozmozhnostej-merchanta-zapros-sostoyaniya-platezha)

`Client` methods return result in [Either monad](https://github.com/bolshakov/fear#either-documentation) for helping handling errors on different level. Thank you [@bolshakov](https://github.com/bolshakov).

How it works:

* `Right` result means success
* `Left` result means PSCB returns some conscious error which can require special handling on our side.
* any exception means unexpected error (e.g. timeout, network) that we don't know how to handle, and probably best option is to log it and try again later.

Learn more about [Either monad usage](https://github.com/bolshakov/fear#either-documentation). Example:

```ruby
client = PscbIntegration::Client.new

res = client.pull_order_status(order.id)

res.reduce(
  # Left result is handled here
  # @param error - PscbIntegration::BaseApiError
  ->(error) {
    # Some special error handling e.g.
    if error.unknown_payment?
      # Do something special
    end
  },

  # Right result is handled here
  # @param payment - payment hash from PSCB
  ->(payment) { 
    # Update order status
  }
)
```

### Recurring payment

[PSCB API documentation](http://docs.pscb.ru/oos/api.html#api-dopolnitelnyh-vozmozhnostej-merchanta-iniciaciya-povtornoj-oplaty)

Before this call you customer should successefully paid order with `recurrentable` flag. In callback or through status pulling `recurrency_token` will be returned.

```ruby
client = PscbIntegration::Client.new

res = client.recurring_payment(
    prev_order_uid: prev_order.id, # Previous recurrentable order id
    new_order_uid: new_order.id, # New order id
    token: recurrency_token, # Recurrency token from previous order 
    amount: 300, # Amount in RUB
)

res.reduce(
  ->(error) { },
  ->(payment) { },
)
```

### Refund order

[PSCB API documentation](http://docs.pscb.ru/oos/api.html#api-dopolnitelnyh-vozmozhnostej-merchanta-vozvrat-po-platezhu)

```ruby
client = PscbIntegration::Client.new

res = client.refund_order(order.id)

res.reduce(
  ->(error) { },
  ->(payment) { },
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/holyketzer/pscb_integration.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).