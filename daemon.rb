require 'daemons'

pwd = Dir.pwd

Daemons.run_proc('phone_sinatra.rb', {:dir_mode => :normal, :dir => "/home/mike/deploy/remix" }) do
  Dir.chdir(pwd)
  exec "ruby remix_api.rb"
end
