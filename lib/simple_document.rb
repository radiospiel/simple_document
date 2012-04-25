require_relative "abstract_method"

class SimpleDocument
  abstract_method :header
  abstract_method :body
  abstract_method :name
  abstract_method :format
  abstract_method :active?
  abstract_method :mtime

  singleton_class.class_eval do
    def url
      @store.url if @store
    end
    
    def url=(url)
      @store = FileStore.new(url)
    end
    
    def store
      @store || raise("Missing SimpleDocument.url setting")
    end

    def uncache
      self.url = store.url if store
    end
    
    # Return a Hash of all documents in a specific subset in this store. 
    # The Hash keys are the document names, the hash values are an Array
    # of documents for this name, with potentially different locales.
    def all(subset)
      store.all(subset)
    end

    # Stores a single document in a specific subset in this store.
    def write(subset, name, data)
      raise ArgumentError, "Invalid subset #{subset.inspect}" if subset =~ /\./
      raise ArgumentError, "Invalid name #{name.inspect}" if name =~ /\./

      # stringify keys
      data = data.inject({}) { |hash, (k,v)| hash.update(k.to_s => v) }
      locale = data.delete "locale"

      raise(ArgumentError, "Missing format entry") unless data.key?("format")
      
      store.store(subset, name, locale, data)
    end

    # Fetches a document by name from a specific subset. If a localize 
    # is set it tries to load a localized variant of the document first. 
    # If there is no such document, it then tries to load a non-localized 
    # variant of the document.
    # 
    # The method returns nil if there is no such document.
    def read(subset, name, options = {})
      # stringify keys
      options = options.inject({}) { |hash, (k,v)| hash.update(k.to_s => v) }
      locale = options.delete "locale"
      
      (locale && store.fetch_with_locale(subset, name, locale)) ||
      store.fetch_with_locale(subset, name, nil)
    end

    # Fetches a document by name from a specific subset, using #fetch.
    # In opposite to #fetch this method raises an Errno::ENOENT 
    # exception if there is no such document.
    def read!(subset, name, options = {})
      read(subset, name, options) || raise(Errno::ENOENT, "SimpleDocument[#{url}]/#{subset}/#{name}")
    end
  end 
end

require_relative "simple_document/ostruct"
require_relative "simple_document/file_store"
