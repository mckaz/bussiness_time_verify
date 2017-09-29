require 'rdl'
require 'types/core'

module BusinessTime
  class ParsedTime
    include Comparable

    attr_reader :hour, :min, :sec

    var_type :@hour, '%integer'
    var_type :@min, '%integer'
    var_type :@sec, '%integer'
    type :hour, '() -> %integer i {{ i == @hour }}', modular: :true, pure: :true
    type :min, '() -> %integer j {{ j == @min }}', modular: :true, pure: :true
    type :sec, '() -> %integer k {{ k == @sec }}', modular: :true, pure: :true

    type '(%integer h, ?%integer m, ?%integer s) -> self out', typecheck: :later
    def initialize(hour, min = 0, sec = 0)
      @hour = hour
      @min = min
      @sec = sec
    end

    def self.parse(time_or_string)
      if time_or_string.is_a?(String)
        time = Time.parse(time_or_string)
      else
        time = time_or_string
      end
      new(time.hour, time.min, time.sec)
    end

    def to_s
      "#{hour}:#{min}:#{sec}"
    end


    ## verifier user defined
    type '(BusinessTime::ParsedTime t) -> %bool'
    def valid_time(t)
      (0 <= t.hour) && (t.hour < 24) && (0 <= t.min) && (t.min < 60) && (0 <= t.sec) && (t.sec < 60)
    end
    
    type '(BusinessTime::ParsedTime other {{ valid_time(self) && valid_time(other) }}) -> %integer diff {{ if self.hour > other.hour then diff > 0 end  }}', verify: :later
    def -(other)
      (hour - other.hour) * 3600 + (min - other.min) * 60 + sec - other.sec
    end

    def <=>(other)
      [hour, min, sec] <=> [other.hour, other.min, other.sec]
    end
  end
end
