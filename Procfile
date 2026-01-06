web: bundle exec puma -C config/puma.rb -p ${PORT:-8080}
release: bundle exec rails db:prepare && bundle exec rails db:seed
