# encoding: UTF-8
require 'test/unit'
require 'mnemonifier'

# Test case
class MnemonifierTest < Test::Unit::TestCase

  def test_simple
    single_test 'Hello', 'Hello'
    single_test 'Für Elisè', 'F[u:]r Elis[e!]'
    single_test '[x]', '[[]x[]]'
    single_test "\u{20ac 20b9}", '[#20AC][#20B9]', '[#20AC{EU}][#20B9]'
    single_test "\u{20ac 1d11e 20b9}", '[#20AC][#1D11E][#20B9]', '[#20AC{EU}][#1D11E][#20B9]'
    single_test "\u{301 400}", "[|'][E=|!]"
  end

  def test_decoding
    assert_equal ']][[Hello][#q][', Mnemonifier.unmnemonify(']][[Hello][#q][')
    assert_equal "\u20ac[[", Mnemonifier.unmnemonify('[#20ac][[')
    8.times do |i|
      assert_equal '[#123{4}'[0, i], Mnemonifier.unmnemonify('[#123{4}'[0, i])
    end
    [']][[Hello][#q][', '[#20aC]', 'Lo]vely', '[O:]rks]l',
     'Hi['].each do |invalid|
      assert_raise ArgumentError do
        Mnemonifier.unmnemonify(invalid, true)
      end
    end
  end

  def test_roundtrip
    chars = ''
    0x10000.times do |i|
      chars << [i].pack('U') if i < 0xD800 || i > 0xDFFF
    end
    roundtrip_test chars
  end

  def test_roundtrip_surrogates
    chars = ''
    # Ruby is slower than Java, so we only test the first 2 planes...
    0x20000.times do |i|
      if i < 0xD800 || i > 0xDFFF
        ch = [i].pack('U')
        chars << ch if /\p{Assigned}/.match(ch)
      end
    end
    roundtrip_test chars
  end

  def single_test(input, encoded, encoded_alt = nil)
    output = Mnemonifier.mnemonify(input)
    encoded = encoded_alt if output == encoded_alt
    assert_equal encoded, output
    assert_equal input, Mnemonifier.unmnemonify(encoded)
    assert_equal input, Mnemonifier.unmnemonify(encoded, true)
  end

  def roundtrip_test(input)
    encoded = Mnemonifier.mnemonify(input)
    assert_no_match /[^\u{0}-\u{7F}]/, encoded
    assert_equal input, Mnemonifier.unmnemonify(encoded)
    assert_equal input, Mnemonifier.unmnemonify(encoded, true)
  end
end
