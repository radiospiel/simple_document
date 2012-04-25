require 'ostruct'

class SimpleDocument::Ostruct < SimpleDocument
  extend Forwardable
  
  def initialize(data)
    @ostruct = OpenStruct.new(data)
  end
  
  delegate [:header, :body, :name, :format, :uri] => :@ostruct
  
  def active?
    true
  end

  def mtime
    @ostruct.mtime && Time.parse(@ostruct.mtime)
  end
end
