require 'forwardable'
require_relative "abstract_method"

class SimpleDocument
  abstract_method :header
  abstract_method :body
  abstract_method :name
  abstract_method :format
  abstract_method :active?
  abstract_method :mtime

  singleton_class.class_eval do
    extend Forwardable
    
    def store_url=(url)
      @document_store = FileStore.new(url)
    end
    
    def document_store
      @document_store || raise("Missing SimpleDocument.store_url setting")
    end

    def uncache
      self.store_url = document_store.url if document_store
    end
    
    delegate :url => :document_store
    
    # Return a Hash of all documents in a specific subset in this store. 
    # The Hash keys are the document names, the hash values are an Array
    # of documents for this name, with potentially different locales.
    def all(subset)
      document_store.all(subset)
    end

    # Stores a single document in a specific subset in this store.
    def store(subset, name, locale, data)
      raise ArgumentError, "Invalid subset #{subset.inspect}" if subset =~ /\./
      raise ArgumentError, "Invalid name #{name.inspect}" if name =~ /\./

      # stringify keys
      data = data.inject({}) { |hash, (k,v)| hash.update(k.to_s => v) }

      raise(ArgumentError, "Missing format entry") unless data.key?("format")
      
      document_store.store(subset, name, locale, data)
    end

    # Fetches a document by name from a specific subset. If a localize 
    # is set it tries to load a localized variant of the document first. 
    # If there is no such document, it then tries to load a non-localized 
    # variant of the document.
    # 
    # The method returns nil if there is no such document.
    def fetch(subset, name, locale=nil)
      (locale && fetch_with_locale(subset, name, locale)) ||
      fetch_with_locale(subset, name, nil)
    end

    # Fetches a document by name from a specific subset, using #fetch.
    # In opposite to #fetch this method raises an Errno::ENOENT 
    # exception if there is no such document.
    def fetch!(subset, name, locale=nil)
      fetch(subset, name, locale) || raise(Errno::ENOENT, "SimpleDocument[#{url}]/#{subset}/#{name}")
    end

    private

    # Fetches a document by name from a specific subset with a given
    # locale (or no locale, if the locale parameter is set to nil.)
    def fetch_with_locale(subset, name, locale); 
      document_store.fetch_with_locale(subset, name, locale)
    end
  end 
end

require_relative "simple_document/ostruct"
require_relative "simple_document/file_store"
