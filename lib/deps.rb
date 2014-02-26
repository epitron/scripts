require_relative 'os'

if OS.windows?
  PATH_SEPARATOR    = ";"
  BINARY_EXTENSION  = ".exe"
else
  PATH_SEPARATOR    = ":"
  BINARY_EXTENSION  = ""
end

##################################################################

def which(bin)
  ENV["PATH"].split(PATH_SEPARATOR).find do |path|
    fullpath = File.join(path, bin)
    return fullpath if File.exists? fullpath + BINARY_EXTENSION
  end
  nil
end

def gem_deps(*gems)
end

def bin_deps(*bins)
  missing = bins.flatten

  ENV["PATH"].split(PATH_SEPARATOR).each do |path|
    # p path: path
    missing = missing.delete_if do |bin|
      fullpath = File.join(path, bin+BINARY_EXTENSION)
      # p fullpath
      File.exists? fullpath
    end

    break if missing.empty?
  end

  if missing.any?
    puts "missing binaries: #{missing.join(", ")}"
    exit 1
  end

  true
end


def deps(&block)
  d = Deps.new(&block)
  d.check!
end

def packages(&block)
end

##################################################################

class Deps

  PACKAGE_MANAGERS = {
    rpm: {
      install: ["yum", "install"],
      check:   ["rpm", "-q"]
    },

    deb: {
      install: ["apt-get", "install"],
      check:   ["dpkg", "-s"]
    },

    arch: {
      install: ["pacman", "-U"],
      check:   ["pacman", "-Q"]
    }
  }

  #----------------------------------------------------

  class DSL
    def initialize
      @gems = []
      @bins = []
    end

    def gem(name)
      @gems << name
    end
    
    def bin(name, opts={})
      @bins << [name, opts]
    end
  end

  #----------------------------------------------------

  def initialize(&block)
    @dsl = DSL.new(&block)
  end

  def check!
    check_gems!
    check_bins!
  end

  def check_gems!
    gems = @gems.flatten

    missing = []

    gems.each do |gem|
      begin
        require gem
      rescue LoadError
        missing << gem
      end
    end

    if missing.any?
      puts "missing gems: #{missing.join(", ")}"
      exit 1
    end
  end

  def check_bins!
    missing = @bins.keys

    ENV["PATH"].split(PATH_SEPARATOR).each do |path|
      # p path: path
      missing = missing.delete_if do |bin|
        fullpath = File.join(path, bin+BINARY_EXTENSION)
        # p fullpath
        File.exists? fullpath
      end

      break if missing.empty?
    end

  end

  def check_packages!(missing_bins)

    packages = packages.flatten

    case OS.distro
    when :arch
      PACKAGE_MANAGERS[:arch]
    when :ubuntu, :debian
      PACKAGE_MANAGERS[:deb]
    when :fedora
      PACKAGE_MANAGERS[:rpm]
    else
      $stderr.puts "Unknown distro: #{OS.distro}"
      exit 1
    end

  end

  def system_silent(*cmd)
    IO.popen(cmd, err: [:child, :out]) { |io| }
    $?.exitstatus == 0
  end

end

##################################################################
