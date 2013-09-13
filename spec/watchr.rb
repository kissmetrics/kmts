watch('spec/.*spec\.rb') { |md| system("bundle exec rspec --color #{md[0]}") }
watch('lib/kmts\.rb') { |md| system("bundle exec rake spec") }
watch('lib/kmts/saas\.rb') { |md| system("bundle exec rspec --color spec/km_saas_spec.rb") }
