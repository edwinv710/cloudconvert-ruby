module CloudConvert
  module VERSION #:nodoc:
      MAJOR    = '0'
      MINOR    = '1'
      TINY     = '0'
      BETA     = nil # Time.now.to_i.to_s
    end

  VERSION= [VERSION::MAJOR, VERSION::MINOR, VERSION::TINY, VERSION::BETA].compact * '.'
end
