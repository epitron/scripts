require_relative 'os'

if OS.windows?
  PATH_SEPARATOR    = ";"
  BINARY_EXTENSION  = ".exe"
else
  PATH_SEPARATOR    = ":"
  BINARY_EXTENSION  = ""
end

def which(bin)
  ENV["PATH"].split(PATH_SEPARATOR).find do |path|
    fullpath = File.join(path, bin)
    return fullpath if File.exists? fullpath + BINARY_EXTENSION
  end
  nil
end

def gem_deps(*gems)
  gems = gems.flatten

  missing = []

  gems.each do |g|
    begin
      require g
    rescue LoadError
      missing << g
    end
  end

  if missing.any?
    puts "missing gems: #{missing.join(", ")}"
    exit 1
  end
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

def package_deps(*packages)
  packages = packages.flatten

  case OS.distro
  when "arch"
  when "debian"
  when "redhat"
  else
    $stderr.puts "Unknown distro: #{OS.distro}"
    exit 1
  end
end
