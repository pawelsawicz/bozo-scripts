module Bozo::Hooks
  
  class Timing
  
    def initialize
      @timings = {}
    end
    
    def print_timings
      puts ''
      @timings.each do |stage, times|
        puts format_timing(stage, times).bright.color(stage == :build ? :cyan : :black)
      end
    end
    
    def format_timing(stage, args)
      time_taken = (args[:post] - args[:pre]).round(1)
      "#{stage.to_s.capitalize.ljust(14)} #{time_taken.to_s.rjust(5)}s"
    end
    
    def record(stage, point)
      @timings[stage] ||= {}
      @timings[stage][point] = Time.now
    end
    
    def method_missing(method, *args)
      if method.to_s =~ /^(pre|post)_(.+)/
        record $2.to_sym, $1.to_sym
        print_timings if $1 == 'post' and $2 == 'build'
      else
        super
      end
    end
    
    def respond_to?(method)
      method.to_s =~ /^(pre|post)_(.+)/ or super
    end
  
  end
  
end