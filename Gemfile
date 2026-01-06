source "https://rubygems.org"

# Core
gem "rails", "~> 8.1.1"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# Ruby 4.0 compatibility
gem "fiddle"

# Performance
gem "bootsnap", require: false

# Windows timezone data
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
end

group :development do
  gem "web-console"
end