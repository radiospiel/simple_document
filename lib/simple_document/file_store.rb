class SimpleDocument::FileStore
  class Document < SimpleDocument::Ostruct
    def mtime
      @ostruct.mtime ? Time.parse(@ostruct.mtime.to_s) : File.mtime(self.uri)
    end
  end

  attr :url
  alias :root :url

  def initialize(url)
    @url = url
  end

  # Fetches a document by name from a specific subset with a given
  # locale (or no locale, if the locale parameter is set to nil.)
  def fetch_with_locale(subset, name, locale = nil)
    locale_ext = ".#{locale}" if locale
    
    pattern = "#{root}/#{subset}/#{name}#{locale_ext}.{#{FORMAT_BY_EXTENSION.keys.join(",")}}"
    Dir.glob(pattern).sort.
      map do |path| read_from_file(path) end.
      detect(&:active?)
  end
  
  # Return a Hash of all documents in a specific subset in this store. 
  def all(subset)
    Dir.glob("#{root}/#{subset}/*.{#{FORMAT_BY_EXTENSION.keys.join(",")}}").
      map { |path| read_from_file(path) }.
      select(&:active?).
      group_by(&:name).
      tap { |hash| hash.default = [] }
  end
  
  private
  
  def dir(subset) 
    dir = "#{root}/#{subset}"
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    dir
  end
  
  public
  
  def store(subset, name, locale, data)
    format, body = data.values_at "format", "body"
    ext = FORMAT_BY_EXTENSION.key(format.to_sym) || raise(ArgumentError, "Unsupported format #{format.inspect}")
    locale_ext = ".#{locale}" if locale
    
    path = "#{dir(subset)}/#{name}#{locale_ext}.#{ext}"
    
    File.open(path, "w") do |file|
      file.write data.to_yaml unless data.empty?
      file.write "---\n"
      file.write body
    end

    fetch_with_locale(subset, name, locale)
  end
  
  private
  
  FORMAT_BY_EXTENSION = {
    "md"    => :markdown,
    "html"  => :plain,
    "erb"   => :erb
  }

  def header_and_body_from_document(path)
    content = File.read(path).force_encoding('UTF-8')
    lines = StringIO.new(content).readlines
    lines.shift if lines.first =~ /^---/

    header = []

    while (line = lines.shift) && line !~ /^---/ do
      header << line
    end

    if lines.empty?
      [ nil, header.join ] 
    else
      [ header.join, lines.join ]
    end
  end

  # read a simple document from a file
  def read_from_file(path)
    header, body = header_and_body_from_document(path)
    header = header ? YAML::load(header) : {}

    attributes = attributes_from_path(path) || raise("Cannot parse path: #{path.inspect}")

    Document.new header.merge(attributes).merge(:body => body)
  end
  
  def attributes_from_path(path)
    return unless File.basename(path) =~ /^([^.]+)\.((\w\w)\.)?(\w+)$/

    name, locale, ext = $1, $3, $4
    return unless format = FORMAT_BY_EXTENSION[ext]

    { :locale => locale, :name => name, :uri => path, :format => format }
  end
end
