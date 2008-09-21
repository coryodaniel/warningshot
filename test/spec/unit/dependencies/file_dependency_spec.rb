require File.join(%w(. lib dependencies file_dependency))

# VALID YAML (mode,user,group, src are all optional)
# '~/some.file'
# '/path/to/a.file'
# 'PROTOCOL://path/to/a.file'
# { dest: "/path/to/data.txt", src: "PROTOCOL://example.com/index.html"}
# { dest: "/path/to/data.txt", src: "/example.com/index.html"}

describe WarningShot::FileDependency do
  before :all do
    @@logger = Logger.new STDOUT
    @@logger.level = Logger::FATAL
    @@base_path = File.expand_path(File.join(%w(. test data dependencies file)))
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
  it 'should respond to FileDependency#test' do
    WarningShot::FileDependency.new.respond_to?(:test).should be(true)
  end
  
  it 'should respond to FileDependency#heal' do
    WarningShot::FileDependency.new.respond_to?(:heal).should be(true)
  end
   
  describe 'with healing enabled' do
    describe 'with heal instructions' do
      it 'should raise an error if the protocol is invalid' do
        that_file = File.join @@src_path, 'that.txt'
        this_file = File.join @@dest_path, 'this.txt'
        
        fd = WarningShot::FileDependency.new
        fd.logger = @@logger
        fd.init [{:src  => "fake://#{that_file}",:dest => this_file}]
        fd.test
        lambda {fd.heal}.should raise_error(WarningShot::FileDependency::UnsupportedProtocolException)
      end
      
      describe 'file exists' do
        it 'should do nothing' do
          #nothing
        end
      end # End healing enabled, instructions provided, file exists
      
      describe 'file does not exist' do
        it 'should increment #errors that the file is missing' do
          that_file = File.join @@src_path, 'that.txt'
          this_file = File.join @@dest_path, 'this.txt'
          
          fd = WarningShot::FileDependency.new
          fd.logger = @@logger
          fd.init [{:src  => "file://#{that_file}",:dest => this_file}]
          fd.test
          
          fd.errors.should be(1)
        end 
        
        it 'should heal a file from file://' do
          that_file = File.join @@src_path, 'that.txt'
          this_file = File.join @@dest_path, 'this.txt'
          
          fd = WarningShot::FileDependency.new
          fd.logger = @@logger
          fd.init [{:src  => "file://#{that_file}",:dest => this_file}]
          fd.test
          fd.heal
          fd.healed.should be(1)
        end
        
        it 'should heal a file from http://' do
          fd = WarningShot::FileDependency.new
          fd.logger = @@logger
          fd.init [{:src  => "http://www.example.com/",:dest => File.join(@@dest_path,'internetz.html')}]

          fd.test
          fd.heal
          fd.healed.should be(1)
        end
                
        it 'should increment #errors if the healing fails' do
          fd = WarningShot::FileDependency.new
          fd.logger = @@logger
          fd.init [{:src  => "http://www.example.com/DOESNT.EXIST",:dest => File.join(@@dest_path,'doesnt_exist.html')}]
          fd.test
          fd.errors.should be(1)
          fd.heal
          fd.errors.should be(2)
        end
      end # End healing enabled, instructions provided, file does not exists
    end # End healing enabled, instructions provided
    
    describe 'without heal instructions' do
      it 'should raise a warning for missing heal instructions' do
        this_file = File.join @@dest_path, 'this.txt'
        
        fd = WarningShot::FileDependency.new
        fd.logger = @@logger
        fd.init [{:dest => this_file}]
        fd.test
        fd.heal
        fd.warnings.should be(1)
        
        fd.init [this_file]
        fd.test
        fd.heal
        fd.warnings.should be(1)
      end
      
      describe 'file exists' do
        it 'should do nothing' do
          #nothing
        end
      end # End healing enabled, instructions not provided, file exists
      
      describe 'file does not exist' do 
        it 'should increment #errors' do
          this_file = File.join @@dest_path, 'this.txt'

          fd = WarningShot::FileDependency.new
          fd.logger = @@logger
          fd.init [{:dest => this_file}]
          fd.test
          fd.errors.should be(1)
          fd.heal
          fd.errors.should be(2)
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
        it 'should increment #errors' do
          that_file = File.join @@src_path, 'that.txt'
          this_file = File.join @@dest_path, 'this.txt'

          fd = WarningShot::FileDependency.new
          fd.logger = @@logger
          fd.init [{:dest => this_file,:src => that_file}]
          fd.test
          fd.errors.should be(1)
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
        it 'should increment #errors' do
          this_file = File.join @@dest_path, 'this.txt'

          fd = WarningShot::FileDependency.new
          fd.logger = @@logger
          fd.init [{:dest => this_file}]
          fd.test
          fd.errors.should be(1)
        end
      end # End healing disabled, instructions not provided, file does not exists
    end # End healing disabled, instructions not provided
  end # End healing disabled
end