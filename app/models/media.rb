
class Media
  
  PRINTED_BOOK    = "printed_book"
  PRINTED_HARDCOVER_BOOK = "printed_hardcover_book"
  ELECTRONIC_BOOK = "electronic_book"
  SCREENCAST      = "screencast"
  ON_DEMAND_BOOK  = "on_demand_book"
  AUDIO_BOOK      = "audio_book"
  OTHER           = "other"
  
  BETA_ON_PAPER   = "Beta-on-Paper"

  attr_reader :code, :name
  def initialize(code, name, intangible)
    @code, @name, @intangible = code, name, intangible
  end

  class << self
    def as_select_list
      instances.map {|i| [i.name, i.code]}
    end

		def codes
			instances.map(&:code)
		end
  
    def for_code(code)      
      instances.find {|c| c.code == code} || default(:code, code)
    end
  
    def for_name(name)
      instances.find {|c| c.name == name} || default(:name, name)
    end
  
    def printed_book
      for_code(PRINTED_BOOK)
    end

    def printed_hardcover_book
      for_code(PRINTED_HARDCOVER_BOOK)
    end
  
    def electronic_book
      for_code(ELECTRONIC_BOOK)
    end

    def screencast
      for_code(SCREENCAST)
    end

    def on_demand_book
      for_code(ON_DEMAND_BOOK)
    end

    def audio_book
      for_code(AUDIO_BOOK)
    end

    def other
      for_code(OTHER)
    end
    
    def physical
      [ PRINTED_BOOK, PRINTED_HARDCOVER_BOOK, ON_DEMAND_BOOK, OTHER ].map {|code| for_code(code) }
    end
  
    def instances
      @instances ||= [
        # -------------------------------------------------------------------
        #         code,                   name,                   intangible?
        # -------------------------------------------------------------------
        Media.new(PRINTED_BOOK,           "Paper Book",           false), 
        Media.new(PRINTED_HARDCOVER_BOOK, "Paper Hardcover Book", false), 
        Media.new(ELECTRONIC_BOOK,        "eBook",                true),
        Media.new(SCREENCAST,             "Screencast",           true),
        Media.new(ON_DEMAND_BOOK,         BETA_ON_PAPER,          false),
        Media.new(AUDIO_BOOK,             "Audio book",           true),
        Media.new(OTHER,                  "Other",                false)
      ]
    end
  
    def default(attribute, value)
      raise "There is no default media, it must be specified.  This is a bug in the code or data. Passed #{value.inspect} for #{attribute.inspect}"
    end
  end
  
  def intangible?
    @intangible
  end
  
  def pdf?
    ActiveSupport::Deprecation.warn("Why are you calling .pdf? it's .ebook? now", caller)
    ebook?
  end

  def ebook?
    @code == ELECTRONIC_BOOK
  end
  
  def paper?
    @code == PRINTED_BOOK
  end

  def hardcover?
    @code == PRINTED_HARDCOVER_BOOK
  end

  def screencast?
    @code == SCREENCAST
  end
  
  def on_demand?
    @code == ON_DEMAND_BOOK
  end  
  
  def other?
    @code == OTHER
  end

  def audio_book?
    @code == AUDIO_BOOK
  end
end
