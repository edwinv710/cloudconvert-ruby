module CloudConvert
  module VERSION_VALUES #:nodoc:
      MAJOR    = '0'
      MINOR    = '1'
      TINY     = '2'
      BETA     = nil # Time.now.to_i.to_s
    end

  VERSION= [VERSION_VALUES::MAJOR, VERSION_VALUES::MINOR, VERSION_VALUES::TINY, VERSION_VALUES::BETA].compact * '.'
end
