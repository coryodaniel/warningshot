begin
  (require("rubygems")
  require("net/ssh")
  require("net/scp")
  require("highline"))
  require 'pp'
rescue LoadError
  warn "There was a problem loading net-ssh, net-scp, or highline. You will not be able to use an ssh-resolver until those gems are installed."
end

class WarningShot::SshResolver
  include WarningShot::Resolver
  order  100
  # disable! 

  branch :ssh
  description 'Validates ability to login to a remote server'

  # Define ServerResource struct
  ServerResource = Struct.new(:hostname, :username, :ssh_options)
       
  typecast Hash do |server|
    ServerResource.new server[:hostname], server[:username], (server[:ssh_options] || {})
  end
  
  register :test, {:name => :ssh_check} do |server|
    begin
      server.ssh_options[:keys]     ||= self.discovered_keys
      server.ssh_options[:password] ||= "purposefully_fail_98niu98uj98nhn" # hack to avoid getting a 'Password: ' prompt on fail
      Net::SSH.start(server.hostname, server.username, server.ssh_options) do |ssh|
        ssh.exec!("echo hi")
      end
      true
    rescue Net::SSH::AuthenticationFailed
      false
    end
  end
  
  register :resolution, {:name => :install_ssh_public_key } do |server|
    # based on ben schwartz sake task to do the same
    h = HighLine.new
    not_blank = Proc.new { |s| (not s.empty?) }
    def not_blank.to_s; "not blank"; end

    h.say("I need some information to install your public SSH key onto #{server.hostname}.")
    password = h.ask("Password for #{server.username}@#{server.hostname}: ") { |q| q.echo = "*" }
    public_key_path = self.discovered_keys.first + ".pub" # todo, have an option to specify this
    begin
      Net::SSH.start(server.hostname, server.username, :password => password) do |ssh|
        puts("Uploading your public key into a tmp file... ")
        ssh.scp.upload!(public_key_path, "my_public_key")
        puts("Creating '.ssh' directory in your home directory")
        ssh.exec!("mkdir .ssh")
        puts("Concatenating your public key into the authorized_keys2 file")
        ssh.exec!("cat my_public_key >> .ssh/authorized_keys2")
        puts("Removing your public key tmp file")
        ssh.exec!("rm my_public_key")
        puts("Setting permissions on .ssh")
        ssh.exec!("chmod 700 .ssh")
        puts("Setting permissions on your authorized_keys2 file")
        ssh.exec!("chmod 600 .ssh/authorized_keys2")
        puts("\nAll done!  Enjoy your new, potentially password-free login.")
      end
      true
    rescue Net::SSH::AuthenticationFailed
      puts("\nThere was a problem authenticating you for #{server.username}@#{server.hostname}.")
      try_again = h.ask("Do you want to try again? [Y/n]: ") { |q| q.default = "y" }
      if try_again =~ /^y/i
        password = h.ask("Password for #{server.username}@#{server.hostname}: ") { |q| q.echo = "*" }
        retry
      else
        false
      end
    end
  end

  private 

    def self.discovered_keys
      discovered_keys = (["id_rsa", "id_dsa", "identity"].collect do |f|
           file = "#{ENV["HOME"]}/.ssh/#{f}"
           File.exists?(file) ?  file : nil
      end).compact
    end
end
