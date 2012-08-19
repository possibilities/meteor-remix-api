require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'active_support/all'

class BranchRemixer
  def initialize(branches)
    @branches = branches
    @home_dir = File.expand_path('~')
    @root_path = File.join(@home_dir, '.meteor-remix')
    @meteor_path = File.join(@root_path, 'meteor')
    @original_path = Dir.pwd
  end
  
  def bump_it!
    prepare
    Dir.chdir(@meteor_path)

    ensure_all_branches_exist_upstream
    branch_name = "remix.#{Time.now.utc.to_i}.#{@branches.join(',')}"
    `git checkout -b #{branch_name} master`

    @branches.each do |branch|
      `git merge upstream/#{branch} -m'merging #{branch}'`
      if $?.exitstatus == 1
        Dir.chdir(@original_path)
        message = "Could not merge #{branch} cleanly!"
        raise Exception.new(message)
      end
    end
    
    `git push origin #{branch_name}`
    `git checkout master`
    Dir.chdir(@original_path)
    
    branch_name
  end
  
  private
  
    def upstream_branches
      @upstream_branches ||= branches_for_origin('upstream')
    end
    
    def remix_branches
      @upstream_branches ||= begin
        origin_branches = branches_for_origin('origin')
        origin_branches.select { |name| name =~ /^remix\.\d{8}\.[\d]{4}\.([\w-_]+,?)+/ }
      end
    end
    
    def all_branches
      @all_branches ||= begin
        raw_branches = `git branch -r`
        clean_branches = raw_branches.split(/\n/).map { |name| name.strip }
      end
    end

    def branches_for_origin(origin)
      branches = all_branches.select { |name| name =~ /^#{origin}/ }
      branches.map {|name| name.gsub(/^#{origin}\//, '') }
    end

    def prepare
      unless File.exists?(@root_path)
        `mkdir -p #{@root_path}`
        Dir.chdir(@root_path)
        p `git clone https://github.com/meteor-remix/meteor`

        Dir.chdir(@meteor_path)
        p `git remote add upstream https://github.com/meteor/meteor`
      end
      
      Dir.chdir(@meteor_path)
      `git checkout master`
      `git fetch upstream`
      `git fetch origin`
    end
    
    def ensure_all_branches_exist_upstream
      overlap_branches = (upstream_branches & @branches)

      unless overlap_branches.size == @branches.size
        Dir.chdir(@original_path)
        message = "\"#{(@branches - overlap_branches).first}\" branch not found upstream!"
        raise Exception.new(message)
      end
    end
    
end

get '/' do
  content_type :json

  puts 
  puts 

  raw_branches = params[:branches]
  result = if raw_branches.blank?
    { error: 'You have to specify some branches to remix!' }
  else

    branches = raw_branches.split(',').sort()
    branch = BranchRemixer.new(branches).bump_it!
    
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
