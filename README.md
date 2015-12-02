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

It's not in the project specification per se, but let's validate that each idea has at least a title. I don't really care to elaborate on all of my ideas with a `body`, but I'd at least like to have some kind of sense what my great idea was all about. You've probably done this a thousand times before, but that doesn't mean I'm going to throw caution to the wind, let's start with a test in `test/models/idea.rb`.

```rb
test "it should be invalid without a title" do
  idea_without_title = Idea.new
  idea_with_title = Idea.new(title: "My greatest idea")

  refute(idea_without_title.valid?)
  assert(idea_with_title.valid?)
end
```

Getting the test to pass is pretty trivial.

```rb
class Idea < ActiveRecord::Base
  validates :title, presence: true

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


