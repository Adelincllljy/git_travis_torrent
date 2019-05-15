

require 'time'
require 'linguist'
require 'thread'
require 'rugged'
require 'json'
require 'open-uri'
require 'net/http'
require 'fileutils'
require 'time_difference'

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
  @out_queue = SizedQueue.new(2000)
  $token="8bbfaab218a72930d36ec952cfd6494ef5aa348b"
  $REQ_LIMIT = 4990
  def load_all_builds(rootdir,filename)
    f = File.join(rootdi, filename)
    unless File.exists? f
      puts "不能找到"
    end

    JSON.parse File.open(f).read, :symbolize_names => true#return symbols
  end
  def load_builds(owner, repo)
    f = File.join("build_logs", "#{owner}@#{@repo}", "repo-data-travis.json")
    unless File.exists? f
      puts "不能找到"
    end

    JSON.parse File.open(f).read, :symbolize_names => true#return symbols
  end


  def load_commit(owner, repo)
     f = File.join("build_logs", "#{owner}@#{@repo}", "commits_info.json")
    unless File.exists? f
      puts "不能找到"
    end

    JSON.parse File.open(f).read, :symbolize_names => true#return symbols
  end


  def is_pr?(build)
    build[:pull_req].nil? ? false : true
  end


  def write_file(contents,parent_dir,filename)
    json_file = File.join(parent_dir, filename)
    if contents.class == Array
      
        contents.flatten!
    # Remove empty entries
        contents.reject! { |c| c.empty? }
    end
    if File.exists? json_file
      #puts "all_commit:#{all_commits}"
      return
    
      
  # Remove empty entries
      
      puts "initial builds size #{contents.size}"
      if contents.empty?
        error_message = "Error could not get any repo information for #{parent_dir}."
        puts error_message    
        exit(1)
      end
    
      File.open(json_file, 'a') do |f|
      f.puts JSON.dump(contents)
      end
    
    else
      File.open(json_file, 'a') do |f|
      f.puts JSON.dump(contents)
      end
    end

      
  end

  def test(user,repo1)
    checkout_dir = File.join('repos', user, repo1)
    flag = File::exists?("README.md")
    puts "flag:#{flag}"
    begin
      repo = Rugged::Repository.new(checkout_dir)
      unless repo.bare?
        spawn("cd #{checkout_dir} && git pull")
      end
      repo
      puts repo.path
    rescue
      spawn("git clone git://github.com/#{user}/#{repo}.git #{checkout_dir}")
    end
      builds = load_builds(user, repo1)
      walker = Rugged::Walker.new(repo)
      walker.sorting(Rugged::SORT_DATE)
      walker.push(repo.head.target)
      puts "walker.class:#{walker.class}"
      all_commit = Hash.new
      all_commits = []
      walker.map do |commit|
     
        begin
           all_commit={
             :sha => commit.oid,
             :message => commit.message,
             :commit_parents => commit.parent_ids,
             :committer => commit.author
           }
          # all_commit[:sha]=commit.oid
          # all_commit[:message]=commit.message
          # all_commit[:commit_parents]=commit.parent_ids
          # all_commit[:committer]=commit.author
          # @out_queue.enq all_commit
        rescue
          puts "no commit info"
        end
        all_commits << all_commit
      end
      @parent_dir = File.join('build_logs/',  "#{user}@#{repo1}")
      json_file = File.join(@parent_dir, 'commits_info.json')
      #puts "all_commit:#{all_commits}"
      all_commits.flatten!
  # Remove empty entries
      all_commits.reject! { |c| c.empty? }
  # Remove duplicates
      all_commits = all_commits.group_by { |x| x[:sha] }.map { |k, v| v[0] }
      puts "initial builds size #{builds.size}"
      if all_commits.empty?
        error_message = "Error could not get any repo information for #{repo}."
        puts error_message    
        exit(1)
      end

      File.open(json_file, 'w') do |f|
      f.puts JSON.dump(all_commits)
      end
      #读取所有commit信息
      all_commit=load_commit(user,repo1)
      puts builds.class
      acc=Array.new
      fixre = /(?:fixe[sd]?|close[sd]?|resolve[sd]?)(?:[^\/]*?|and)#([0-9]+)/mi

      puts  'Calculating PRs closed by commits'
    
      closed_by_commit =
          all_commit.map do |x|
              sha = x[:sha]
              result = {}
           
              comment = x[:message]

              comment.match(fixre) do |m|
                temparr=m[0][0..10]
                temparr=temparr.split(" ")
                (1..(m.size - 1)).map do |y|
                  result[m[y].to_i] = sha+"#"+temparr[0]#close/fixed/resolved  {issue_id,pr_id=>"sha"}
                end
              end
              if !result.empty?
                name=result[result.keys[0]].split("#")[1]
                x[:close_fixed_resolved ]= (result.keys[0]).to_s+"#"+name
                #puts x
              end
              result
          end.select { |m| !m.empty? }.reduce({}) { |x, m| x.merge(m) }
      puts "#{closed_by_commit.size} PRs closed by commits"

      puts "Retrieving commits that were actually built (for pull requests)"
      builds.map  do |build|
        if is_pr?(build)
          c = github_commit(user, repo1, build[:commit])
          unless c.empty?
            shas = c['commit']['message'].match(/Merge (.*) into (.*)/i).captures
            if shas.size == 2
              puts "Replacing Travis commit #{build[:commit]} with actual #{shas[0]}"

              build[:commit] = shas[0]
              build[:tr_virtual_merged_into] = shas[1]

            end
            build
            write_file(build,@parent_dir,"repo-data-virtual-travis.json")
          else
            nil
          end
        else
          build
        end
    end.select { |x| !x.nil? }
    write_file(builds,@parent_dir,"all_repo-data-virtual-builds.json")
    builds = load_all_builds(@parent_dir, "all_repo-data-virtual-builds.json")
    puts "initial builds size #{builds.size}"
    puts builds.class
    
    build_stats=[]
    i=0
    builds.each do |build|
       
       # puts "build的class#{build.class}"
        pre_commit=[]
        build_stat={
          build[:commit].to_sym => find_commits_to_prior(builds,build,build[:commit],pre_commit,0)
        }
         
       
        build_stats << build_stat
       
    end
    #puts build_stats
    write_file(build_stats,@parent_dir,"prior_commit_to_last_build.json")
   


    
  end

  
 #get prior commits to last build
 '''
 只找到本地的数据，会有本地找不到的commit情况，暂时没有考虑
 '''
def find_commits_to_prior(builds,build,sha,prev_commits,flag)

    
       puts"==================================="
       begin
        repo = Rugged::Repository.new("git_travis_torrent/repos/#{@user}/#{@repo}")
        
        build_commit = repo.lookup(sha)
        #puts "build_commit#{build_commit}  #{build_commit.oid} "
       rescue
        puts "cannot find!"
        return
       end
      if build_commit.nil?
        return 
      end
      walker = Rugged::Walker.new(repo)
      walker.sorting(Rugged::SORT_TOPO)
      walker.push(build_commit)
     
   
      commit_resolution_status = :no_previous_build
      last_commit = nil
      i=0
      walker.each do |commit|
        i=i+1
        last_commit = commit
        if i==1
            prev_commits << commit
            
        end
        
        puts "last_commt#{i}#{[last_commit]}"
        puts "last_commit.oid:#{last_commit.oid}"
        puts "commit_oid#{commit.oid}"
        
        if commit.oid == build_commit.oid#build_commit本身是一个merge
          if commit.parents.size > 1
            commit_resolution_status = :merge_found
            puts "build_commit本身是一个merge"
            if flag==0#如果是第一层build，就要继续找下去
              acc=[]
              j=0
              commit.parent_ids.each do |shas|
               
                
                while prev_commits.last.oid!=build_commit.oid
                prev_commits.pop
                end
                acc << find_commits_to_prior(builds,build,shas,prev_commits,1)
              end
              return acc
            
            elsif flag==1#如果是已经找到父commit了，父亲是一个build_commit且有两个parents  flag=1
              if not builds.select { |b| b[:commit] == commit.oid }.empty?#不为空
                commit_resolution_status = :build_found#找到上一次的build_commit
            
            
                puts"在第二层找到上一次build_commit"
                
                prev_commits.uniq
                puts "prev_commits1 #{prev_commits}"
                break
              
              else#这个merge不是build
               acc=[]
               j=0
                commit.parent_ids.each do |shas|
                 
                  prev_copy_commit=[build_commit]
                  while prev_commits.last.oid!=build_commit.oid
                    prev_commits.pop
                  end
                  puts "22这里的 pre_commits #{prev_commits}"
                  acc << find_commits_to_prior(builds,build,shas,prev_commits,1)
                end
                return acc
              end

            end
          



          else
            puts "当前commit 只有一个parent"
            if flag==1 
                if not builds.select { |b| b[:commit] == commit.oid }.empty?#不为空
                    commit_resolution_status = :build_found#找到上一次的build_commit
                
                
                    puts"在第二层找到上一次build_commit"
                    
                    prev_commits.uniq
                    puts "prev_commits1 #{prev_commits}"
                    break
                
                else
                next
                end 
            else
                next
            end
          end
          
        end

        if not builds.select { |b| b[:commit] == commit.oid }.empty?#不为空
          commit_resolution_status = :build_found#找到上一次的build_commit
          
          
          puts"找到上一次build_commit"
          prev_commits << commit
          prev_commits.uniq
          puts "prev_commits2 #{prev_commits}"
          break
       
        end

        prev_commits << commit

        if commit.parents.size > 1#这个commit不是built_commit，但是有两个parents
          commit_resolution_status = :merge_found
          puts "这个commit不是built_commit，但是有两个parents"
          acc=[]
          
          commit.parent_ids.each do |shas|
               prev_copy_commit=[build_commit]
                  while prev_commits.last.oid!=build_commit.oid
                    prev_commits.pop
                  end
            
           acc << find_commits_to_prior(builds,build,shas,prev_commits,1) 
          end
          return acc    
          
        end

      end

      puts "#{prev_commits.size} built commits (#{commit_resolution_status}) for build #{sha}"
    
    build_stats=
      {
          :build_id => build[:build_id],
          #:commit_sha => build[:commit],
          :prev_build => if not commit_resolution_status == :merge_found
                           builds.find { |b| b[:build_id] < build[:build_id] and last_commit.oid.start_with? b[:commit] }
                         else
                           nil
                         end,
          :commits => prev_commits.map { |c| c.oid },#从当前buildcommit到上一次build_commit之前，包括上一次build_commit
          :authors => prev_commits.map { |c| c.author[:email] }.uniq,
          :prev_built_commit => commit_resolution_status == :merge_found ? nil : (last_commit.nil? ? nil : last_commit.oid),
          :prev_commit_resolution_status => commit_resolution_status
      }
      
    return build_stats
end 

#抽commit详细信息，包括travis上的虚拟commit sha 
  def github_commit(owner, repo, sha)
    parent_dir = File.join('commits', "#{owner}@#{repo}")
    commit_json = File.join(parent_dir, "#{sha}.json")
    FileUtils::mkdir_p(parent_dir)

    r = nil
    if File.exists? commit_json
      r = begin
        JSON.parse File.open(commit_json).read
      rescue
        # This means that the retrieval operation resulted in no commit being retrieved
        {}
      end
      return r
    end

    url = "https://api.github.com/repos/#{owner}/#{repo}/commits/#{sha}"
    puts "Requesting #{url} (#{@remaining} remaining)"

    contents = nil
    begin
      r = open(url, 'User-Agent' => 'ghtorrent', 'Authorization' => "token #{$token}")
      @remaining = r.meta['x-ratelimit-remaining'].to_i
      @reset = r.meta['x-ratelimit-reset'].to_i
      contents = r.read
      JSON.parse contents
    rescue OpenURI::HTTPError => e
      @remaining = e.io.meta['x-ratelimit-remaining'].to_i
      @reset = e.io.meta['x-ratelimit-reset'].to_i
      puts  "Cannot get #{url}. Error #{e.io.status[0].to_i}"
      {}
    rescue StandardError => e
      log "Cannot get #{url}. General error: #{e.message}"
      {}
    ensure
      File.open(commit_json, 'w') do |f|
        f.write contents unless r.nil?
        f.write '' if r.nil?
      puts "获取成功"
      
      end

      if 5000 - @remaining >= $REQ_LIMIT
        to_sleep = @reset - Time.now.to_i + 2
        puts "Request limit reached, sleeping for #{to_sleep} secs"
        sleep(to_sleep)
      end
    end
  end
   
      
    #   builds = builds.reduce([]) do |acc, build|
    #     unless build[:pull_req].nil?
    #         puts "为空"
    #         puts build.class
    #         acc << build#pr为空
    #         puts acc
    #     else
        
    #         r = build[:pull_req]
    #         unless r.nil?
            
    #             acc << build
    #         else
    #         # Not yet processed by GHTorrent, don't process further
    #             acc
    #         end
    #     end
    #   end
    # puts "after: #{builds.size}"
 


    #    build_stats = builds.map do |build|  
    #    puts"==================================="
    #    begin
    #     repo = Rugged::Repository.new(checkout_dir)
    #     build_commit = repo.lookup(build[:commit])
    #     puts "build_commit#{build_commit}  #{build_commit.oid} "
    #   rescue
    #     next
    #   end
    #   next if build_commit.nil?

    #   walker = Rugged::Walker.new(repo)
    #   walker.sorting(Rugged::SORT_TOPO)
    #   walker.push(build_commit)
    #   prev_commits = [build_commit]
    #   puts"build_commit.class: #{build_commit.class}"
    #   puts "pre_commit.size#{prev_commits.size}"
    #   puts "build_commit.oid: #{build_commit.oid}"
    #   puts "prev_commits/[build_commit]#{prev_commits}"
    #  # puts "pre_commits3#{prev_commits}"
    #   commit_resolution_status = :no_previous_build
    #   last_commit = nil
    #   i=0
    #   walker.each do |commit|
    #     last_commit = commit
          
    #     puts "last_commt#{i}#{[last_commit]}"
    #     i+=1
    #     if commit.oid == build_commit.oid
    #       if commit.parents.size > 1
    #         commit_resolution_status = :merge_found
    #         break
    #       end
    #       next
    #     end

    #     if not builds.select { |b| b[:commit] == commit.oid }.empty?#不为空
    #       commit_resolution_status = :build_found#找到上一次的build_commit
    #       puts commit.class
    #       puts "commit.oid#{commit.oid}"
    #       puts commit.message
    #       puts "last_commit.oid #{last_commit.oid}"
    #       puts "last_commit.oid.start_with #{commit.tools}"
    #       puts"找到上一次build_commit"
    #       break
    #     end

    #     prev_commits << commit

    #     if commit.parents.size > 1
    #       commit_resolution_status = :merge_found
    #       break
    #     end

    #   end

    #   puts "#{prev_commits.size} built commits (#{commit_resolution_status}) for build #{build[:build_id]}"

    #   {
    #       :build_id => build[:build_id],
    #       :prev_build => if not commit_resolution_status == :merge_found
    #                        builds.find { |b| b[:build_id] < build[:build_id] and last_commit.oid.start_with? b[:commit] }
    #                      else
    #                        nil
    #                      end,
    #       :commits => prev_commits.map { |c| c.oid },
    #       :authors => prev_commits.map { |c| c.author[:email] }.uniq,
    #       :prev_built_commit => commit_resolution_status == :merge_found ? nil : (last_commit.nil? ? nil : last_commit.oid),
    #       :prev_commit_resolution_status => commit_resolution_status
    #   }
    # end.select { |x| !x.nil? }
    
    




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
@repo = ARGV[1]
repo = ARGV[1]
# arry=["eb37fce20c89a3bd14be623ef03bb242118159b0",
# "b8e9edd09d9008e6f65f5751dd7ad6ecc0004eb4",
# "46d759b3836e2e78bae251e6ff7d727d88d53554",
# "cb65d46a8e2618a086020db188b6f1eb60f355ad",
# ca0cefbf423573c78395ea9bc8914a13dad2bf47
# 2155f74c5b2a9f877fe84d2a7716282569bb8487
# 9efb11d7bf6952a00473d16ab63fe18c10d0e57a
# 8444c6312eea167bf2ec642db1f2cb6dc8cc73b2
# 8eee968957079d707214beb460b77e67ce9ac53c
# 61b01c1de2c32db125907a72d79a68ce7e88abea
# 2038d32ea0e4dc819f7b085535facfc9e2160bca
# dd2670e66be0e164ccf4521a501c113981c1e201
# 4cfa50c6b30a6aec49ad1c3d824c5e9576a54303
# b19a5db803f737eeb3a174e77e82ed76d9f6e056
# 58abe578f5c25f158e4f5ad2612db15daf7e84dc
# c8263b4d9491ca52b12934f4503dae68d756ed0d
# 1ccad68897a760d735285530c988e7e37414b41c"]
github_commit(owner,repo,"58abe578f5c25f158e4f5ad2612db15daf7e84dc")
#test("#{owner}","#{repo}")
