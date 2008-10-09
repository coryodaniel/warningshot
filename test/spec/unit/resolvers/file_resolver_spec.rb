=begin
require File.join(%w(. lib resolvers file_resolver))

# VALID YAML (mode,user,group, src are all optional)
# '~/some.file'
# '/path/to/a.file'
# 'PROTOCOL://path/to/a.file'
# { dest: "/path/to/data.txt", src: "PROTOCOL://example.com/index.html"}
# { dest: "/path/to/data.txt", src: "/example.com/index.html"}

describe WarningShot::FileResolver do
  before :all do
    @@base_path = File.expand_path(File.join(%w(. test data resolvers file)))
    @@src_path  = File.join(@@base_path,'src')
    @@dest_path = File.join(@@base_path,'dest')
    FileUtils.mkdir_p @@dest_path
  end
  
  before :each do
    FileUtils.mkdir_p @@dest_path
  end

  after :each do
    FileUtils.rm_rf @@dest_path
  end

  it 'should have tests registered' do
    WarningShot::FileResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions regsitered' do
    WarningShot::FileResolver.resolutions.empty?.should be(false)
  end
  
  it 'should treate relative paths as from directory specified by WarningShot::Config[:application]' do
    pending
  end
   
  describe 'with healing enabled' do
    describe 'with heal instructions' do
      it 'should raise an error if the protocol is not supported' do
        pending
      end
      
      describe 'file exists' do
        it 'should do nothing' do
          #nothing
        end
      end # End healing enabled, instructions provided, file exists
      
      describe 'file does not exist' do
        it 'should add failed dependencies to #failed' do
          that_file = File.join @@src_path, 'that.txt'
          this_file = File.join @@dest_path, 'this.txt'
          
          fd = WarningShot::FileResolver.new
          fd.init [{:src  => "file://#{that_file}",:local => this_file}]
          fd.test!
          
          fd.failed.length.should be(1)
        end 
        
        it 'should heal a file from file://' do
          that_file = File.join @@src_path, 'that.txt'
          this_file = File.join @@dest_path, 'this.txt'
          
          fd = WarningShot::FileResolver.new
          fd.init [{:src  => "file://#{that_file}",:local => this_file}]
          fd.test!
          fd.failed.length.should be(1)
          fd.resolve!
          fd.resolved.length.should be(1)
        end
        
        it 'should heal a file from http://' do
          fd = WarningShot::FileResolver.new

          fd.init [{:src  => "http://www.example.com/",:local => File.join(@@dest_path,'internetz.html')}]
          fd.test!
          fd.failed.length.should be(1)
          fd.resolve!
          fd.resolved.length.should be(1)
        end
                
        it 'should note increment #resolved if the resolution fails' do
          fd = WarningShot::FileResolver.new
          fd.init [{:src  => "http://www.example.com/DOESNT.EXIST",:local => File.join(@@dest_path,'doesnt_exist.html')}]
          fd.test!
          fd.failed.length.should be(1)
          fd.resolve!
          fd.failed.length.should_not be(2)
        end
      end # End healing enabled, instructions provided, file does not exists
    end # End healing enabled, instructions provided
    
    describe 'without heal instructions' do
      it 'should be able to return unresolved dependencies' do
        this_file = File.join @@dest_path, 'this.txt'
        
        fd = WarningShot::FileResolver.new
        fd.init [{:local => this_file}]
        fd.test!
        fd.resolve!
        fd.unresolved.length.should be(1)
        
        fd.init [this_file]
        fd.test!
        fd.resolve!
        fd.unresolved.length.should be(1)
      end
      
      describe 'file exists' do
        it 'should do nothing' do
          #nothing
        end
      end # End healing enabled, instructions not provided, file exists
      
      describe 'file does not exist' do 
        it 'should add dependency to #failed' do
          this_file = File.join @@dest_path, 'this.txt'

          fd = WarningShot::FileResolver.new
          fd.init [{:local => this_file}]
          fd.test!
          fd.failed.length.should be(1)
          fd.resolve!
          fd.unresolved.length.should be(1)
        end
      end # End healing enabled, instructions not provided, file does not exists
    end # End healing enabled, instructions not provided
  end # End healing enabled
  
  describe 'with healing disabled' do
    describe 'with heal instructions' do
      describe 'file exists' do
        it 'should do nothing' do
          #Does nothing
        end
      end # End healing disabled, instructions provided, file exists
      
      describe 'file does not exist' do 
        it 'should add dependency to #failed' do
          that_file = File.join @@src_path, 'that.txt'
          this_file = File.join @@dest_path, 'this.txt'

          fd = WarningShot::FileResolver.new
          fd.init [{:local => this_file,:src => that_file}]
          fd.test!
          fd.failed.length.should be(1)
        end
      end # End healing disabled, instructions provided, file does not exists
    end
    
    describe 'without heal instructions' do
      describe 'file exists' do
        it 'should do nothing' do
          #Does nothing
        end
      end # End healing disabled, instructions not provided, file exists
      
      describe 'file does not exist' do 
        it 'should add dependency to #failed' do
          this_file = File.join @@dest_path, 'this.txt'

          fd = WarningShot::FileResolver.new

          fd.init [{:local => this_file}]
          fd.test!
          fd.failed.length.should be(1)
        end
      end # End healing disabled, instructions not provided, file does not exists
    end # End healing disabled, instructions not provided
  end # End healing disabled
end
=end