require "." / "lib" / "resolvers" / "ssh_resolver"

describe WarningShot::SshResolver do

  it 'should have tests registered' do
    WarningShot::SshResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions registered' do
    WarningShot::SshResolver.resolutions.empty?.should be(false)
  end
     
  describe 'with healing enabled' do
    describe 'with heal instructions' do
      it 'should install the public key on the local user' do
        pending "rm your own pubkey from ~/.ssh/authorized_keys2 to run"
        fd = WarningShot::SshResolver.new(WarningShot::Config.create,:ssh,{:hostname => 'localhost', :username => ENV['USER']})
        fd.test!
        fd.failed.length.should be(1)
        fd.resolve!
        fd.resolved.length.should be(1)

        fd = WarningShot::SshResolver.new(WarningShot::Config.create,:ssh,{:hostname => 'localhost', :username => ENV['USER']})
        fd.test!
        fd.failed.length.should be(0)
      end
    end # End healing enabled, instructions provided
    
    describe 'without heal instructions' do

      it 'should fail if you have a bogus username' do
        fd = WarningShot::SshResolver.new(WarningShot::Config.create,:ssh,{:hostname => 'localhost', :username => "128nisd89hg"})
        fd.test!
        fd.failed.length.should be(1)
      end

    end # End healing enabled, instructions not provided
  end # End healing enabled
  
end
