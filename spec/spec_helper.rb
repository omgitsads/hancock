require 'rubygems'
require 'pp'
gem 'selenium-client', '~>1.2.10'
gem 'rspec', '~>1.1.12'
require 'spec'
require 'sinatra/test'
require 'dm-sweatshop'

$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'hancock'
gem 'webrat', '~>0.4.2'
require 'webrat/sinatra'

gem 'rack-test', '~>0.1.0'
require 'rack/test'

require File.dirname(__FILE__)+'/matchers'

require File.expand_path(File.dirname(__FILE__) + '/fixtures')
DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.auto_migrate!

Webrat.configure do |config|
  if ENV['SELENIUM'].nil?
    config.mode = :sinatra
  else
    config.mode = :selenium
    config.application_framework = :sinatra
    config.application_port = 4567
    require 'webrat/selenium'
  end
end

Hancock::App.set :environment, :development

module HancockTestApp
  module Helpers
    def landing_page
      <<-HAML
%h3 Hello #{session_user.first_name} #{session_user.last_name}!
- unless @consumers.empty?
  %ul#consumers
    - @consumers.each do |consumer|
      %li
        %a{:href => consumer.url}= consumer.label
HAML
    end
  end
  def self.registered(app)
    app.helpers Helpers
    app.set :sessions, true
    app.get '/' do
      ensure_authenticated
      @consumers = ::Hancock::Consumer.visible
      @consumers += ::Hancock::Consumer.internal if session_user.internal?
      haml landing_page
    end
  end
end
Hancock::App.register(HancockTestApp)

Spec::Runner.configure do |config|
  def app
    @app = Rack::Builder.new do
      run Hancock::App
    end
  end

  def login(user)
    post '/sso/login', :email => user.email, :password => user.password
  end

  config.include(Rack::Test::Methods)
  config.include(Webrat::Methods)
  config.include(Webrat::Matchers)
  config.include(Hancock::Matchers)

  unless ENV['SELENIUM'].nil?
    config.include(Webrat::Selenium::Methods)
    config.include(Webrat::Selenium::Matchers)
  end
end
