module OS
  
  #
  # Return the current operating system: Darwin, Linux, or Windows. 
  #
  def self.name
    return @os if @os
    
    case RUBY_PLATFORM
      when /darwin/
        @os = :darwin
      when /bsd/
        @os = :bsd
      when /linux/
        @os = :linux
      when /cygwin|mswin|mingw|bccwin|wince|emx/
        @os = :windows
    else
      raise "Unknown operating system: #{RUBY_PLATFORM}"
    end

    @os
  end
  
  #
  # Is this Linux?
  #
  def self.linux?
    name == :linux
  end

  def self.windows?
    name == :windows
  end

  def self.darwin?
    name == :darwin
  end
  def self.mac?; darwin?; end

  def self.bsd?
    name == :bsd or name == :darwin
  end

  def self.unix?
    not windows?
  end

end