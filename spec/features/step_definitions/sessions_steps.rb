Given /^I am not logged in on the sso provider$/ do
  @user = Hancock::User.new(:email      => /\w+@\w+\.\w{2,3}/.gen.downcase,
                            :first_name => /\w+/.gen.capitalize,
                            :last_name  => /\w+/.gen.capitalize)
  get "/sso/logout"
end

Given /^a valid consumer and user exists$/ do
  @consumer = ::Hancock::Consumer.gen(:internal)
  @user     = ::Hancock::User.gen
  get '/sso/logout'  # log us out if we're logged in
end

Then /^I login$/ do
  post "/sso/login", :email => @user.email,
                     :password => @user.password
end

Then /^I should see the login form$/ do
  last_response.should be_a_login_form
end

Then /^I should be redirected to the consumer app to start the handshake$/ do
  redirection = Addressable::URI.parse(last_response.headers['Location'])

  "#{redirection.scheme}://#{redirection.host}#{redirection.path}".should eql(@consumer.url)
  redirection.query_values['id'].to_i.should eql(@user.id)
end

Then /^I should be redirected to the sso provider root on login$/ do
  last_response.headers['Location'].should eql('/')
  follow_redirect!
end

When /^I request the landing page$/ do
  get '/'
end

Then /^I should see a list of consumers$/ do
  last_response.headers['Location'].should eql('/')
  follow_redirect!
end

Given /^I request authentication returning to the consumer app$/ do
  get "/sso/login?return_to=#{@consumer.url}"
end

Given /^I request authentication$/ do
  get "/sso/login"
end
