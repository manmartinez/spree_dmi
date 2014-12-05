Spree DMI
=========

[![Circle CI](https://circleci.com/gh/manmartinez/spree_dmi.svg?style=svg&circle-token=6469ead150cd3770e7f70ac8a568863268cbcc2d)](https://circleci.com/gh/manmartinez/spree_dmi) [![Code Climate](https://codeclimate.com/github/manmartinez/spree_dmi/badges/gpa.svg)](https://codeclimate.com/github/manmartinez/spree_dmi)


Send your Spree orders to DMI, sync shipment status and keep track of your inventory on both sides

Installation
------------

Add spree_dmi to your Gemfile:

```ruby
gem 'spree_dmi'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_dmi:install
```

Testing
-------

First bundle your dependencies, then run `rake`. `rake` will default to building the dummy app if it does not exist, then it will run specs. The dummy app can be regenerated by using `rake test_app`.

```shell
bundle
bundle exec rake
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_dmi/factories'
```

Copyright (c) 2014 Manuel Martínez, released under the New BSD License
