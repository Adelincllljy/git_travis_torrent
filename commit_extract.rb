

require 'time'
require 'linguist'
require 'thread'
require 'rugged'
require 'json'
# def clone(user, repo, update = false)

    # def spawn(cmd)
    #   proc = IO.popen(cmd, 'r')

    #   proc_out = Thread.new {
    #     while !proc.eof
    #       puts "GIT: #{proc.gets}"
    #     end
    #   }

    #   proc_out.join
    # end
  def load_builds(owner, repo)
    f = File.join("travistorrent-tools/build_logs", "#{owner}@#{repo}", "repo-data-travis.json")
    unless File.exists? f
      puts "不能找到"
    end

    JSON.parse File.open(f).read, :symbolize_names => true#return symbols
  end
  def test(user,repo)
      checkout_dir = File.join('repos', user, repo)

    # begin
    #   repo = Rugged::Repository.new(checkout_dir)
    #   if update
    #     spawn("cd #{checkout_dir} && git pull")
    #   end
    #   repo
    #   puts repo.path
    # rescue
    #   spawn("git clone git://github.com/#{user}/#{repo}.git #{checkout_dir}")
      builds = load_builds(user, repo)
      puts "initial builds size #{builds.size}"
      puts builds.class
      acc=Array.new
      builds = builds.reduce([]) do |acc, build|
        unless build[:pull_req].nil?
            puts "不为空"
            puts build.class
            acc << build#pr为空
            puts acc
        else
        
            r = build[:pull_req]
            unless r.nil?
            
                acc << build
            else
            # Not yet processed by GHTorrent, don't process further
                acc
            end
        end
      end
    puts "after: #{builds.size}"
 


       build_stats = builds.map do |build|  
       puts"==================================="
       begin
        repo = Rugged::Repository.new(checkout_dir)
        build_commit = repo.lookup(build[:commit])
        puts "build_commit#{build_commit}  #{build_commit.oid} "
      rescue
        next
      end
      next if build_commit.nil?

      walker = Rugged::Walker.new(repo)
      walker.sorting(Rugged::SORT_TOPO)
      walker.push(build_commit)
      prev_commits = [build_commit]
      puts"build_commit.class: #{build_commit.class}"
      puts "pre_commit.size#{prev_commits.size}"
      puts "build_commit.oid: #{build_commit.oid}"
      puts "prev_commits/[build_commit]#{prev_commits}"
     # puts "pre_commits3#{prev_commits}"
      commit_resolution_status = :no_previous_build
      last_commit = nil
      i=0
      walker.each do |commit|
        last_commit = commit
          
        puts "last_commt#{i}#{[last_commit]}"
        i+=1
        if commit.oid == build_commit.oid
          if commit.parents.size > 1
            commit_resolution_status = :merge_found
            break
          end
          next
        end

        if not builds.select { |b| b[:commit] == commit.oid }.empty?#不为空
          commit_resolution_status = :build_found#找到上一次的build_commit
          puts commit.class
          puts "commit.oid#{commit.oid}"
          puts commit.message
          puts "last_commit.oid #{last_commit.oid}"
          puts "last_commit.oid.start_with #{commit.tools}"
          puts"找到上一次build_commit"
          break
        end

        prev_commits << commit

        if commit.parents.size > 1
          commit_resolution_status = :merge_found
          break
        end

      end

      puts "#{prev_commits.size} built commits (#{commit_resolution_status}) for build #{build[:build_id]}"

      {
          :build_id => build[:build_id],
          :prev_build => if not commit_resolution_status == :merge_found
                           builds.find { |b| b[:build_id] < build[:build_id] and last_commit.oid.start_with? b[:commit] }
                         else
                           nil
                         end,
          :commits => prev_commits.map { |c| c.oid },
          :authors => prev_commits.map { |c| c.author[:email] }.uniq,
          :prev_built_commit => commit_resolution_status == :merge_found ? nil : (last_commit.nil? ? nil : last_commit.oid),
          :prev_commit_resolution_status => commit_resolution_status
      }
    end.select { |x| !x.nil? }
    
    
end




    # Filter out builds without build statistics
    # self.builds = builds.select do |b|
    #   not build_stats.find do |bd|
    #     bd[:build_id] == b[:build_id]
    #   end.nil?
    # end
    # log "After calculating build stats: #{builds.size} builds for #{owner}/#{repo}"
  
        # repo = Rugged::Repository.new(checkout_dir)
        # repo.lookup("48591b2abb01fa4a93f74c5b9d1626a7296571c3")
        # repo2=Rugged::Walker.new(repo)
        # repo2.sorting(Rugged::SORT_DATE)
        # puts repo.head.target
        # repo2.push(repo.head.target)
        # i=0
        # all_commits = repo2.map do |commit|
           
        #     while i<=2
        #         puts "commit#{commit}"
        #         #commit.oid[0..10]
        #         puts commit.oid
        #         i+=1
        # end
 
owner = ARGV[0]
repo = ARGV[1]

test("#{owner}","#{repo}")
