require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'ruby-debug'
require 'simplecov'
require 'timecop'
require 'test/unit'
SimpleCov.start do
  add_filter "test/*.rb"
  add_filter "lib/abstract_method.rb"
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'simple_document'

module SimpleDocument::TestCase
  def test_simple_document_kindof
    assert store.kind_of?(SimpleDocument)
  end
  
  # def test_simple_document
  #   assert_equal(nil, simple_document.fetch("bar"))
  # 
  #   assert_equal("foo", simple_document.store("bar", "foo"))
  #   assert_equal("foo", simple_document.fetch("bar"))
  #   
  #   done = 0
  #   assert_equal "baz", simple_document.cached("key") { done += 1; "baz" }
  #   assert_equal 1, done
  #   assert_equal "baz", simple_document.cached("key") { done += 1; "baz" }
  #   assert_equal 1, done
  # 
  #   assert_equal(nil, simple_document.store("bar", nil))
  #   assert_equal(nil, simple_document.fetch("bar"))
  # end
end
