require 'rubygems'
require 'daemons'

pwd = Dir.pwd

Daemons.run_proc('remix_api.rb', {:dir_mode => :normal, :dir => "/home/mike/deploy/remix", :log_output => true }) do
  Dir.chdir(pwd)
  exec "ruby /home/mike/deploy/remix/remix_api.rb"
end
