# Timecode is a convenience object for calculating SMPTE timecode natively.
# The promise is that you only have to store two values to know the timecode - the amount
# of frames and the framerate. An additional perk might be to save the dropframeness,
# but we avoid that at this point.
#
# You can calculate in timecode objects ass well as with conventional integers and floats.
# Timecode is immutable and can be used as a value object. Timecode objects are sortable.
#
# Here's how to use it with ActiveRecord (your column names will be source_tc_frames_total and tape_fps)
#
#   composed_of :source_tc, :class_name => 'Timecode',
#     :mapping => [%w(source_tc_frames total), %w(tape_fps fps)]

require "approximately"

class Timecode

  VERSION = '2.1.0'

  include Comparable, Approximately

  DEFAULT_FPS = 25.0

  #:stopdoc:

  # Quoting the Flame project configs here (as of ver. 2013 at least)
  # TIMECODE KEYWORD
  # ----------------
  # Specifies the default timecode format used by the project. Currently
  # supported formats are 23.976, 24, 25, 29.97, 30, 50, 59.94 or 60 fps
  # timecodes.
  STANDARD_RATES = [23.976, 24, 25, 29.97, 30, 50, 59.94, 60].map do | float |
    Approximately.approx(float, 0.002) # Tolerance of 2 millisecs should do.
  end.freeze

  NTSC_FPS = (30.0 * 1000 / 1001).freeze
  FILMSYNC_FPS = (24.0 * 1000 / 1001).freeze
  ALLOWED_FPS_DELTA = (0.001).freeze

  COMPLETE_TC_RE = /^(\d{2}):(\d{2}):(\d{2}):(\d{2})$/
  COMPLETE_TC_RE_24 = /^(\d{2}):(\d{2}):(\d{2})\+(\d{2})$/
  DF_TC_RE = /^(\d{1,2}):(\d{1,2}):(\d{1,2});(\d{2})$/
  FRACTIONAL_TC_RE = /^(\d{2}):(\d{2}):(\d{2})[\.,](\d{1,8})$/
  TICKS_TC_RE = /^(\d{2}):(\d{2}):(\d{2}):(\d{3})$/

  WITH_FRACTIONS_OF_SECOND = "%02d:%02d:%02d.%02d"
  WITH_SRT_FRACTION = "%02d:%02d:%02d,%02d"
  WITH_FRACTIONS_OF_SECOND_COMMA = "%02d:%02d:%02d,%03d"
  WITH_FRAMES = "%02d:%02d:%02d:%02d"
  WITH_FRAMES_24 = "%02d:%02d:%02d+%02d"

  #:startdoc:

  # All Timecode lib errors inherit from this
  class Error < RuntimeError; end

  # Gets raised if timecode is out of range (like 100 hours long)
  class RangeError < Error; end

  # Gets raised when a timecode cannot be parsed
  class CannotParse < Error; end

  # Gets raised when you try to compute two timecodes with different framerates together
  class WrongFramerate < ArgumentError; end

  # Initialize a new Timecode object with a certain amount of frames and a framerate
  # will be interpreted as the total number of frames
  def initialize(total = 0, fps = DEFAULT_FPS)
    raise WrongFramerate, "FPS cannot be zero" if fps.zero?
    self.class.check_framerate!(fps)
    # If total is a string, use parse
    raise RangeError, "Timecode cannot be negative" if total.to_i < 0
    # Always cast framerate to float, and num of rames to integer
    @total, @fps = total.to_i, fps.to_f
    @value = validate!
    freeze
  end

  def inspect # :nodoc:
    string_repr = if (framerate_in_delta(fps, 24))
      WITH_FRAMES_24 % value_parts
    else
      WITH_FRAMES % value_parts
    end
    "#<Timecode:%s (%dF@%.2f)>" % [string_repr, total, fps]
  end

  class << self

    # Returns the list of supported framerates for this subclass of Timecode
    def supported_framerates
      STANDARD_RATES + (@custom_framerates || [])
    end

    # Use this to add a custom framerate
    def add_custom_framerate!(rate)
      @custom_framerates ||= []
      @custom_framerates.push(rate)
    end

    # Check the passed framerate and raise if it is not in the list
    def check_framerate!(fps)
      unless supported_framerates.include?(fps)
        supported = "%s and %s are supported" % [supported_framerates[0..-2].join(", "), supported_framerates[-1]]
        raise WrongFramerate, "Framerate #{fps} is not in the list of supported framerates (#{supported})"
      end
    end

    # Use initialize for integers and parsing for strings
    def new(from = nil, fps = DEFAULT_FPS)
      from.is_a?(String) ? parse(from, fps) : super(from, fps)
    end

    # Parse timecode and return zero if none matched
    def soft_parse(input, with_fps = DEFAULT_FPS)
      parse(input) rescue new(0, with_fps)
    end

    # Parses the timecode contained in a passed filename as frame number in a sequence
    def from_filename_in_sequence(filename_with_or_without_path, fps = DEFAULT_FPS)
      b = File.basename(filename_with_or_without_path)
      number = b.scan(/\d+/).flatten[-1].to_i
      new(number, fps)
    end

    # Parse timecode entered by the user. Will raise if the string cannot be parsed.
    # The following formats are supported:
    # * 10h 20m 10s 1f (or any combination thereof) - will be disassembled to hours, frames, seconds and so on automatically
    # * 123 - will be parsed as 00:00:01:23
    # * 00:00:00:00 - will be parsed as zero TC
    def parse(spaced_input, with_fps = DEFAULT_FPS)
      input = spaced_input.strip

      # Drop frame goodbye
      if (input =~ DF_TC_RE)
        raise Error, "We do not support drop-frame TC"
      # 00:00:00:00
      elsif (input =~ COMPLETE_TC_RE)
        atoms_and_fps = input.scan(COMPLETE_TC_RE).to_a.flatten.map{|e| e.to_i} + [with_fps]
        return at(*atoms_and_fps)
      # 00:00:00+00
      elsif (input =~ COMPLETE_TC_RE_24)
        atoms_and_fps = input.scan(COMPLETE_TC_RE_24).to_a.flatten.map{|e| e.to_i} + [24]
        return at(*atoms_and_fps)
      # 00:00:00.0
      elsif input =~ FRACTIONAL_TC_RE
        parse_with_fractional_seconds(input, with_fps)
      # 00:00:00:000
      elsif input =~ TICKS_TC_RE
        parse_with_ticks(input, with_fps)
      # 10h 20m 10s 1f 00:00:00:01 - space separated is a sum of parts
      elsif input =~ /\s/
        parts = input.gsub(/\s/, ' ').split.reject{|e| e.strip.empty? }
        raise CannotParse, "No atoms" if parts.empty?
        parts.map{|part|  parse(part, with_fps) }.inject{|sum, p| sum + p.total }
      # 10s
      elsif input =~ /^(\d+)s$/
        return new(input.to_i * with_fps, with_fps)
      # 10h
      elsif input =~ /^(\d+)h$/i
        return new(input.to_i * 60 * 60 * with_fps, with_fps)
      # 20m
      elsif input =~ /^(\d+)m$/i
        return new(input.to_i * 60 * with_fps, with_fps)
      # 60f - 60 frames, or 2 seconds and 10 frames
      elsif input =~ /^(\d+)f$/i
        return new(input.to_i, with_fps)
      # Only a bunch of digits, treat 12345 as 00:01:23:45
      elsif (input =~ /^(\d+)$/)
        atoms_len = 2 * 4
        # left-pad input AND truncate if needed
        padded = input[0..atoms_len].rjust(8, "0")
        atoms = padded.scan(/(\d{2})/).flatten.map{|e| e.to_i } + [with_fps]
        return at(*atoms)
      else
        raise CannotParse, "Cannot parse #{input} into timecode, unknown format"
      end
    end

    # Initialize a Timecode object at this specfic timecode
    def at(hrs, mins, secs, frames, with_fps = DEFAULT_FPS)
      validate_atoms!(hrs, mins, secs, frames, with_fps)
      total = (hrs*(60*60*with_fps) +  mins*(60*with_fps) + secs*with_fps + frames).round
      new(total, with_fps)
    end

    # Validate the passed atoms for the concrete framerate
    def validate_atoms!(hrs, mins, secs, frames, with_fps)
      case true
      when hrs > 999
          raise RangeError, "There can be no more than 999 hours, got #{hrs}"
        when mins > 59
          raise RangeError, "There can be no more than 59 minutes, got #{mins}"
        when secs > 59
          raise RangeError, "There can be no more than 59 seconds, got #{secs}"
        when frames >= with_fps
          raise RangeError, "There can be no more than #{with_fps} frames @#{with_fps}, got #{frames}"
      end
    end

    # Parse a timecode with fractional seconds instead of frames. This is how ffmpeg reports
    # a timecode
    def parse_with_fractional_seconds(tc_with_fractions_of_second, fps = DEFAULT_FPS)
      fraction_expr = /[\.,](\d+)$/
      fraction_part = ('.' + tc_with_fractions_of_second.scan(fraction_expr)[0][0]).to_f

      seconds_per_frame = 1.0 / fps.to_f
      frame_idx = (fraction_part / seconds_per_frame).floor

      tc_with_frameno = tc_with_fractions_of_second.gsub(fraction_expr, ":%02d" % frame_idx)

      parse(tc_with_frameno, fps)
    end

    # Parse a timecode with ticks of a second instead of frames. A 'tick' is defined as
    # 4 msec and has a range of 0 to 249. This format can show up in subtitle files for digital cinema
    # used by CineCanvas systems
    def parse_with_ticks(tc_with_ticks, fps = DEFAULT_FPS)
      ticks_expr = /(\d{3})$/
      num_ticks = tc_with_ticks.scan(ticks_expr).join.to_i

      raise RangeError, "Invalid tick count #{num_ticks}" if num_ticks > 249

      seconds_per_frame = 1.0 / fps
      frame_idx = ( (num_ticks * 0.004) / seconds_per_frame ).floor
      tc_with_frameno = tc_with_ticks.gsub(ticks_expr, "%02d" % frame_idx)

      parse(tc_with_frameno, fps)
    end

    # create a timecode from the number of seconds. This is how current time is supplied by
    # QuickTime and other systems which have non-frame-based timescales
    def from_seconds(seconds_float, the_fps = DEFAULT_FPS)
      total_frames = (seconds_float.to_f * the_fps.to_f).to_i
      new(total_frames, the_fps)
    end

    # Some systems (like SGIs) and DPX format store timecode as unsigned integer, bit-packed. This method
    # unpacks such an integer into a timecode.
    def from_uint(uint, fps = DEFAULT_FPS)
      tc_elements = (0..7).to_a.reverse.map do | multiplier |
        ((uint >> (multiplier * 4)) & 0x0F)
      end.join.scan(/(\d{2})/).flatten.map{|e| e.to_i}

      tc_elements << fps
      at(*tc_elements)
    end
  end

  def coerce(to)
    me = case to
      when String
        to_s
      when Integer
        to_i
      when Float
        to_f
      else
        self
    end
    [me, to]
  end

  # is the timecode at 00:00:00:00
  def zero?
    @total.zero?
  end

  # get total frame count
  def total
    to_f
  end

  # get FPS
  def fps
    @fps
  end

  # get the number of frames
  def frames
    value_parts[3]
  end

  # get the number of seconds
  def seconds
    value_parts[2]
  end

  # get the number of minutes
  def minutes
    value_parts[1]
  end

  # get the number of hours
  def hours
    value_parts[0]
  end

  # get frame interval in fractions of a second
  def frame_interval
    1.0/@fps
  end

  # get the timecode as bit-packed unsigned 32 bit int (suitable for DPX and SGI)
  def to_uint
    elements = (("%02d" * 4) % [hours,minutes,seconds,frames]).split(//).map{|e| e.to_i }
    uint = 0
    elements.reverse.each_with_index do | p, i |
      uint |= p << 4 * i
    end
    uint
  end

  # get the timecode as a floating-point number of seconds (used in Quicktime)
  def to_seconds
    (@total / @fps)
  end

  # Convert to different framerate based on the total frames. Therefore,
  # 1 second of PAL video will convert to 25 frames of NTSC (this
  # is suitable for PAL to film TC conversions and back).
  def convert(new_fps)
    self.class.new(@total, new_fps)
  end

  # Get formatted SMPTE timecode. Hour count larger than 99 will roll over to the next
  # remainder (129 hours will produce "29:00:00:00:00"). If you need the whole hour count
  # use `to_s_without_rollover`
  def to_s
    vs = value_parts
    vs[0] = vs[0] % 100 # Rollover any values > 99
    WITH_FRAMES % vs
  end
  
  # Get formatted SMPTE timecode. Hours might be larger than 99 and will not roll over
  def to_s_without_rollover
    WITH_FRAMES % value_parts
  end
  
  # get total frames as float
  def to_f
    @total
  end

  # get total frames as integer
  def to_i
    @total
  end

  # add number of frames (or another timecode) to this one
  def +(arg)
    if (arg.is_a?(Timecode) && framerate_in_delta(arg.fps, @fps))
      self.class.new(@total+arg.total, @fps)
    elsif (arg.is_a?(Timecode))
      raise WrongFramerate, "You are calculating timecodes with different framerates"
    else
      self.class.new(@total + arg, @fps)
    end
  end

  # Tells whether the passes timecode is immediately to the left or to the right of that one
  # with a 1 frame difference
  def adjacent_to?(another)
    (self.succ == another) || (another.succ == self)
  end

  # Subtract a number of frames
  def -(arg)
    if (arg.is_a?(Timecode) &&  framerate_in_delta(arg.fps, @fps))
      self.class.new(@total-arg.total, @fps)
    elsif (arg.is_a?(Timecode))
      raise WrongFramerate, "You are calculating timecodes with different framerates"
    else
      self.class.new(@total-arg, @fps)
    end
  end

  # Multiply the timecode by a number
  def *(arg)
    raise RangeError, "Timecode multiplier cannot be negative" if (arg < 0)
    self.class.new(@total*arg.to_i, @fps)
  end

  # Get the next frame
  def succ
    self.class.new(@total + 1, @fps)
  end

  # Get the number of times a passed timecode fits into this time span (if performed with Timecode) or
  # a Timecode that multiplied by arg will give this one
  def /(arg)
    arg.is_a?(Timecode) ?  (@total / arg.total) : self.class.new(@total / arg, @fps)
  end

  # Timecodes can be compared to each other
  def <=>(other_tc)
    if framerate_in_delta(fps, other_tc.fps)
      self.total <=> other_tc.total
    else
      raise WrongFramerate, "Cannot compare timecodes with different framerates"
    end
  end

  # FFmpeg expects a fraction of a second as the last element instead of number of frames. Use this
  # method to get the timecode that adheres to that expectation. The return of this method can be fed
  # to ffmpeg directly.
  #  Timecode.parse("00:00:10:24", 25).with_frames_as_fraction #=> "00:00:10.96"
  def with_frames_as_fraction(pattern = WITH_FRACTIONS_OF_SECOND)
    vp = value_parts.dup
    vp[-1] = (100.0 / @fps) * vp[-1]
    pattern % vp
  end
  alias_method :with_fractional_seconds, :with_frames_as_fraction

  # SRT uses a fraction of a second as the last element instead of number of frames, with a comma as
  # the separator
  #  Timecode.parse("00:00:10:24", 25).with_srt_fraction #=> "00:00:10,96"
  def with_srt_fraction
    with_frames_as_fraction(WITH_SRT_FRACTION)
  end

  # Validate that framerates are within a small delta deviation considerable for floats
  def framerate_in_delta(one, two)
    (one.to_f - two.to_f).abs <= ALLOWED_FPS_DELTA
  end

  private

  # Prepare and format the values for TC output
  def validate!
    secs = (@total / @fps).floor
    rest_frames = (@total % @fps).floor
    hrs = secs.to_i / 3600
    mins = (secs.to_i / 60) % 60
    secs = secs % 60

    self.class.validate_atoms!(hrs, mins, secs, rest_frames, @fps)

    [hrs, mins, secs, rest_frames]
  end

  def value_parts
    @value ||= validate!
  end

end