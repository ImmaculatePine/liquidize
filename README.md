# Liquidize

[![Build Status](https://travis-ci.org/ImmaculatePine/liquidize.svg?branch=master)](https://travis-ci.org/ImmaculatePine/liquidize)
[![Code Climate](https://codeclimate.com/github/ImmaculatePine/liquidize/badges/gpa.svg)](https://codeclimate.com/github/ImmaculatePine/liquidize)

Ruby library that adds [Liquid](http://liquidmarkup.org) template language support to your project.

## Installation

Add this line to your application's Gemfile:

    gem 'liquidize'

And then execute:

    $ bundle

## Usage

### PORO

Include `Liquidize::Model` mixin to your model and specify the liquidized attribute:

    class Page
      include Liquidize::Model
      attr_accessor :body
      liquidize :body
    end

Now you can set the body and render it with any options:

    page = Page.new
    page.body = 'Hello, {{username}}!'
    page.render_body(username: 'John') # => "Hello, John!"

Liquid works much faster if once parsed template is cached. Just add `liquid_*` pair attribute and Liquidize will use it to store dump of parsed template.

    class Page
      # ...
      attr_accessor :body, :liquid_body
      # ...
    end

### With ActiveRecord

Liquidize works the same way with ActiveRecord models. The only difference is that parsed template dump will be automatically saved before rendering if your model responds to `liquid_*` attribute.

    rails g model Email message:text liquid_message:text
    rake db:migrate

Liquidize it:

    class Email < ActiveRecord::Base
      include Liquidize::Model
      liquidize :message
    end

Use it the same way:

    email = Email.create(message: 'How are you doing, {{who}}?')
    email.render_message(who: 'friend') # parses template before rendering
    # => "How are you doing, friend?"

    # Now it won't parse template until message will be changed
    reloaded_email = Email.find(email.id)
    reloaded_email.render_message(who: 'sir') # does not parse it. Even after reload.
    # => "How are you doing, sir?"

    reloaded_email.message = 'Oops, I changed the message!'
    reloaded_email.render_message # parses template again
    # => "Oops, I changed the message!"

It makes record invalid if there are any syntax errors in the liquid template:

    email.message = 'Hey, {{username, I think, there is an error.'
    email.valid? # => false

    email.message = 'Hey, {{username}}, everything is ok now.'
    email.valid? # => true

## Contributing

1. Fork it (https://github.com/ImmaculatePine/liquidize/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
