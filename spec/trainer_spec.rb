require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Guise" do
  context "trainer" do
    it 'should be able to turn a sentence into a new training line' do
      Guise::Trainer.train(-1, "Fuck shit god damnit you piece of shit you are a bitch")
    end
  end
end