# Idea Box

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
  idea = { title: "New Idea", body: "Something" }
  number_of_ideas = Idea.all.count

  post :create, idea: idea, format: :json

  assert_equal number_of_ideas + 1, Idea.all.count
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
    respond_with({ errors: idea.errors }, status: 422, location: api_v1_ideas_path)
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
    respond_with({ errors: idea.errors }, status: 422, location: api_v1_ideas_path)
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
