class ImplementationMissing < NameError; end

class Object
  private

  def implementation_missing!
    calling_method_name = caller[1]
    calling_method_name = $1 if calling_method_name =~ /.*in `(.*)'$/

    raise ImplementationMissing, "Implementation missing: #{self.class.name}##{calling_method_name}"
  end
end

module Kernel
  private
  
  def abstract_method(*syms)
    syms.each do |sym|
      define_method sym do
        raise ImplementationMissing, "#{self.class.name}##{sym}"
      end
    end
  end
end
