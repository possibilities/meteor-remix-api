require 'daemons'

pwd = Dir.pwd

Daemons.run_proc('remix_api.rb', {:dir_mode => :normal, :dir => "/home/mike/deploy/remix" }) do
  Dir.chdir(pwd)
  exec "ruby remix_api.rb"
end
