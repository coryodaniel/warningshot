require "." / "lib" / "resolvers" / "file_resolver"

describe WarningShot::FileResolver do
  before :all do
    WarningShot::FileResolver.logger = $logger

    @@base_path = File.expand_path("." / "test" / "data" / "resolvers" / "file")
    @@source_path   = @@base_path / 'src'
    @@dest_path     = @@base_path / 'dest'
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
   
  describe 'with healing enabled' do
    describe 'with heal instructions' do
      describe 'file does not exist' do
        it 'should add failed dependencies to #failed' do
          that_file = @@source_path / 'that.txt'
          this_file = @@dest_path / 'this.txt'
          
          fd = WarningShot::FileResolver.new(WarningShot::Config.create,:file,{:source  => "file://#{that_file}",:target => this_file})
          fd.test!
          
          fd.failed.length.should be(1)
        end 
        
        it 'should heal a file from file://' do
          that_file = @@source_path / 'that.txt'
          this_file = @@dest_path / 'this.txt'
          
          fd = WarningShot::FileResolver.new( WarningShot::Config.create,:file,{:source  => "file://#{that_file}",:target => this_file})
          fd.test!
          fd.failed.length.should be(1)
          fd.resolve!
          fd.resolved.length.should be(1)
        end
        
        it 'should heal a file from http://' do
          fd = WarningShot::FileResolver.new( WarningShot::Config.create,:file,{:source  => "http://www.example.com/",:target => (@@dest_path / 'internetz.html')})
          fd.test!
          fd.failed.length.should be(1)
          fd.resolve!
          fd.resolved.length.should be(1)
        end
        
        it 'should be able to verify the root ca and peer when healing over https' do
          pending
        end
                
        it 'should not increment #resolved if the resolution fails' do
          fd = WarningShot::FileResolver.new( WarningShot::Config.create,:file,{:source  => "http://www.example.com/DOESNT.EXIST",:target => (@@dest_path / 'doesnt_exist.html')})
          fd.test!
          fd.failed.length.should be(1)
          fd.resolve!
          fd.failed.length.should_not be(2)
        end
      end # End healing enabled, instructions provided, file does not exists
    end # End healing enabled, instructions provided
    
    describe 'without heal instructions' do
      it 'should be able to return unresolved dependencies' do
        this_file = @@dest_path / 'this.txt'
        
        fd = WarningShot::FileResolver.new( WarningShot::Config.create,:file,{:target => this_file})
        fd.test!
        fd.resolve!
        fd.unresolved.length.should be(1)

        fd = WarningShot::FileResolver.new WarningShot::Config.create,:file, this_file
        fd.test!
        fd.resolve!
        fd.unresolved.length.should be(1)
      end
      
      describe 'file does not exist' do 
        it 'should add dependency to #failed' do
          this_file = @@dest_path / 'this.txt'

          fd = WarningShot::FileResolver.new( WarningShot::Config.create,:file,{:target => this_file})
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
      describe 'file does not exist' do 
        it 'should add dependency to #failed' do
          that_file = @@source_path / 'that.txt'
          this_file = @@dest_path / 'this.txt'

          fd = WarningShot::FileResolver.new( WarningShot::Config.create,:file,{:target => this_file,:source => that_file})
          fd.test!
          fd.failed.length.should be(1)
        end
      end # End healing disabled, instructions provided, file does not exists
    end
    
    describe 'without heal instructions' do      
      describe 'file does not exist' do 
        it 'should add dependency to #failed' do
          this_file = @@dest_path / 'this.txt'

          fd = WarningShot::FileResolver.new( WarningShot::Config.create,:file,{:target => this_file})
          fd.test!
          fd.failed.length.should be(1)
        end
      end # End healing disabled, instructions not provided, file does not exists
    end # End healing disabled, instructions not provided
  end # End healing disabled
end