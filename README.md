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
