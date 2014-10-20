Gem::Specification.new do |s|
  s.name        = 'mnemonifier'
  s.version     = '0.0.0'
  s.date        = '2014-10-11'
  s.summary     = 'Convert Unicode text to human-readable ASCII text and back.'
  s.description = %q{Mnemonifier provides functions for converting Unicode
      strings (containing any Unicode characters including those not in the
      Basic Multilingual Plane) to ASCII-only strings that can be converteds
      back to the original strings while still trying to be human-readable.}
  s.author     = 'Michael Schierl'
  s.email       = 'schierlm@gmx.de'
  s.files       = ['lib/mnemonifier.rb', 'data/mnemonics.dat']
  s.homepage    = 'http://mnemonifier.sourceforge.net/'
  s.license     = 'MIT'
end
