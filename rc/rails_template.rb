gem 'coffee-rails-source-maps'
gem 'haml-rails'
gem 'jquery-rails'
gem 'pg'
gem 'simple_form'

gem_group :development, :test do
  gem 'pry-rails'
  gem 'pry-theme'
  gem 'best_errors'
  gem 'quiet_assets'
  gem 'letter_opener'
  gem 'faker'
  gem 'did_you_mean'
end

environment 'config.action_mailer.delivery_method = :letter_opener', env: 'development'
# environment 'config.assets.js_compressor = :closure', env: 'assets'

rakefile("db.rake") do
  %{
    namespace :db do
      desc "Reimport everything"
      task remigrate: [:drop, :create, :migrate]
    end
  }
end

generate "haml:application_layout", "convert"
# rake "haml:erb2haml"

after_bundle do
  git :init
  git add: "."
  git commit: %Q{ -m 'First commit.' }
end

run "subl ."