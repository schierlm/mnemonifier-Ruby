# encoding: UTF-8

# Mnemonifier provides methods for converting Unicode strings (containing any
# Unicode characters including those not in the Basic Multilingual Plane) to
# ASCII-only strings that can be converted back to the original strings while
# still trying to be human-readable.
#
# This is achieved by using RFC1345 mnemonics (<tt>à</tt> becomes
# <tt>[a!]</tt>) and decomposition mappings (<tt>Ǹ</tt> becomes
# <tt>[N|!]</tt>). Anything not included in either of these two lists is
# represented as hex code (<tt>€</tt> becomes <tt>[#20AC]}).
#
# To enable rounddtrip conversion, any square brackets inside the original
# string are replaced by <tt>[[]</tt> and <tt>[]]</tt>, respectively.
#
# The decoder is available in two versions: The strict version will throw an
# exception if any square bracket is not encoded correctly, the lax version
# (for cases where the user is able to edit/type encoded strings) will pass
# these unchanged.
#
# In case the +unidecode+ gem can be loaded, it will be used to provide
# additional information about an unencodable character, which is added
# in curly braces (for example <tt>[#20AC{EUR}]</tt>).
#
# Author:: Michael Schierl (mailto:schierlm@gmx.de)
#
module Mnemonifier

  # Class constructor
  def self.initialize_data
    begin
      require 'unidecode'
      @unidecode_loaded = true
    rescue LoadError
      @unidecode_loaded = false
    end
    @forward_map = Array.new(256)
    @reverse_map = {}
    resource_file = File.join(File.dirname(__FILE__), '..', 'data',
                              'mnemonics.dat')
    File.open(resource_file, 'r:UTF-8') do |file|
      current = 0
      ch = file.getc
      while ch
        if ch == ' '
          current += 1
        else
          current = ch.ord
        end
        ch = file.getc
        mnemonic = ''
        while ch && ch.ord > 32 && ch.ord < 128
          mnemonic << ch
          ch = file.getc
        end
        unless @forward_map[current / 256]
          @forward_map[current / 256] = Array.new(256)
        end
        @forward_map[current / 256][current % 256] = mnemonic
        @reverse_map[mnemonic] = current
      end
    end
    @reverse_map
  end

  # whether 'unidecode' gem could be loaded
  @unidecode_loaded = false

  # ragged array, of [256][256] size, to save space
  @forward_map = nil

  # hash, mapping mnemonic strings to codepoints
  @reverse_map = initialize_data

  # Convert any Unicode string into mnmenonics.
  def self.mnemonify(input)
    return input if /^[ -~]*$/.match(input) && !/[\[\]]/.match(input)
    result = ''
    input.each_char do |ch|
      if ch == '['
        result << '[[]'
      elsif ch == ']'
        result << '[]]'
      elsif ch.ord < 128
        result << ch
      elsif ch.ord < 0x10000 && @forward_map[ch.ord / 256] &&
            @forward_map[ch.ord / 256][ch.ord % 256]
        result << '[' + @forward_map[ch.ord / 256][ch.ord % 256] + ']'
      else
        result << format('[#%X', ch.ord)
        if @unidecode_loaded
          ascii = ch.to_ascii
          if ascii != ch && ascii != '[?]' && ascii != '?' &&
             !/[{}]/.match(ascii)
            result << '{' + ascii + '}'
          end
        end
        result << ']'
      end
    end
    result
  end

  # Convert mnemonified string back to original.
  def self.unmnemonify(input, strict = false)
    fail ArgumentError, input if strict && input.include?(']') && !input.include?('[')
    return input unless input.include?('[')
    result = ''
    parsed_offset = 0
    offset = input.index('[')
    while offset
      literal_part = input[parsed_offset, offset - parsed_offset]
      fail ArgumentError, input if strict && literal_part.include?(']')
      result << literal_part
      parsed_offset = offset
      parsed = false
      if offset + 2 < input.length && input[offset + 1, 1] == '#'
        hex_end = offset + 2
        c = input[hex_end, 1]
        while '0123456789ABCDEFabcdef'.include?(c)
          hex_end += 1
          break if hex_end >= input.length
          c = input[hex_end, 1]
        end
        tag_end = nil
        if c == ']'
          tag_end = hex_end + 1
        elsif c == '{'
          pos = input.index('}', hex_end + 1)
          tag_end = pos + 2 if pos && input[pos, 2] == '}]'
        end
        if hex_end > offset + 2 && tag_end
          parsed = true
          codepoint_hex = input[offset + 2, hex_end - offset - 2]
          codepoint = codepoint_hex.hex
          fail ArgumentError, input if strict && codepoint_hex != format('%X', codepoint)
          result << [codepoint].pack('U')
          parsed_offset = tag_end
        end
      elsif offset + 1 < input.length && '[]'.include?(input[offset + 1, 1])
        if offset + 2 < input.length && input[offset+2, 1] == ']'
          parsed = true
          result << input[offset + 1, 1]
          parsed_offset = offset + 3
        end
      else
        end_offset = input.index(']', offset + 1)
        if end_offset
          decoded = @reverse_map[input[offset + 1, end_offset - offset - 1]]
          if decoded
            parsed = true
            result << [decoded].pack('U')
            parsed_offset = end_offset + 1
          end
        end
      end
      unless parsed
        fail ArgumentError, input if strict
        result << '['
        parsed_offset += 1
      end
      offset = input.index('[', parsed_offset)
    end
    literal_tail = input[parsed_offset, input.length - parsed_offset]
    fail ArgumentError, input if strict && literal_tail.include?(']')
    result << literal_tail
  end
end
