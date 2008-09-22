=begin
# All example script files still need to be written, after ScriptResolver is re-written
# General idea is:
  load 'pre.rb' if File.exists? 'pre.rb'
  
  find each file that doesn't start with pre_|post_
    run pre_THAT_FILE if it exists
    run THAT_FILE
    run post_THAT_FILE if it exists
  
  load 'post.rb' if File.exists? 'post.rb'

=end