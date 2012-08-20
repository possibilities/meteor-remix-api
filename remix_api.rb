require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'active_support/all'
require_relative 'branch_remixer'

post '/' do
  content_type :json

  raw_branches = params[:branches]
  result = if raw_branches.blank?
    { error: 'You have to specify some branches to remix!' }
  else

    branches = raw_branches.split(',').sort()
    branch = BranchRemixer.new(branches).remix!
    
    {
      success: 'Your branches have been remixed!',
      git: {
        url: 'https://github.com/meteor-remix/meteor',
        branch: branch
      }
    }
  end

  result.to_json
end

not_found do
  'eff off, ok?'
end
