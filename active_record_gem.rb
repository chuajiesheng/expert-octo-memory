begin
  require 'bundler/inline'
rescue LoadError => e
  $stderr.puts 'Bundler version 1.10 or later is required. Please update your Bundler'
  raise e
end

gemfile(true) do
  source 'https://rubygems.org'
  # Activate the gem you are reporting the issue against.
  gem 'activerecord', '4.2.4'
  gem 'sqlite3'
  gem 'pry'
end

require 'active_record'
require 'minitest/autorun'
require 'logger'

# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.integer :tag_code
  end
end

class Post < ActiveRecord::Base
  scope :zeros, -> { where(tag_code: 0) }
  scope :ones, -> { where(tag_code: 1) }
  scope :zeros_or_ones, -> { where(tag_code: [0, 1]) }
end

class BugTest < Minitest::Test
  def test_union
    Post.create!(tag_code: 0)
    Post.create!(tag_code: 1)

    union = Post.zeros.union(Post.ones)
    table_alias = Post.arel_table.create_table_alias(union, Post.table_name)
    query = Post.from(table_alias)

    assert_equal 2, query.count
  end
end