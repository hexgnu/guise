require 'digest/sha1'

#        NAME: Guise::Trainer
#      AUTHOR: Matthew Kirk
#     LICENSE: Proprietary 
#   COPYRIGHT: (c) 2011 Matthew Kirk
# DESCRIPTION: 
#             Guise::Trainer is where the SVM model exists
#             This is built up using a training set and the basic api is
#             Guise::Trainer#vote(sentiment, text)
module Guise
  class Trainer
    DIR = File.dirname(__FILE__)
    attr_reader :bloom_filter, :word_set, :rows
    
    
    # Can take in a dictionary of words stored in the database or wherever
    # Initializes a bloomb_filter that will strip out stopwords
    def initialize(word_set = [], load_data = true)
      load_bloom_filter!
      @rows = []
      @word_set = word_set
      if load_data
        load_training_data! 
        load_positive_training_data!
        load_negative_training_data!
      end
    end
    
    # Using a bloom filter to load in the stop words and to kill all of them out of the file
    # Strips urls downcases text and takes out html_nuglets.  This tokenizes the text into 
    # a set of features to build our model on.
    def clean(text = "")
      extracted_terms = []
      non_alpha = /[^a-z\s]/
      html_nuglets = /&.+;/
      Util.strip(text).downcase.gsub(Regexp.union(html_nuglets, non_alpha), '').split(/\s+/).uniq.each do |word| 
        if passes(word)
          extracted_terms << word
        end
      end
      extracted_terms
    end
    
    
    # The sentiment [-1, 0, 1] maps to [negative, neutral, positive] and the text is the features to regress on
    def vote(sentiment, text)
      terms = clean(text)
      @word_set |= terms
      unless terms.empty?
        @rows << {sentiment => indicies(terms)}
      end
    end
    
    # Helper function to determine whether we should keep the word or not
    def passes(word)
      !@bloom_filter.includes?(word)
    end
    
    
    # Builds an libsvm problem
    def problem
      rows = []
      indexes = []
      @rows.each do |row|
        rows << row.keys.first
        indexes << row.values.first
      end
      
      @problem = SVM::Problem.new(rows, *indexes)
    end
    
    
    # Based on cross validation we should be using a C of 2 and a gamma of 0.125
    # This will yield the best results for our current data set.
    # will need to be reviewed in the future to see if still relevant
    def params
      SVM::Parameter.new(:kernel_type => RBF, :C => 2, :gamma => 0.125)
    end
    
    # Returns libsvm model
    def model
      @model ||= SVM::Model.new(problem, params)
    end
    
    # Returns libsvm model and destroys older version
    def model!
      @model = SVM::Model.new(problem, params)
    end
    
    # Returns a prediction based on training data when fed in a block of text
    def predict(text)
      indexes = indicies(clean(text)).compact
      model.predict(indexes)
    end
    
    # Helper function for finding indicies of words in word_set
    def indicies(words)
      words.map { |word| @word_set.index(word) }
    end
    
    # Kills the current model
    def flush!
      @word_set = []
      @rows = []
      @model = nil
    end
    
    # Will output a friendly format for libsvm for testing
    def output_file
      rows.map do |row|
        label = row.keys.first
        indexes = row.values.first.sort.map {|idx| [idx + 1, 1].join(":")}.join("\t")
        [label, indexes].join("\t")
      end.join("\n")
    end
    
    private
    
    %w[positive negative].each do |sentiment|
      define_method("load_#{sentiment}_training_data!") do
        File.open(File.join(DIR, "../../data/#{sentiment}_words.txt")).each do |line|
          vote((sentiment == "positive") ? 1 : -1, line)
        end
      end
    end
    
    
    def load_training_data!
      YAML::load(File.open(File.join(DIR, "../../data/output.yml"))).each do |row|
        if row[:answer].values.first != "-2"
          vote(row[:answer].values.first.to_i, row[:question])
        end
      end
    end
    
    def load_bloom_filter!
      @bloom_filter = BloominSimple.new(50_000) do |word|
        Digest::SHA1.digest(word.downcase.strip).unpack("VVV")
      end
      
      File.open(File.join(File.dirname(__FILE__), "../../data/stopwords.txt")).each do |line| 
        @bloom_filter.add(line)
      end
    end
  end
end