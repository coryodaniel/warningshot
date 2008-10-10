require File.join(%w(. lib resolvers integrity_resolver))

describe WarningShot::IntegrityResolver do
  before :all do
    @@base_path = File.expand_path(File.join(%w(. test data resolvers file)))
    @@src_path  = File.join(@@base_path,'src')
  end
  
  it 'should have tests registered' do
    WarningShot::IntegrityResolver.tests.empty?.should be(false)
  end

  it 'should not have resolutions registered' do
    WarningShot::IntegrityResolver.resolutions.empty?.should be(true)
  end
  
  it 'should be able to verify a sha1 digest' do
    resolver = WarningShot::IntegrityResolver.new
    that_file = File.join @@src_path, 'that.txt'
    #These values are flipped from FileResolverRspec so that we dont
    # have to resolve the file dependency to check the integrity
    resolver.init [{
      :local => "file://#{that_file}",
      :src => "",
      :sha1 => "e87c9091b6f6d30d1a05d66de1acbac6e1998121"
    }]
    
    resolver.test!
    resolver.failed.length.should be(0)    
  end
  
  it 'should be able to determine if a sha1 digest is wrong' do
    resolver = WarningShot::IntegrityResolver.new
    that_file = File.join @@src_path, 'that.txt'
    #These values are flipped from FileResolverRspec so that we dont
    # have to resolve the file dependency to check the integrity
    resolver.init [{
      :local => "file://#{that_file}",
      :src => "",
      :sha1 => "WRONG"
    }]
    
    resolver.test!
    resolver.failed.length.should be(1)
  end
  
  it 'should be able to determine if an md5 digest is wrong' do
    resolver = WarningShot::IntegrityResolver.new
    that_file = File.join @@src_path, 'that.txt'
    #These values are flipped from FileResolverRspec so that we dont
    # have to resolve the file dependency to check the integrity
    resolver.init [{
      :local => "file://#{that_file}",
      :src => "",
      :md5 => "WRONG"
    }]
    
    resolver.test!
    resolver.failed.length.should be(1)
  end
  
  it 'should be able to verify a md5 digest' do
    resolver = WarningShot::IntegrityResolver.new
    that_file = File.join @@src_path, 'that.txt'
    #These values are flipped from FileResolverRspec so that we dont
    # have to resolve the file dependency to check the integrity
    resolver.init [{
      :local => "file://#{that_file}",
      :src => "",
      :md5 => "db59da6066bab8885569c012b1f6b173"
    }]
    
    resolver.test!
    resolver.failed.length.should be(0)
  end
  
  it 'should use sha1 if md5 and sha1 are given' do
    resolver = WarningShot::IntegrityResolver.new
    that_file = File.join @@src_path, 'that.txt'
    #These values are flipped from FileResolverRspec so that we dont
    # have to resolve the file dependency to check the integrity
    resolver.init [{
      :local => "file://#{that_file}",
      :src => "",
      :md5 => "WRONG",
      :sha1 => "e87c9091b6f6d30d1a05d66de1acbac6e1998121"
    }]
    
    resolver.test!
    resolver.failed.length.should be(0)
  end
  
  it 'should be silent if a digest isnt given' do
    resolver = WarningShot::IntegrityResolver.new
    that_file = File.join @@src_path, 'that.txt'
    #These values are flipped from FileResolverRspec so that we dont
    # have to resolve the file dependency to check the integrity
    resolver.init [{
      :local => "file://#{that_file}",
      :src => ""
    }]
    
    resolver.test!
    resolver.failed.length.should be(0)
  end
end