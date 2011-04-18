require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Guise" do
  context "Trainer" do
    before(:each) do
      sentence_1 = [1, "fee fo"] # [0,1,2]
      sentence_2 = [-1, "fo"] # [2]
      @tr = Guise::Trainer.new(%w[fee fi fo])
      @tr.vote(*sentence_1)
      @tr.vote(*sentence_2)
    end
    
    it 'should return 1 for fee' do
      @tr.predict("fee").should == 1
    end
    
    it 'should return -1 for fo' do
      @tr.predict("fo").should == -1
    end
      
  end
end