require_relative 'test_helper'

DIR = File.expand_path File.dirname(__FILE__)

class SimpleDocument::FileStoreTest < Test::Unit::TestCase
  def setup
    SimpleDocument.url = "#{DIR}/fixtures"

    # Clean writing directory
    FileUtils.rm_rf("#{DIR}/fixtures/writing")
  end
  
  def teardown
    File.unlink @store.path if @store
  end

  # -- load single documents ------------------------------------------------
  
  def test_load_about
    doc = SimpleDocument.read "folder", "about"
    
    assert_equal "#{DIR}/fixtures/folder/about.md", doc.uri
    assert_equal :markdown, doc.format
    assert_equal "A english \"about\"\n", doc.body
    
    assert_equal nil, doc.header
    assert_equal "about", doc.name
    assert_equal true, doc.active?
    assert_equal File.mtime(doc.uri), doc.mtime
  end

  # load document in a specific locale
  def test_load_about_de
    doc = SimpleDocument.read "folder", "about", :locale => "de"
    
    assert_equal "#{DIR}/fixtures/folder/about.de.md", doc.uri
    assert_equal :markdown, doc.format
    assert_equal "Ein deutsches \"about\"\n", doc.body
    
    assert_equal nil, doc.header
    assert_equal "about", doc.name
    assert_equal true, doc.active?
    assert_equal File.mtime(doc.uri), doc.mtime
  end

  # fallback to base document in a specific, but missing locale
  def test_load_about_missing_locale
    doc = SimpleDocument.read "folder", "about", :locale => "fr"
    
    assert_equal "#{DIR}/fixtures/folder/about.md", doc.uri
  end

  # load document with headers
  def test_load_headered
    doc = SimpleDocument.read "folder", "headered"
    
    assert_equal "#{DIR}/fixtures/folder/headered.md", doc.uri
    assert_equal :markdown, doc.format
    assert_equal "A document with a header.\n", doc.body
    
    assert_equal nil, doc.header
    assert_equal "headered", doc.name
    assert_equal true, doc.active?
    assert_equal Time.parse("2012-01-01"), doc.mtime
  end

  # load missing document
  def test_load_missing!
    assert_raise(Errno::ENOENT) {  
      SimpleDocument.read! "missing-folder", "about"
    }

    assert_raise(Errno::ENOENT) {  
      SimpleDocument.read! "folder", "missing-about"
    }
  end

  def test_load_missing
    assert_nil SimpleDocument.read("missing-folder", "about")
    assert_nil SimpleDocument.read("folder", "missing-about")
  end

  # -- fetch collections ------------------------------------------------
  
  # fetch collection
  def test_missing_collection
    docs = SimpleDocument.all "missing-folder"
    assert_equal({}, docs)
  end
  
  def test_collection
    # Return a Hash of all documents in a specific subset in this store. 
    # The Hash keys are the document names, the hash values are an Array
    # of documents for this name, with potentially different locales.
    
    docs = SimpleDocument.all "folder"
    assert_kind_of(Hash, docs)
    assert_equal(%w(about headered), docs.keys.sort)
    assert_equal(2, docs.count)
    assert_equal([], docs["missing"])
  end

  # -- writing ------------------------------------------------
  
  def test_write_fails
    # Make sure we are blank.
    assert_raise(Errno::ENOENT) { SimpleDocument.read! "writing", "foo" }
    
    # Missing format
    assert_raise(ArgumentError) { SimpleDocument.write "writing", "foo", :body => "The body" }

    # Invalid format
    assert_raise(ArgumentError) { SimpleDocument.write "writing", "foo", :body => "The body", :format => "yahoo!" }

    # Invalid names
    assert_raise(ArgumentError) { SimpleDocument.write "wba/../dd", "12.kjsh", :body => "The body", :format => "markdown" }
  end

  def test_write
    # Make sure we are blank.
    assert_raise(Errno::ENOENT) { SimpleDocument.read! "writing", "foo" }

    doc = SimpleDocument.write "writing", "foo", :body => "The body", :format => "markdown"
    assert_equal("foo", doc.name)
    assert_equal("The body", doc.body)
    assert_equal(true, doc.active?)

    doc = SimpleDocument.read! "writing", "foo", :locale => "de"
    assert_equal("foo", doc.name)
    assert_equal("The body", doc.body)
    assert_equal(true, doc.active?)
  end

  # -- uncache ------------------------------------------------
  
  def test_uncache
    store_1 = SimpleDocument.store
    store_2 = SimpleDocument.store
    SimpleDocument.uncache
    store_3 = SimpleDocument.store
    
    assert_equal(store_1.object_id, store_2.object_id)
    assert_not_equal(store_1.object_id, store_3.object_id)

    assert_equal(store_1.url, store_3.url)
  end
end
