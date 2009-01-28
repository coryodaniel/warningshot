#See TODO's below... (maybe the best bet it to take command line flags for User/Group names?)

# Auto-generated ruby debug require
require 'rubygems'
require "ruby-debug"
Debugger.start
Debugger.settings[:autoeval] = true if Debugger.respond_to?(:settings)

require '.' / 'lib' / 'resolvers' / 'permission_resolver'

describe WarningShot::PermissionResolver do
  before :all do
    #You can add additional groups to try here...
    @group_names = ['everyone']

    # Test if user can chown/chmod files to found group... if not nil out names...
    @grp_chmod_test = File.expand_path($test_data / "group_w_test.txt")
    FileUtils.touch @grp_chmod_test

    # Set the @test_group_* for the first group found
    Etc.group {|grp|
      if @group_names.member?(grp.name)
        begin
          if @test_group_name.nil? && @test_group_id.nil?
            @test_group_name  = grp.name
            @test_group_id    = grp.gid
            File.chown(nil,@test_group_id,@grp_chmod_test)
          end
        rescue Exception => ex
          #Could chown group, keep looking...
          @test_group_name = nil
          @test_group_id   = nil
        end
      end
    }

    #Remove the chmod/chown test file
    FileUtils.rm @grp_chmod_test

    #Test file for changing permissions
    @perm_test_file = File.expand_path($test_data / "permission_test_#{Time.now.to_i}.txt")
    File.open(@perm_test_file,"w+") do |fs|
      fs.puts "This file is used for testing the PermissionResolver"
    end

    #Test directory for recursive permissions
    @perm_test_directory = File.expand_path($test_data / "permission_test_dir_#{Time.now.to_i}")
    @perm_test_directory_subdirectory = File.expand_path(@perm_test_directory / "subdirectory")
    FileUtils.mkdir_p @perm_test_directory_subdirectory

    #Test link target for testing nofollow
    @perm_test_link_tgt = File.expand_path($test_data / "permission_test_link_tgt_#{Time.now.to_i}")
    FileUtils.ln_s @perm_test_file, @perm_test_link_tgt

    #Use the create file above to get the current processes User/Group info
    @orig_user_uid = File.stat(@perm_test_file).uid
    @orig_user_name = Etc.getpwuid(@orig_user_uid).name

    @orig_group_gid = File.stat(@perm_test_file).gid
    @orig_group_name = Etc.getgrgid(@orig_group_gid).name

    @orig_mode  = File.stat(@perm_test_file).mode

    WarningShot::PermissionResolver.logger = $logger
  end

  after :all do
    FileUtils.rm @perm_test_file
    FileUtils.rm_rf @perm_test_directory
    FileUtils.rm @perm_test_link_tgt
  end

  it 'should have tests registered' do
    WarningShot::PermissionResolver.tests.empty?.should be(false)
  end

  it 'should have resolutions registered' do
    WarningShot::PermissionResolver.resolutions.empty?.should be(false)
  end

  describe WarningShot::PermissionResolver::PermissionResource do
    it 'should be able to determine if its user permission is correct' do

      #Verify valid user by ID
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,nil,@orig_user_uid,nil,nil)
      pr.valid_user?.should be(true)

      #Verify valid user by name
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,nil,@orig_user_name,nil,nil)
      pr.valid_user?.should be(true)

      #Get a user that isn't the user that currently owns the file
      test_user = Etc.passwd
      if test_user.uid == @orig_user_uid
        test_user = Etc.passwd
      end

      #Invalid user by ID
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,nil,test_user.uid,nil,nil)
      pr.valid_user?.should be(false)

      #Invalid user by name
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,nil,test_user.name,nil,nil)
      pr.valid_user?.should be(false)
    end

    it 'should consider the user permission to be correct if not provided' do
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,nil,nil,nil,nil)
      pr.valid_user?.should be(true)
    end

    it 'should consider the user permission to be incorrect if the user does not exist' do
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,nil,"randouser-#{Time.now.to_i}",nil,nil)
      pr.valid_user?.should be(false)
    end

    it 'should be able to determine if its group permission is correct' do

      #Verify valid group by ID
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,nil,nil,@orig_group_gid,nil)
      pr.valid_group?.should be(true)

      #Verify valid group by name
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,nil,nil,@orig_group_name,nil)
      pr.valid_group?.should be(true)

      #Get a group that isn't the group that currently owns the file
      test_group = Etc.group
      if test_group.gid == @orig_group_gid
        test_group = Etc.group
      end

      #Invalid group by ID
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,nil,nil,test_group.gid,nil)
      pr.valid_group?.should be(false)

      #Invalid group by name
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,nil,nil,test_group.name,nil)
      pr.valid_group?.should be(false)
    end

    it 'should consider the group permission to be correct if not provided' do
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,nil,nil,nil,nil)
      pr.valid_group?.should be(true)
    end

    it 'should consider the group permission to be incorrect if the group does not exist' do
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,nil,nil,"randogroup-#{Time.now.to_i}",nil)
      pr.valid_group?.should be(false)
    end

    it 'should be able to determine if its mode is correct' do
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,'777',nil,nil,nil)
      pr.valid_mode?.should be(false)

      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,'644',nil,nil,nil)
      pr.valid_mode?.should be(true)

      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,'644',nil,nil,nil)
      pr.valid_mode?.should be(true)
    end

    it 'should consider the mode to be correct if the mode is not provided' do
      pr = WarningShot::PermissionResolver::PermissionResource.new(@perm_test_file,nil,nil,nil,nil)
      pr.valid_mode?.should be(true)
    end
  end

  describe 'with healing enabled and with healing instructions' do
    it 'should consider a dependency met if passed a string and the target exists' do
      pr = WarningShot::PermissionResolver.new(WarningShot::Config.create, :file, @perm_test_file)
      pr.test!
      pr.passed.first.met.should be(true)
    end

    it 'should be able to correct the user by name' do
      # TODO How do you test this w/o SUDO, or without knowing the names of users/groups on test machine
      pending
    end
    it 'should be able to correct the user by id' do
       # TODO How do you test this w/o SUDO, or without knowing the names of users/groups on test machine
      pending
    end

    it 'should be able to correct the group by id' do
      # Mark the spec as pending if it couldnt find a group to run this as
      if @test_group_id
        perm_file = {
          :target => @perm_test_file,
          :group  => @test_group_id
        }

        pr = WarningShot::PermissionResolver.new(WarningShot::Config.create, :file, perm_file)

        pr.test!
        pr.failed.length.should be(1)
        pr.resolve!
        pr.resolved.length.should be(1)

        (File.stat(@perm_test_file).gid).should == @test_group_id

        #give it back to original group
        File.chown(nil,@orig_group_gid,@perm_test_file)
      else
        # TODO How do you test this w/o SUDO, or without knowing the names of users/groups on test machine
        pending
      end
    end

    it 'should be able to correct the group by name' do
      # Mark the spec as pending if it couldnt find a group to run this as
      if @test_group_name
        perm_file = {
          :target => @perm_test_file,
          :group  => @test_group_name
        }

        pr = WarningShot::PermissionResolver.new(WarningShot::Config.create, :file, perm_file)

        pr.test!
        pr.failed.length.should be(1)

        pr.resolve!
        pr.resolved.length.should be(1)

        Etc.getgrgid(File.stat(@perm_test_file).gid).name.should == @test_group_name

        #Give it back to the original group
        File.chown(nil,@orig_group_id,@perm_test_file)
      else
        # TODO How do you test this w/o SUDO, or without knowing the names of users/groups on test machine
        pending
      end
    end

    it 'should be able to correct the mode' do
      perm_file = {
        :target => @perm_test_file,
        :mode => '777'
      }
      pr = WarningShot::PermissionResolver.new(WarningShot::Config.create, :file, perm_file)

      pr.test!
      pr.failed.length.should be(1)
      pr.resolve!
      pr.resolved.length.should be(1)

      ("%o" % (File.stat(@perm_test_file).mode & 007777)).to_i.should be(777)

      #set the mode back
      File.chmod(@orig_mode,@perm_test_file)
    end

    it 'should be able to correct permissions recursively for directories' do
      perm_file = {
        :target => @perm_test_directory,
        :mode => '777',
        :recursive => 'chmod'
      }
      pr = WarningShot::PermissionResolver.new(WarningShot::Config.create, :file, perm_file)

      pr.test!
      pr.failed.length.should be(1)
      pr.resolve!
      pr.resolved.length.should be(1)

      ("%o" % (File.stat(@perm_test_directory).mode & 007777)).to_i.should be(777)
      ("%o" % (File.stat(@perm_test_directory_subdirectory).mode & 007777)).to_i.should be(777)
    end

    it 'should be able to correct permissions on links and not targets (no follow)' do
      perm_file = {
        :target => @perm_test_link_tgt,
        :mode => '777',
        :no_follow => 'chmod'
      }
      pr = WarningShot::PermissionResolver.new(WarningShot::Config.create, :file, perm_file)

      pr.test!
      pr.failed.length.should be(1)
      pr.resolve!
      pr.resolved.length.should be(1)

      File.stat(@perm_test_file).mode.should == @orig_mode
      ("%o" % (File.lstat(@perm_test_link_tgt).mode & 007777)).to_i.should be(777)
    end
  end
end