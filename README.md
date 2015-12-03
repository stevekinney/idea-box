# Idea Box

## Preamble

This is tutorial is the account of my first pass at IdeaBox. It test-drives the API from the ground up, implements some integration tests, adds support for displaying ideas, creating ideas, updating ideas, and adjusting the quality of ideas. It does not implement sorting, truncation, or filtering.

In addition, I placed myself under some additional constraints that I wouldn't have if I was just writing it on my own. I did not use anything that wasn't at least somewhat shown to you in the first three days of Module 4. This means, I could not use any of the following:

- Unit-testing JavaScript
- Mocks, stubs, and spies in JavaScript testing
- Object-oriented JavaScript
- Event delegation
- Advanced functional programming techniques

There is a lot I don't like in my implementation and we'll refactor it in future classes. My plan is to revisit this guide and add those features as we learn them throughout the module. We'll revist this application throughout the module. Feedback, suggestions, and pull requests are more than welcome.

## Getting Started

Let's get this thing off the ground. First things first, let's create a new Rails application with all of the bells and whistles that suit our fancy. You might choose to select different options, these are my tastes.

```shell
rails new idea-box --database=postgresql --skip-bundle --skip-turbolinks
```

Speaking of matters of taste, let's slim down the `Gemfile` a lille bit. We'll be adding more to it later, but this is a good starting place.

```rb
source 'https://rubygems.org'

gem 'rails', '4.2.4'
gem 'pg'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'

group :development, :test do
  gem 'pry-rails'
end

group :development do
  gem 'web-console', '~> 2.0'
  gem 'spring'
end
```

At this point, we can go ahead and `bundle install` to get all of our dependencies in place.

This seems as good a place as any to make our first commit.

```shell
git init
git add .
git commit -m "Initial commit"
```

## The `Idea` Model

The foundation of our Idea Box is the `Idea` model. So, let's go ahead and create one of those.

```shell
rails generate model idea title:string body:text quality:integer
```

The next step is to migrate the database with `rake db:create db:migrate`. (Keep in mind, you might already have a database with the same name if you've done this project before. Forewarned is forearmed.)

The specification says that, by default, all ideas start out at the lowest quality rating. Right now, `quality` is just an integer, so let's awesome that `0` represents the lowest possible quality.

Step one is to ourselves a nice little test in `test/models/idea_test.rb`. Let's replace the automatically generated—yet commented out—test with our own.

```rb
test "should have a quality that defaults to 0" do
  idea = Idea.new
  assert_equal(0, idea.quality)
end
```

That test should fail. Let's go ahead and make it pass. First, we'll generate a migration where we set a default value of `0` for the `quality` column in our database.

```shell
rails g migration AddDefaultToIdeaQuality
```

In the migration file you just generated, we'll add the following:

```rb
class AddDefaultToIdeaQuality < ActiveRecord::Migration
  def change
    change_column :ideas, :quality, :integer, default: 0
  end
end
```

Finally, we'll run `rake db:migrate` to run the migration we just set up. Let's run our tests with `rake` and verify that everything is passing. If it is, then we're ready to move on.

It's about that time again to make a commit.

```shell
git add app/models/idea.rb db/migrate/ db/schema.rb test/models/idea_test.rb
git commit -m "Generate idea model; default quality to zero"
```

### Quality Control

Some people love [`enums`][enums] and [some people][sean] hate them. We're going to use them for the sake of exposing you to them. You could just stick with using an interger to represent the quality of the idea. You could also just store the name of the value as a string if that's your sort of thing.

[enums]: http://edgeapi.rubyonrails.org/classes/ActiveRecord/Enum.html
[sean]: https://github.com/sgrif

To get started with `enums`, let's add the following to `app/models/idea.rb`:

```rb
class Idea < ActiveRecord::Base
  enum quality: [:swill, :plausible, :genius]
end
```

One nice thing about using `enums` is that we're implicitly creating a validation that the quality property will always be either "swill", "plausible", or "genius". We also got some nifty scopes for free. We can call `Idea.swill` or `Idea.plausible` and we'll receive the ideas of that quality.

Just for kicks, let's go ahead and run our test suite using `rake`.

Everything is gr—oh no, it looks like we have a failure on our hands. We changed the way that quality works. Our test is asserting that `quality` is `0`, but that's no longer the case. Adding the `enum` method has changed the way that `quality` works. `idea.quality` is now `"swill"`.

Let's update our test in `test/models/idea.rb` accordingly:

```rb
test "should have a quality that defaults to 0" do
  idea = Idea.new
  assert_equal("swill", idea.quality)
end
```

### Adding Validations

It's not in the project specification per se, but let's validate that each idea has at least a title. I don't really care to elaborate on all of my ideas with a `body`, but I'd at least like to have some kind of sense what my great idea was all about. You've probably done this a thousand times before, but that doesn't mean I'm going to throw caution to the wind, let's start with a few tests in `test/models/idea.rb`.

```rb
test "it should be invalid without a title or body" do
  idea_without_title_or_body = Idea.new

  refute(idea_without_title_or_body.valid?)
end

test "it should be invalid without a title" do
  idea = Idea.new(body: "body")

  refute(idea.valid?)
end

test "it should be invalid without a body" do
  idea = Idea.new(title: "title")

  refute(idea.valid?)
end

test "it is valid with a title and body" do
  idea_with_title_and_body = Idea.new(title: "title", body: "body")

  assert(idea_with_title_and_body.valid?)
end
```

Getting these tests to pass is pretty trivial.

```rb
class Idea < ActiveRecord::Base
  validates :title, :body, presence: true

  enum quality: [:swill, :plausible, :genius]
end
```

And, that should do it. It sounds like a good time for another commit.

```shell
git add app/models/idea.rb test/models/idea_test.rb
git commit -am "Add enum and validations"
```

## Setting Up Our Controller

Now that we have our model, it's time for us to expose an API that allows the user to retrieve, update, and delete some ideas. We'll start by generating a namespaced controller.

```shell
rails generate controller api/v1/ideas
```

A whole bunch of files were created on our behalf. We won't use a lot of these and it might have been a good idea to use Rails API instead of vanilla Rails, but that ship has sailed. Let's at least get rid of the obvious cruft.

```shell
rm -r app/assets/javascripts/api app/assets/stylesheets/api
```

So, now it's time to write a test to make sure that our API endpoint works (hint: it doesn't). We'll start by writing a test that we can hit it with JSON in `test/controllers/api/v1/ideas_controllers/test.rb`.

```rb
test "controller responds to json" do
  get :index, format: :json
  assert_response :success
end
```

If we go ahead and run our test, we'll see that it errors out because there is no route setup for that endpoint. Silly us. Let's go add it to our `routes.rb` file.

```rb
Rails.application.routes.draw do

  namespace :api do
    namespace :v1 do
      resources :ideas
    end
  end

end
```

Our next error states that there is no `index` action. This also makes sense, since we haven't set one up. We can address that in `app/controllers/api/v1/ideas_controller.rb`.

```rb
class Api::V1::IdeasController < ApplicationController

  def index
  end

end
```

Run and tests and—ugh, now it's complaining that there is no template. But we don't need a template, we're responding with JSON, right?

We'll need to add the `responders` gem to our `Gemfile` and `bundle`

```rb
gem 'responders'
```

We'll also need to update our controller as follows:

```rb
class Api::V1::IdeasController < ApplicationController
  respond_to :json

  def index
    respond_with Idea.all
  end

end
```

(Yes, we're sneakily preparing for a future requirement where we want them in reverse chronological order.)

Let's take one more stab at running our tests—and we're green! Let's go ahead and make another commit.

## Testing Our Controller Actions

**Nota bene**: If you don't like fixtures and prefer something like [factory_girl][fg], then you're welcome to use those instead.

[fg]: https://github.com/thoughtbot/factory_girl_rails

All of our interactions with the server are going to be through our API. So, it makes sense to get it fully in place. So far, we've stayed pretty vanilla with all of our tools. Let's continue down that road and take a look at using Rails fixtures. When we generated our `Idea` model, Rails went ahead and created `test/fixtures/ideas.yml`.

Let's customize our fixtures a bit to suit the needs of our application:

```yaml
one:
  title: First Idea
  body: Create world peace
  quality: 2

two:
  title: Second Idea
  body: Buy more potato chips
  quality: 0
```

These two fixtures will be seeded to our database by default whenever we run our test suite.

### Testing the Index Action

Now, if we have two ideas in our database, we can make some assumptions about what ought to happen when we hit the `index` action on our controller.

- We should get back a JSON response that contains an array
- That array should contain two ideas
- The first idea should have the title "First Idea"

You could certainly add a few more items to that list, but that's enough to get us to the level of confidence where we can be pretty certain that our `index` action is working as it should.

Let's start by writing a test to see if we're getting back an array from the controller.

```rb
test 'index returns an array of records' do
  get :index, format: :json

  assert_kind_of Array, response.body
end
```

If we run our test, we'll see that it fails. This initially might be a little surprising given that it looks kind of like an array if you squnit at the failure message. But, if you remember, we can only send strings over HTTP. We'll need to parse the string using `JSON.parse`. Let's update our test accordingly.

```rb
test 'index returns an array of records' do
  get :index, format: :json
  json_response = JSON.parse(response.body)

  assert_kind_of Array, json_response
end
```

Run our tests again and watch it pass.

### DRYing Up Our Tests

All of our responses from the server are going to be strings that we're going to have to parse to JSON. It would be super helpful if we didn't have to do it by hand every time we wrote a new test, right? Let's reopen `ActionController::TestCase` and add a method that give us back the parsed response in `test/test_helper.rb`. *Please note*, this is in addition to what is already in this file.

```rb
class ActionController::TestCase
  def json_response
    JSON.parse response.body
  end
end
```

We can now use this method in `test/controllers/api/v1/ideas_controller_test.rb`. Let's refactor our test as follows:

```rb
test 'index returns an array of records' do
  get :index, format: :json

  assert_kind_of Array, json_response
end
```

Run the test suite and verify that you have no new errors. Let's commit our changes and get ready to move on.

### Testing the Contents of Our Response

So, we know we have an array, but we probably want to test that this array has what we think it has in it. When we're using fixtures, they're given random `id` attributes, but we can grab a given fixture using the key defined in `test/fixtures/ideas.yml`.

For example, `ideas(:one)` will get us the fixture with the key of `one` in `test/fixtures/ideas.yml`.

As mentioned earlier, we want to verify that if we have two ideas in our database, we're getting two ideas out through our API and they are the ideas we think they are.

```rb
test '#index returns the correct number of ideas' do
  get :index, format: :json

  assert_equal Idea.count, json_response.count
end
```

Notice that I used `Idea.count` instead of 2. You and I both know there are two fixtures. But that's not totally clear to someone just reading our test suite. It's not clear to the reader why we are asserting the number 2. This is known as the [mystery guest pattern][] and we'd ideally like to avoid it, if at all possible. We've also gained the added benefit of being able to add and remove fixtures to our heart's content without messing up our tests.

[mystery guest pattern]: https://robots.thoughtbot.com/mystery-guest

We also want to make sure that we have well-formed ideas in our response. The order of our fixtures is not guaranteed and it's frankly not worth pinning down all of the small changes that occur between converting our ActiveRecord model into a simpler data structure (a hash), serializing it into a string, sending it out over the wire, and converting it back into a data structure. But, it is super important that each of the ideas we get from our API have a `title`, `body`, and `quality` property.

Let's go ahead and test that we have this properties:

```rb
test '#index contains ideas with the correct properties' do
  get :index, format: :json

  json_response.each do |idea|
    assert idea["title"]
    assert idea["body"]
    assert idea["quality"]
  end
end
```

It's about time for another commit, I think.

### Getting a Specific Idea

Okay, we can get all of the ideas, but what about getting just one idea in particular? Let's start with a test that verifies that we even have that endpoint.

```rb
test "controller responds to json" do
  id = ideas(:one).id

  get :show, id: id, format: :json
  assert_response :success
end
```

Ugh, we don't have that action available. So, let's go ahead and take care of that. I know it's not true TDD, but we'll also have it respond with the `Idea` in question so we don't have to go back and do this again. In `app/controllers/api/v1/ideas_controller.rb`, add the following method:

```rb
def show
  respond_with Idea.find(params[:id])
end
```

Run your tests and again and verify that it passes.

That's cool and all, but we also want to make sure it responds with the correct idea. Let's write a test for that.

```rb
test "#show responds with a particular idea" do
  id = ideas(:one).id

  get :show, id: id, format: :json

  assert_equal id, json_response["id"]
end
```

This test should pass out of the box. That's one of the fun advantages of using a framework. It does mostly the write thing in your behalf.

### Creating New Ideas

We can get all of the ideas in our fixtures. We can get a particular idea in our fixtures. What we can't do—yet—is create a new idea. Let's start with a pair of tests.

```rb
test "#create adds an additional idea to to the database" do
  assert_difference 'Idea.count', 1 do
    idea = { title: "New Idea", body: "Something" }

    post :create, idea: idea, format: :json
  end
end

test "#create returns the new idea" do
  idea = { title: "New Idea", body: "Something" }

  post :create, idea: idea, format: :json

  assert_equal idea[:title], json_response["title"]
  assert_equal idea[:body], json_response["body"]
  assert_equal "swill", json_response["quality"]
end
```

To no one's surprise, this test fails because we don't have that action in our controller. Let's head over to `app/controllers/api/v1/ideas_controller.rb` and add it. We'll need to do two things. Set up a private method that appease built-in security featrues in Rails.

```rb
def idea_params
  params.require(:idea).permit(:body, :title)
end
```

Then, we can set up our controller.

```rb
def create
  idea = Idea.new(idea_params)
  if idea.save
    respond_with(idea, status: 201, location: api_v1_idea_path(idea))
  else
    render json: { errors: idea.errors }, status: 422, location: api_v1_ideas_path
  end
end
```

What's happening here? We're creating a new `Idea` and then attempting to send it. If that works, we'll send the user a response with a 201 ("Created") status code from the location of that new resource. If it fails, then we'll send them a 422 ("Unprocessble Entity") status code and some information about what went wrong.

If we run our tests, they should pass at this point.

### The Unhappier Side of Creating Ideas

So, what happens if we send some bad data to our server? We probably want to make sure we're getting some helpful error messages and the appropriate status codes, right?

```rb
test "#create rejects ideas without a title" do
  idea = { body: 'Something' }
  number_of_ideas = Idea.all.count

  post :create, idea: idea, format: :json

  assert_response 422
  assert_includes json_response["errors"]["title"], "can't be blank"
end

test "#create rejects ideas without a body" do
  idea = { title: 'New Idea' }
  number_of_ideas = Idea.all.count

  post :create, idea: idea, format: :json

  assert_response 422
  assert_includes json_response["errors"]["body"], "can't be blank"
end
```

These should all pass, which makes this a good time for a commit.

### Updating Ideas

Alright, let's cut to the chase an implement a basic `update` action and then we'll write some tests to verify that it works the way we want it to. (I'm getting a bit tired at acting surprised when a test doesn't pass on a controller action I haven't defined.) In `app/controllers/api/v1/ideas_controller.rb`:

```rb
def update
  idea = Idea.find(params[:id])
  if idea.update(idea_params)
    respond_with(idea, status: 200, location: api_v1_idea_path(idea))
  else
    render json: idea.errors, status: 422
  end
end
```

It's backwards day, so we'll write a test after the fact:

```rb
test "#update an idea through the API" do
  updated_content = { title: "Updated Idea" }

  put :update, id: ideas(:one), idea: updated_content, format: :json
  ideas(:one).reload

  assert_equal "Updated Idea", ideas(:one).title
end
```

This is pretty similar to the `create` method with the exception that we need to reload the idea in order to get the updated information. This a good time to commit your changes.

### Changing the Quality of an Idea

We'll also need to promote and demote the quality of an idea. It's easier to worry about the logistics on the client and just send whatever want the new status to be to the server to save. Let's write a test to try this out.

```rb
test "#update the quality of an idea" do
  updated_content = { quality: "plausible" }

  put :update, id: ideas(:one), idea: updated_content, format: :json
  ideas(:one).reload

  assert_equal "plausible", ideas(:one).quality
end
```

Go ahead and run the test.

I'll wait.

It fails! Why? Because quality is not listed in `ideas_params` and Rails will not allow it. Let's add it to our strong parameters in `app/controllers/api/v1/ideas_controller.rb`.

```rb
def idea_params
  params.require(:idea).permit(:body, :title, :quality)
end
```

### The Unhappy Path and Enum Edge Cases

We should test the unhappy path as well. What happens if we send along an invalid quality?

```rb
test "#update rejects invalid quality values" do
  updated_content = { quality: "invalid" }

  put :update, id: ideas(:one), idea: updated_content, format: :json
  ideas(:one).reload

  assert_response 422
end
```

Oh boy or girl! Controller raises an `ArgumentError` and blows up. Enum properties get very angry when you assign an invalid attribute. Passing in a valid attribute is considered a application level error in Rails. So, it's on us to figure out a way to refactor this controller to get this test to pass.

**Full Disclosure**: You author now wishes he didn't use enums. If we had chosen to just use a string field with a default value, we could roughly the same interface. If we want to make an invalid enum not blow up, we're going to have to hack together a lot of logic in our controller. One of the things I'd love for you all to get out of Module 4 is to listen to that little voice in your head about not going down a bad path. That voice is ringing loud and clear in my head. So, I'm going to listen to it.

Let's stop what we're doing and make a commit.

### The Rescue Mission

Let's create a new branch for the purposes of conducting our rescue mission.

```
git checkout -b the-rescue-mission
```

Next, let's generate a migration.

```
rails g migration ChangeIdeaQualityFromIntegerToString
```

We'll run the migration.

```
rake db:migrate
```

Let's update our fixtures to use our new strings instead of integrers in `test/fixtures/ideas.yml`.

```yaml
one:
  title: First Idea
  body: Create world peace
  quality: genius

two:
  title: Second Idea
  body: Buy more potato chips
  quality: swill
```

Now, let's run the test suite and watch Rome burn. We should have five failures.

We know we're going to need to replace that enum method in our model. Let's start by getting rid of it. Your `app/models/idea.rb` should now look like this.

```rb
class Idea < ActiveRecord::Base
  validates :title, :body, presence: true
end
```


Run your tests.

That got us down to one failure. Even better is that was the same test that was failing before we started this mission. The issue is a little different. Before our application was blowing up. Now, we're just returning a 204 instead of telling the user they passed us an invalid attribute.

This is because we don't have an enum anymore, just a regular old string column. We'll take literally any kind of string. Let's add some validations to our model to shore things up a bit. We'll start with some tests in `test/models/idea_test.rb`.

```rb
test "it is valid with a quality of swill" do
  ideas(:one).quality = "swill"

  assert(ideas(:one).valid?)
end

test "it is valid with a quality of plausible" do
  ideas(:one).quality = "plausible"

  assert(ideas(:one).valid?)
end

test "it is valid with a quality of genius" do
  ideas(:one).quality = "genius"

  assert(ideas(:one).valid?)
end

test "it is invalid with any other quality" do
  ideas(:one).quality = "invalid"

  refute(ideas(:one).valid?)
end
```

To get these new model validation tests to pass, we'll need to add one additional validation to `app/models/idea.rb`.

```rb
class Idea < ActiveRecord::Base
  validates :title, :body, presence: true
  validates :quality, inclusion: { in: %w(swill plausible genius) }
end
```

Let's run our tests. They should pass. We avoided writing some hacky code to dance around some of limitations of enums by rethinking our design and listening to our gut. Commit these changes and let's merge our `the-rescue-mission` branch back into `master`.

### Deleting an Idea

Some ideas need to die. Let's write a test for deleting an idea.

```js
test "#destroy removes an idea" do
  assert_difference 'Idea.count', -1 do
    delete :destroy, idea: ideas(:one), format: :json
  end
end
```

Let's run the test. To our shock and surprise, it errors out because we don't have that action. We'll add it and try out an implementation in an attempt to avoid the "Missing Template" dance in `app/controllers/api/v1/idea_controllers.rb`.

```rb
def destroy
  Idea.find(params[:id]).destroy
  head :no_content
end
```

Run the tests and we should have 24 passing tests. And with that our API is complete. Along the way, we've tested the unhappy path, learned the implications of some poor design decisions, and rethought our approach. We're now ready to talk the client side of our application.

## The Client Side

Because we have some solid tests on our API, we can be relatively confident about what we're going to get from Rails at any given moment.

We'll be doing most of our interactions with JavaScript, but we still want to send over a simple view that will load and run our client-side code. Let's start with an integration test to make sure we can load at a view at our application root and verify that it has the elements we're expecting.

### Generate a Static Page Controller

Let's generate a controller for our static template.

```
rails g controller static
rm app/assets/javascripts/static.js
rm app/assets/stylesheets/static.scss
rm app/helpers/static_helper.rb
rm test/controllers/static_controller_test.rb
```

In `config/routes.rb`, let's have the root of our application point to our new static route.

```rb
root to: 'static#main'
```

We'll add a `main` action to our `app/controllers/static_controller.rb`.

```rb
def main
end
```

Finally, we'll make a template for this action.

```
touch app/views/static/main.html
```

### Getting the Basic Structure Up and Running

I know I'm going to want a few things on my page:

- An `<h1>` with the name of the application.
- A `<div>` with the class of `ideas` for rendering my ideas into.
- A form for creating new ideas.

In order to verify that things are actually on the page, we're going to have to bring in our furry little friend, Capybara. We'll add the following to gems to the development/test section of our `Gemfile`.

```rb
group :development, :test do
  gem 'pry-rails' # This was already here.
  gem 'capybara'
  gem 'launchy'
end
```

Go ahead and `bundle`. I'll wait.

#### Setting Up Capybara

We need to add some stuff to `test/test_helper.rb` in order to get up and running. The first is that we need to require `capybara/rails`.

```rb
require 'capybara/rails'
```

The second is that we'll want to add all of its rodenty goodness to our integration tests.

```rb
class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Rails.application.routes.url_helpers
end
```

Next, we'll generate a test.

```
rails g integration_test basic_template
```

This will generate a `test/integration/basic_template_test.rb` for us.

```rb
require 'test_helper'

class BasicTemplateTest < ActionDispatch::IntegrationTest

  test "it loads a page at the application root" do
    visit root_path
    assert_equal 200, page.status_code
  end

end
```

Run the test suite. Everything should pass. Getting the `<h1>` on the page should also be pretty straight-forward. We'll start with a test.

```rb
test "it has an <h1> tag with the content Idea Box" do
  visit root_path
  assert page.find("h1").has_content? "Idea Box"
end
```

It will fail, but getting it pass is easy. Add the following content to `app/views/static/main.html`.

```html
<h1>Idea Box</h1>
```

Run the tests again and verify that they all still pass. Now is a good time for a commit.

#### Adding the Form and Ideas Container

If you recall from earlier, we had three major things we wanted on this page.

- An `<h1>` with the name of the application.
- A `<div>` with the class of `ideas` for rendering my ideas into.
- A form for creating new ideas.

We got the first one on the page. Let's write some tests for the second two.

```rb
test "it has an ideas container on the page" do
  visit root_path
  assert page.has_css? ".ideas"
end

test "it has a form for creating new ideas" do
  visit root_path
  assert page.has_css? "form.new-idea"
end

test "form has an text input for a new idea title" do
  visit root_path
  assert page.has_css? "form.new-idea input[type='text'].new-idea-title"
end

test "form has an text input for a new idea button" do
  visit root_path
  assert page.has_css? "form.new-idea input[type='text'].new-idea-body"
end

test "form has an input button" do
  visit root_path
  assert page.has_css? "form.new-idea input[type='submit'].new-idea-submit"
end
```

I won't subject you to implementing each HTML element one at a time. Here is the basic HTML that I wrote to get the tests passing.

```html
<div class="container">

  <header>
    <h1>Idea Box</h1>
  </header>

  <section class="create-idea">
    <form class="new-idea">
      <div class="new-idea-field">
        <label class="new-idea-label">Idea Title</label>
        <input type="text" class="new-idea-title new-idea-input" name="idea[title]" placeholder="Idea Title">
      </div>
      <div class="new-idea-field">
        <label class="new-idea-label">Idea Body</label>
        <input type="text" class="new-idea-body new-idea-input" name="idea[body]" placeholder="Idea Body">
      </div>
      <div class="new-idea-messages"></div>
      <input type="submit" class="new-idea-submit" value="Submit Idea">
    </form>
  </section>

  <section class="ideas"></section>

</div>
```

**Side note**: I added some styles to make this more pleasant. You can see the styles I wrote in `app/assets/stylesheets/ideabox.scss`.

### Testing Some JavaScript with Capybara

It meakes sense that we're going to ned to test JavaScript eventually. So, let's go ahead and get that set up.

Let's install Poltergeist, which uses the Webkit rendering engine—the basis for Safari and Chrome. In our `Gemfile` add the following to the development and test section:

```rb
gem 'poltergeist'
```

We'll also add the following to `test/test_helper.rb`.

```rb
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
```

I've also added a helper method to my integration tests which makes it easy to switch over to Poltergeist whenever I need to.

```rb
class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Rails.application.routes.url_helpers

  def use_javascript
    Capybara.current_driver = Capybara.javascript_driver
  end

  def reset_driver
    Capybara.current_driver = nil
  end
end
```

Now, when I write a test, I can switch over to Poltergeist as follows:

```rb
test "something or other" do
  use_javascript
  visit root_path
  # Do some stuff
end
```

## Testing JavaScript

Rails is agnostic of unit tests and it's beyond the scope of this tutorial to get into trying to set up a bridge between a JavaScript unit testing framework and Rails's testing framework. (My goal is to show you some best approaches while also staying as close as possible to the tools you had at your disposal when embarking on this project. Later in the module, we can refine our approach with better tools.) This means that we'll be flying without a net for a bit, but we'll eventually be caught by our integration tests.

### Adding an Idea

We already have a form on the page, so let's get it working.

In order to add an idea, we need to do the following:

- Bind an event listener to the "Submit Idea" button.
- Stop the default browser action from happening. The default browser action would cause the browser to dump the page and request a new one.
- Get the values of the title and body fields in the new idea form.
- Send an AJAX POST request to the server.
- Deal with the response.
   - On success, prepend the idea to the list.
   - On failure, display an error message.

Let's write some functionality that handles the first three bullets a new file called `app/assets/javascripts/create_idea.js`.

```js
var newIdeaTitle, newIdeaBody;

$(document).ready(function () {
  newIdeaTitle = $('.new-idea-title');
  newIdeaBody = $('.new-idea-body');

  $('.new-idea-submit').on('click', createIdea);
});

function createIdea(event) {
  event.preventDefault();
  console.log(getNewIdea());
}

function getNewIdea() {
  return {
    title: newIdeaTitle.val(),
    body: newIdeaBody.val()
  };
}
```

We'll make room for `newIdeaTitle` and `newIdeaBody` in the global scope. When the document is ready, we'll assign values to those variables by way of `getIdeaPropertiesFromForm`. We'll also bind `createIdea` as an event listener to the "Submit Idea" button. Right now, it will just log to the console for a moment. In a perfect world, we could use Mocha to unit test that every step of the way, but writing JavaScript in Rails is always a bit of a compromise.

In `idea_respository.js`, we'll add a new method to `IdeaRepository` for creating new methods.

```js
var IdeaRepository = {
  create: function (idea) {
    return $.post('/api/v1/ideas', {idea: idea});
  }
};
```

Our `IdeaRepository` abstraction will take advantage of formatting the data and keeping track of the endpoint for us.

Let's finally get around to writing a test, shall we?

```rb
test "it creates a new idea upon form submission" do
  assert_difference 'Idea.count', 1 do
    page.fill_in "idea[title]", with: 'Special Idea'
    page.fill_in "idea[body]", with: 'World domination'
    page.click_button "Submit Idea"
  end
end
```

We'll update our `createIdea` function to actually send a request.

```js
function createIdea(event) {
  event.preventDefault();
  IdeaRepository.create(getNewIdea());
}
```

#### The Hassles of Asynchrous Code and Multiple Threads

There are two reasons why this test will never pass. First, is that we're firing an AJAX request and the test will validate the assertion before it actually fires. The second is that our integration test is running on a different thread than our database.

We'll have to implement two little features in order to get everything moving along.

1. Our test suite is not goin to wait for the AJAX to complete before testing if our new idea is in the database.
2. Our Poltergeist instance is running on a different thread from our database test. The Rails default of using transactions isn't going to work. So, we'll have switch strategies and use `DatabaseCleaner` to help us out.

The first one is fairly straight-forward. We'll need to implement a method that checks with jQuery to see if we have any active AJAX requests and if so, kicks the can down the road and waits a little bit before checking again. To do this, we'll add an addition pair of methods to `ActionDispatch::IntegrationTest` in `test/test_helper.rb`.

This a popular technique that has been floating around for a while. I stole it from [here][wfa].

[wfa]: https://robots.thoughtbot.com/automatically-wait-for-ajax-with-capybara

```rb
def wait_for_ajax
  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until finished_all_ajax_requests?
  end
end

def finished_all_ajax_requests?
  page.evaluate_script('jQuery.active').zero?
end
```

We'll now have access to `wait_for_ajax` in all of our integration tests.

We'll also need to add `database_clearner` to our `Gemfile` and `bundle`. Then we can add the following methods to `ActionDispatch::IntegrationTest` as well.

```rb
class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Rails.application.routes.url_helpers

  DatabaseCleaner.strategy = :truncation
  self.use_transactional_fixtures = false

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

  def use_javascript
    Capybara.current_driver = Capybara.javascript_driver
  end

  def reset_driver
    # Capybara.current_driver = nil
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end
end
```

If you ever override `setup` or `teardown` then you'll have to call up to the super class. We actually do this in `test/integration/creating_ideas_test.rb`. So, we'll have to call `super`. Your test file, should now look something like this:

```rb
require 'test_helper'

class LoadingIdeasTest < ActionDispatch::IntegrationTest

  def setup
    super
    use_javascript
    visit root_path
  end

  def teardown
    super
    reset_driver
  end

  test "it creates a new idea upon form submission" do
    assert_difference 'Idea.count', 1 do
      page.fill_in "idea[title]", with: 'Special Idea'
      page.fill_in "idea[body]", with: 'World domination'
      page.click_button "Submit Idea"
    end
  end

end
```

If we update our test to use the new `wait_for_ajax` function, our suite should pass.

```rb
test "it creates a new idea upon form submission" do
  assert_difference 'Idea.count', 1 do
    page.fill_in "idea[title]", with: 'Special Idea'
    page.fill_in "idea[body]", with: 'World domination'
    page.click_button "Submit Idea"
    wait_for_ajax
  end
end
```

This sounds like a good time to make a commit, right?

#### Testing the Unhappy Path

So, what happens if we pass invalid data? If that happens, we should not have a new record in our database, right? Let's write a test!

```rb
test "it does not create a new idea upon invalid form submission" do
  assert_difference 'Idea.count', 0 do
    page.fill_in "idea[title]", with: ''
    page.fill_in "idea[body]", with: ''
    page.click_button "Submit Idea"
    wait_for_ajax
  end
end
```

Our server handles that pretty, well. We have controller tests that verify that this won't happen, but it sure would be nice to have an error message, right? In our HTML, we gave ourselves `<div class="new-idea-messages">` to display messages if needed. It would be cool if we could display a semi-helpful error message.

Let's write a test, shall we? Our API will give us a list of everything that went wrong when we send in an idea that doesn't pass the ActiveRecord validation muster. For the sake of brevity, we'll assume that its because they didn't pass in a title or body for the idea and just display a general error message. In a later iteration, we might parse the error we got back from Rails and then display a custom error message.

```rb
test "it shows an error saying that the title or body cannot be blank if missing" do
  page.click_button "Submit Idea"

  wait_for_ajax

  assert page.find('.new-idea-messages').has_content? 'Title and/or body cannot be blank.'
end
```

In our implementation, we'll respond to a failure and then display that message.

```js
function createIdea(event) {
  event.preventDefault();
  IdeaRepository.create(getNewIdea())
                .fail(renderError);
}
```

As we discussed before. This isn't perfect. It will technically display this message even if the request times out, but its a good first pass and we would come back later and add test coverage and implementation for all of the nuances. We probably also want to clear out the error when we go to submit it again.

```rb
test "it removes the error on subsequent submissions" do
  page.click_button "Submit Idea"

  wait_for_ajax

  page.fill_in "idea[title]", with: "Special Idea"
  page.fill_in "idea[body]", with: "World domination"
  page.click_button "Submit Idea"

  refute page.find('.new-idea-messages').has_content? 'Title and/or body cannot be blank.'
end
```

Implementing this is pretty simple. We'll add a `clearErrors()` function.

```js
function createIdea(event) {
  event.preventDefault();
  clearErrors();
  IdeaRepository.create(getNewIdea())
                .fail(renderError);
}

function clearErrors() {
  return errorMessages.html('');
}
```

The tests should pass.

### Displaying Ideas

We know that at some point, we're going to need to render a template for each idea. So, let's get hat out of the way now. We'll Lodash's `_.template` function to help us out here. We will need to install Lodash first, however.

- Add the `lodash-rails` gem to your `Gemfile`
- `bundle`
- Add `//= require lodash` to the Asset Pipeline in `app/assets/javascripts/application.js`

We'll create a new file called `app/assets/javascripts/idea_template.js` with the following content.

```js
var ideaTemplate = _.template(
  '<div class="idea">' +
    '<h2 class="idea-title"><%= title %></h2>' +
    '<p class="idea-body"><%= body %></p>' +
    '<p class="idea-quality"><%= quality %></p>' +
    '<div class="idea-qualities idea-buttons">' +
      '<button class="idea-promote">Promote</button>' +
      '<button class="idea-demote">Demote</button>' +
      '<button class="idea-delete">Delete</button>' +
    '</div>' +
  '</div>'
);
```

This will serve as our template for rendering new ideas to the page. In `app/assets/javascripts/idea_repository.js`, let's give ourselves another helper method to fetch these ideas.

```js
var IdeaRepository = {
  all: function () {
    return $.getJSON('/api/v1/ideas')
            .then(renderIdeas);
  },
  create: function (idea) {
    return $.post('/api/v1/ideas', {idea: idea});
  }
};
```

This won't work out of the box because we don't have a `renderIdeas` function just yet. We'll create a file called `app/assets/javascripts/render_idea.js` to serve as a home for this functionality. The purpose of `renderIdeas` is to kind of serve the same role as ActiveRecord. We'll take our plain old JavaScript object and give it some additional methods, much like ActiveRecord gives us some methods around some information in a database row.

With any given idea, we'll probably need to do the following:

- Shove it into `ideaTemplate` and get back a HTML structure
- Turn that into a DOM Node with jQuery
- Bind some event listeners to it for promoting, demoting, and deleting
- Add it to the ideas container

`renderIdeas` is a simple one. All it is going to do is map over the ideas, call a second function named `renderIdea` on each of them and return back the original array.

```js
function renderIdeas(ideas) {
  ideas.map(renderIdea);
  return ideas;
}
```

So, that leads us to `renderIdea`, which has to do the heaving lifting of patching our Idea objects with super powers.

```js
function renderIdea(idea) {
  idea.render = function () {
    this.element = $(ideaTemplate(this));
    return this;
  };

  idea.prependTo = function (target) {
    this.element.prependTo(target);
    return this;
  };
  def create_idea
    Idea.create(title: "Gone Soon", body: "Bye")
  end
  return idea.render();
}
```

We'll start by giving our ideas two new methods:

- `render()`, which will plug the idea into the template and then wrap the result in jQuery.
- `prependTo()`, which will tell the idea to prepend itself to some existing node in the DOM.

When the document loads, we'll want to fetch all of the ideas from the server and then prepend them to the `.ideas` element.

At the top of `render_ideas.js`, we'll find the ideas container when the document loads.

```js
var ideasContainer;

$(document).ready(function () {
  ideasContainer = $('.ideas');
});
```

Next, we'll give ourselves a helper function for iterating over the ideas and telling each one to prepend itself to the page.

```js
function prependIdeaToContainer(idea) {
  idea.prependTo(ideasContainer);
  return idea;
}

function prependIdeasToContainer(ideas) {
  return ideas.map(prependIdeaToContainer);
}
```

You may be asking why I'm making a singular and plural version of each function. I already know I'm going to have deal with individual ideas on creation, so I'm giving myself a hook there as well as an abstraction that makes it easier to work with a collection of ideas.

And finally, we'll tie it all together by loading up the ideas, rendering them, and then prepending them to the page when the document is ready.

```js
var ideasContainer;

$(document).ready(function () {
  ideasContainer = $('.ideas');

  IdeaRepository.all()
                .then(renderIdeas)
                .then(prependIdeasToContainer);
});
```

The super cool thing about promises is that the return value of each function we pass to the `then` method on a promise is then passed to the next `then` method. So, all of the plain JavaScript objects are passed from `all()` to `renderIdeas`, but it's that mapped array that then gets passed to `prependIdeasToContainer`. It's essentially like method-chaning enumerables but with code that you received asynchronously.

If you've got Rails server up and running, then you can verify that your ideas on the page. But we'll probably also want a test in place as well. We'll generate a test.

```
rails g intergration_test loading_ideas
```

In that file, we'll add the following:

```rb
require 'test_helper'

class LoadingIdeasTest < ActionDispatch::IntegrationTest

  def setup
    use_javascript
    visit root_path
  end

  def teardown
    reset_driver
  end

  test "it should load all of the ideas with an .idea div" do
    wait_for_ajax
    within :css, '.ideas' do
      assert_equal Idea.count, page.find_all('.idea').count
    end
  end

end
```

In the test above, we're expecting to find all of ideas in the page that we have in the database.

Run the tests, verify that they pass and then make a commit.

### Adding the Ideas We Create to the Page

So, hitting "Submit Idea" will add a new idea to the database, but as it stands, it does not actually put it on the page. Let's crack open our `test/integration/creating_ideas_test.rb` file and add another test.

```rb
test "it adds a new idea to the page" do
  assert_difference "page.find_all('.idea').count", 1 do
    page.fill_in "idea[title]", with: "Special Idea"
    page.fill_in "idea[body]", with: "World domination"
    page.click_button "Submit Idea"

    wait_for_ajax
  end
end
```

We're expecting one more on the page. Let's run it and watch it fail.

Getting this test to pass it pretty easy. We basically need to do two things:

- Take the JavaScript object we get back from the API and pass it into `renderIdea`.
- Take the resulting object and pass prepend it to the list of ideas.

For listing our ideas on page load, we made the process of giving an idea its super powers part of `IdeaRepository`. So, let's update that to render our new idea after it loads in `app/assets/javascripts/idea_repository.rb`.

```rb
var IdeaRepository = {
  all: function () {
    return $.getJSON('/api/v1/ideas')
            .then(renderIdeas);
  },
  create: function (idea) {
    return $.post('/api/v1/ideas', {idea: idea})
            .then(renderIdea);
  }
};
```

Now we see why having singular and plural version helps. It gives a nice clean syntax. We just need to prepend it onto the page after we create it in `app/assets/javascripts/create_idea.js`.

```js
function createIdea(event) {
  event.preventDefault();
  clearErrors();
  IdeaRepository.create(getNewIdea())
                .then(prependIdeaToContainer)
                .fail(renderError);
}
```

If we run our tests, we'll see that it now passes. So, let's commit.

### Deleting Ideas

Let's start by generating another test file.

```
rails g integration_test deleting_ideas
```

Let's start with the most basic possible test. If we have `n` ideas and we delete one, we can expect to have `n - 1` ideas on the page.

```rb
require 'test_helper'

class DeletingIdeasTest < ActionDispatch::IntegrationTest

  def setup
    create_idea
    use_javascript
    visit root_path
  end

  def teardown
    reset_driver
  end

  test "delete button removes an idea from the page" do
    assert_difference "page.find_all('.idea').count", -1 do
      page.find_all(".idea-delete").first.click

      wait_for_ajax
    end
  end

  private

  def create_idea
    Idea.create(title: "Gone Soon", body: "Bye")
  end

end
```

This test will obviously fail because we haven't wired up any functionality to our delete button. There are a bunch of ways we could do this, but let's hook it up with the pattern that we've been using to render and prepend ideas.

First, let's go ahead and create a new file for all of our idea actions. We'll call it `app/assets/javascripts/idea_actions.js`. In this file, we'll start with a simple function that sends out a DELETE request and then—if successful—will remove the element from the page.

```js
function deleteIdea() {
  $.ajax({
    method: 'DELETE',
    url: '/api/v1/ideas/' + this.id
  }).then(function () {
    this.element.remove();
  }.bind(this))
}
```

If you recall, we need to use `bind()` in order to keep the context of `this` in an asynchronous function. You might be wondering what `this` even is at this point? Well, we're about to attach this method on to each idea that we render. Which means, `this` is whatever idea is calling the function. This is part of the power of allowing functions to execute based on their context.

Inside of the `renderIdea` function in `app/assets/javascripts/render_ideas.js`, we'll attach it to our idea.

```js
idea.delete = deleteIdea;
```

Now, every idea has a `delete` method that will take care of notifying the server that it would like to be deleted and then politely removing itself from the page when that happens.

We'll be binding events for promote and demote later on, so let's just add a method called `bindEvents` where we can do this all at once. Finally, we'll call that method, right after we render the element. The result of all of the changes to our `renderIdea` method is that it should look something like this.

```js
function renderIdea(idea) {
  idea.render = function () {
    idea.element = $(ideaTemplate(idea));
    return idea;
  };

  idea.prependTo = function (target) {
    idea.element.prependTo(target);
    return idea;
  };

  idea.delete = deleteIdea;

  idea.bindEvents = function () {
    idea.element.find('.idea-delete').on('click', function () {
      idea.delete();
    });

    return idea;
  };

  return idea.render().bindEvents();
}
```

You'll notice that I have a habit of returning the idea object at the end of every method, this allows me to chain them together.

If we run our tests, we'll see that everything passes and we now have a working delete button.

#### Testing the Lack of an Unhappy Path

It just so happens that our implementation will always be scoped to the correct idea via a powerful JavaScript feature called *closures*, which we'll discuss later. But let's write a test to verify that the correct idea was deleted, just because.

```rb
test "delete button removes the correct idea from the page" do
  idea_div = page.find(".idea:first-child")
  idea_title = idea_div.find(".idea-title").text

  idea_div.find(".idea-delete").click

  wait_for_ajax

  refute page.has_content? idea_title
end
```

Run the test suite and it should world as expected.

### Promoting and Demoting Ideas

The last feature that we're going to implement in this tutorial is the ability to promote and demote the quality of a given idea. Since the `update` action in our controller is relatively simple, this will also serve as a template for how to impletement an update feature as well for the title and body of an idea.

We'll generate another test file in `test/integration/update_idea.rb`

Let's start with a battery of tests to exercise this functionality.

```rb
require 'test_helper'

class UpdateIdeasTest < ActionDispatch::IntegrationTest

  def setup
    create_idea
    use_javascript
    visit root_path
  end

  def teardown
    reset_driver
  end

  test "promote button should promote the quality of an idea" do
    idea = get_top_idea
    click_the_promote_button_on_idea(idea)

    assert idea.find('.idea-quality').has_content? 'Plausible'
  end

  test "clicking promote button twice should promote the quality of an idea to genius" do
    idea = get_top_idea
    click_the_promote_button_on_idea(idea)
    click_the_promote_button_on_idea(idea)

    assert idea.find('.idea-quality').has_content? 'Genius'
  end

  test "clicking promote button thris should not promote the quality past genius" do
    idea = get_top_idea
    click_the_promote_button_on_idea(idea)
    click_the_promote_button_on_idea(idea)
    click_the_promote_button_on_idea(idea)

    assert idea.find('.idea-quality').has_content? 'Genius'
  end

  test "demoting a swill idea should keep it as swill" do
    idea = get_top_idea
    click_the_demote_button_on_idea(idea)

    assert idea.find('.idea-quality').has_content? 'Swill'
  end

  test "promoting and then demoting an idea should return it to swill" do
    idea = get_top_idea
    click_the_promote_button_on_idea(idea)
    click_the_demote_button_on_idea(idea)

    assert idea.find('.idea-quality').has_content? 'Swill'
  end

  private

  def create_idea
    Idea.create(title: "Gone Soon", body: "Bye")
  end

  def get_top_idea
    page.find('.idea:first-child')
  end

  def click_the_promote_button_on_idea(idea)
    idea.find(".idea-promote").click
    wait_for_ajax
  end

  def click_the_demote_button_on_idea(idea)
    idea.find(".idea-demote").click
    wait_for_ajax
  end

end
```

Now that we have some tests that exercise this functionality, let's add some implementation.

So, with my current approach, I've jammed a bunch of additional methods onto each idea object. We'll look at a *much* better way to do this next week, but for now, this is all we have at our disposal. That said, I don't want to send all these methods back over to Rails.

Rails is expecting three things: a title, a body, and a quality. Ideally, I only want to send those properties over the wire. This is easy enough to do by hand, I could do somethind like:

```js
idea.toJSON = function () {
  return {
    title: this.title,
    body: this.body,
    quality: this.quality
  }
};
```

But, I already have Lodash installed so that means I can use `_.pick` to just pick the properties I want.

```js
idea.toJSON = function () {
  return { idea: _.pick(this, ['title', 'body', 'quality']) }
};
```

I'm also nesting it in an object with the key of ideas, that way Rails gets it as `params[:ideas]`.

I can also implement an `updateIdea` that will prepare an AJAX request with whatever the current state of the object is in `app/assets/javascripts/idea_actions.js`.

```js
function updateIdea() {
  return $.ajax({
    method: 'PUT',
    url: '/api/v1/ideas/' + this.id,
    data: this.toJSON()
  });
}
```

This is a really flexible function that will be reusable later on if I were to implement updating the title and body of the idea. A first draft of promotion and demotion of ideas will work with conditionals, update the property if necessary, and then let the update method that the given idea has been updated.

```js
function promoteIdea() {
  if (this.quality === 'plausible') { this.quality = 'genius'; }
  if (this.quality === 'swill') { this.quality = 'plausible'; }
  return this.update();
}

function demoteIdea() {
  if (this.quality === 'plausible') { this.quality = 'swill'; }
  if (this.quality === 'genius') { this.quality = 'plausible'; }
  return this.update();
}
```

We can add each of these function to our objects as methods. Since `this` is based on the context of the object it's being called from, these functions will work for each individual idea and be scoped appropriately.

```js
idea.promote = promoteIdea;
idea.demote = demoteIdea;
idea.delete = deleteIdea;
idea.update = updateIdea;
```

(You might be wondering if there is a better way to do this. There is. Next week we'll talk about how to attach these to the prototype chain. In that scenario, each idea would just call up to an object that had all of these methods ready and waiting.)

Trying to be a DOM surgeon and just change little pieces of the DOM based on changes to you model is hard and tedious. It often involves a whole lot of traversal and other things that are more work thant their worth. We'll implement a `rerender` method that will do the following:

1. Call jQuery's `replaceWith` method.
2. Pass in a new version of the template based on the updated quality.
3. Bind events to that new version before sending it along.
4. Let jQuery do some magic of swapping one out with the other.

```js
idea.rerender = function () {
  idea.element.replaceWith(idea.render().bindEvents().element);
  return idea;
};
```

Finally, we'll add the additional event listeners to `bindEvents` so that our "Promote" and "Demote" buttons work.

```js
idea.bindEvents = function () {
  idea.element.find('.idea-delete').on('click', function () {
    idea.delete();
  });

  idea.element.find('.idea-promote').on('click', function () {
    idea.promote().then(idea.rerender);
  });

  idea.element.find('.idea-demote').on('click', function () {
    idea.demote().then(idea.rerender);
  });

  return idea;
};
```

Our tests should now pass. Just in case they don't, here is there current contents of `renderIdea` and `app/assets/javascripts/idea_actions.js`.

```js
function renderIdea(idea) {
  idea.render = function () {
    idea.element = $(ideaTemplate(idea));
    return idea;
  };

  idea.rerender = function () {
    idea.element.replaceWith(idea.render().bindEvents().element);
    return idea;
  };

  idea.prependTo = function (target) {
    idea.element.prependTo(target);
    return idea;
  };

  idea.toJSON = function () {
    return { idea: _.pick(this, ['title', 'body', 'quality']) }
  };

  idea.promote = promoteIdea;
  idea.demote = demoteIdea;
  idea.delete = deleteIdea;
  idea.update = updateIdea;

  idea.bindEvents = function () {
    idea.element.find('.idea-delete').on('click', function () {
      idea.delete();
    });

    idea.element.find('.idea-promote').on('click', function () {
      idea.promote().then(idea.rerender);
    });

    idea.element.find('.idea-demote').on('click', function () {
      idea.demote().then(idea.rerender);
    });

    return idea;
  };

  return idea.render().bindEvents();
}
```

```js
// app/assets/javascripts/idea_actions.js

function promoteIdea() {
  if (this.quality === 'plausible') { this.quality = 'genius'; }
  if (this.quality === 'swill') { this.quality = 'plausible'; }
  return this.update();
}

function demoteIdea() {
  if (this.quality === 'plausible') { this.quality = 'swill'; }
  if (this.quality === 'genius') { this.quality = 'plausible'; }
  return this.update();
}

function deleteIdea() {
  $.ajax({
    method: 'DELETE',
    url: '/api/v1/ideas/' + this.id
  }).then(function () {
    this.element.remove();
  }.bind(this));
}

function updateIdea() {
  return $.ajax({
    method: 'PUT',
    url: '/api/v1/ideas/' + this.id,
    data: this.toJSON()
  });
}
```

## Towards an Object Oriented Approach

So, we have this mess of functions all of the place that we're trying to attach onto an individual idea object. It's kind of sloppy, messy, and difficult because we're trying to manage two things:

- Individual ideas and their state
- Methods that work on that state

The Rubyist in you should be througholy annoyned at this point. What we're doing right now seems hacky because it is. It would be much nicer if every idea could just refer to another object that stored all of the shared methods that each idea might need. This sounds like a job for protoypal inheritance.

What would an object-oriented approach look like? Ideally could construct an object that held the data for an individual idea and then store all of the methods a single prototype object. Here is an example of what this might look like.

```js
function Idea(data) {
  this.id = data.id;
  this.title = data.title;
  this.body = data.body;
  this.quality = data.quality;

  this.render().bindEvents();
}

Idea.prototype.promote = function () {
  if (this.quality === 'plausible') { this.quality = 'genius'; }
  if (this.quality === 'swill') { this.quality = 'plausible'; }
  return this.update();
};

Idea.prototype.demote = function () {
  if (this.quality === 'plausible') { this.quality = 'swill'; }
  if (this.quality === 'genius') { this.quality = 'plausible'; }
  return this.update();
};

Idea.prototype.delete = function () {
  $.ajax({
    method: 'DELETE',
    url: '/api/v1/ideas/' + this.id
  }).then(function () {
    this.element.remove();
  }.bind(this));
};

Idea.prototype.update = function () {
  return $.ajax({
    method: 'PUT',
    url: '/api/v1/ideas/' + this.id,
    data: this.toJSON()
  });
};

Idea.prototype.render = function () {
  this.element = $(ideaTemplate(this));
  return this;
};

Idea.prototype.rerender = function () {
  this.element.replaceWith(this.render().bindEvents().element);
  return this;
};

Idea.prototype.prependTo = function (target) {
  this.element.prependTo(target);
  return this;
};

Idea.prototype.toJSON = function () {
  return { idea: _.pick(this, ['title', 'body', 'quality']) };
};

Idea.prototype.bindEvents = function () {
  this.element.find('.idea-delete').on('click', function () {
    this.delete();
  }.bind(this));

  this.element.find('.idea-promote').on('click', function () {
    this.promote().then(this.rerender.bind(this));
  }.bind(this));

  this.element.find('.idea-demote').on('click', function () {
    this.demote().then(this.rerender.bind(this));
  }.bind(this));

  return this;
};
```

Then we swap out our `renderIdea` with a call to our new object constructor. In `app/assets/javascripts/render_ideas.js`:

```js
function renderIdeas(ideas) {
  return ideas.map(renderIdea);
}

function renderIdea(idea) {
  return new Idea(idea);
}
```

