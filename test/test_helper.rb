# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"
require "active_support/all"
require "active_record_test_case_helper"
require "database_cleaner"
require "active_record"
require "byebug"

ActiveSupport.test_order = :sorted if ActiveSupport.respond_to?(:test_order=)
# Force hook :active_record on_load event to make sure loader can work.
ActiveSupport.run_load_hooks(:active_record, ActiveRecord::Base)

require "second_level_cache"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

require "model/application_record"
require "model/user"
require "model/book"
require "model/image"
require "model/topic"
require "model/post"
require "model/order"
require "model/order_item"
require "model/account"
require "model/animal"
require "model/contribution"
require "model/paranoid" if defined?(Paranoid)

DatabaseCleaner[:active_record].strategy = :truncation

SecondLevelCache.configure do |config|
  config.cache_store = ActiveSupport::Cache::MemoryStore.new
end

module ActiveSupport
  class TestCase
    setup do
      SecondLevelCache.cache_store.clear
      DatabaseCleaner.start
    end

    teardown do
      DatabaseCleaner.clean
    end
  end
end
