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
