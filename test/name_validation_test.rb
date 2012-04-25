require_relative 'test_helper'

DIR = File.expand_path File.dirname(__FILE__)

class NameValidationTest < Test::Unit::TestCase
  def parse(name)
    SimpleDocument.send(:parse_name, name)
  end
  
  def test_parse_name
    assert_equal %w(abc def), parse("abc/def")
    assert_equal %w(fuu b_r), parse("fuu/b_r")
    assert_equal %w(f-u bar), parse("f-u/bar")
    
    assert_raise(ArgumentError) { parse("x") }
    assert_raise(ArgumentError) { parse("09-/def") }    # starts with a digit
    assert_raise(ArgumentError) { parse("/x") }         # doesn't have two parts
    assert_raise(ArgumentError) { parse("/a/b/x") }     # more than two parts
    assert_raise(ArgumentError) { parse("fuu/b_r.x") }  # contains a dot
  end
end
