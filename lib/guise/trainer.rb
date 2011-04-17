require 'digest/sha1'
module Guise
  class Trainer
    attr_reader :bloom_filter
    def initialize
      @bloom_filter = BloominSimple.new(50_000) do |word|
        Digest::SHA1.digest(word.downcase.strip).unpack("VVV")
      end
      File.open(File.join(File.dirname(__FILE__), "../../data/stopwords.txt")).each do |line| 
        @bloom_filter.add(line)
      end
      @rows = []
      @word_set = []
    end
    
    # Using a bloom filter to load in the stop words and to kill all of them out of the file
    # stopwords.txt  will need to look into this to add as time goes on.
    # Emoticons are important and haven't been considered.
    def strip_stopwords(text = "")
      extracted_terms = []
      text.downcase.gsub(/[^A-Za-z0-9\s]/, '').split(/\s+/).uniq.each do |word| 
        if passes(word)
          extracted_terms << word
        end
      end
      extracted_terms
    end
    
    def vote(sentiment, text)
      terms = strip_stopwords(text)
      @word_set |= terms
      unless terms.empty?
        @rows << {sentiment => terms}
      end
    end
    
    def passes(word)
      !@bloom_filter.includes?(word)
    end
  end
end