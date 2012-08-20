require 'active_support/all'

class BranchRemixer
  def initialize(branches)
    @branches = branches
    @home_dir = File.expand_path('~')
    @root_path = File.join(@home_dir, '.meteor-remix')
    @meteor_path = File.join(@root_path, 'meteor')
    @original_path = Dir.pwd
  end
  
  def remix!
    prepare
    update

    Dir.chdir(@meteor_path)

    ensure_all_branches_exist_upstream
    branch_name = "remix-#{@branches.join(',')}"

    `git checkout #{branch_name} master`
    if $?.exitstatus == 1
      `git checkout -b #{branch_name} master`
    end

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
        origin_branches.select { |name| name =~ /^remix\.\d{8}\.[\d]{4}\.([\w_-]+,?)+/ }
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
      unless File.exists?(@meteor_path)
        `mkdir -p #{@root_path}`
        
        Dir.chdir(@root_path)
        `git clone git@github.com:meteor-remix/meteor.git`

        Dir.chdir(@meteor_path)
        `git remote add upstream https://github.com/meteor/meteor`
      end
    end

    def update
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
