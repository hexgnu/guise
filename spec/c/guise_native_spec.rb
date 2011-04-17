require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe Guise do
  context "training" do
    before(:each) do
      sr = Struct.new(:y, :x)
      #@training = [{"1" => [1,2,3,4,5]}, {"-1" => [1,4,5,6]}, {"0" => [1, 2, 3, 5]}]
      
      @training = [sr.new(1, [1,2,3,4,5]), sr.new(-1, [1,4,5,6]), sr.new(0, [1, 2, 3, 5])]
    end
    
    
    
    
    it 'should have a class under Guise called Training' do
      lambda { Guise::Model }.should_not raise_error
    end
    
    it 'should be able to accept training in rows and spit back a model' do
      # svm_type c_svc
      # kernel_type rbf
      # gamma 0.166667
      # nr_class 3
      # total_sv 3
      # rho 0 0 0
      # label 1 -1 0
      # nr_sv 1 1 1
      # SV
      # 1 1 1:1 2:1 3:1 4:1 5:1 
      # -1 1 1:1 4:1 5:1 6:1 
      # -1 -1 1:1 2:1 3:1 5:1
      lambda { Guise::Model.load(@training) }.should_not raise_error
    end
    context "model" do
      before(:each) do
        @model = Guise::Model.load(@training)
        puts "---" * 20
        puts @model.inspect
      end
      
      it 'should be of type c_svc' do
        puts @model["svm_type"]
        @model["svm_type"].should == "c_svc"
      end
      
      it 'kernel should be RBF' do
        @model["kernel"].should == "rbf"
      end
      
      it 'gamma should be 0.166667' do
        @model["gamma"].should == 0.16667
      end
      
      it 'nr_class should be of 3' do
        @model["nr_class"].should == 3
      end
      
      it 'rho should be array of [0,0,0]' do
        @model["rho"].should == [0,0,0]
      end
      
      it 'label should be 1 -1 0' do
        @model["label"].should == [1, -1, 0]
      end
      
      it 'nr_sv should be [1,1,1]' do
        @model["nr_sv"].should == [1,1,1]
      end
      
      it 'should have sv' do
        pending "Still need to figure out what to do here..."
      end
    end
    it 'should raise an error when I give it something besides an array' do
      lambda { Guise::Model.load(1) }.should raise_error
    end
  end  
end