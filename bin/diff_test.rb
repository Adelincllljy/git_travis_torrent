require 'time'
require 'linguist'
require 'thread'
require 'rugged'
require 'json'
require 'fileutils'
require 'open-uri'
require 'net/http'
require 'activerecord-import'
require_relative 'java'
#require File.expand_path('../small_test.rb',__FILE__)
require File.expand_path('../../lib/all_repo_data_virtual_prior_merge.rb',__FILE__)
require File.expand_path('../../lib/filemodif_info.rb',__FILE__)
require File.expand_path('../../lib/file_path.rb',__FILE__)
require File.expand_path('../parse_html.rb',__FILE__)
require File.expand_path('../../fix_sql.rb',__FILE__)
@user=ARGV[0]
@repo=ARGV[1]
@out_queue = SizedQueue.new(2000)
$token="bfa572bff859671c0a0605a67d5785e2c8e0be27"
$REQ_LIMIT = 4990
$text_file=["md","doc","docx","txt","csv","json","doc"]
class Diff_test
  include JavaData
  def self.test_download(user,repo)
    builds = load_builds(user, repo,"all_repo_virtual_prior_mergeinfo.json")
    for build in builds
      c=git_compare(build[:now_build_commit],build[:last_build_commit],user,repo)
    end
  end
  def self.test_diff(user,repo)
    #small_test=Small_test.new
    
    builds = load_builds(user, repo,"all_repo_virtual_prior_mergeinfo_father_id.json")
    
    #builds=[{"now_build_commit":"0db6529e47db0d0e5e695d44ea5af26ce836efa7","commit_list":["0db6529e47db0d0e5e695d44ea5af26ce836efa7","80b78c8ba68e32963e1684787a10b7f78c91e81a"],"last_build_commit":"80b78c8ba68e32963e1684787a10b7f78c91e81a","authors":["hugo.van.rijswijk@hva.nl","cpovirk@google.com"],"num_author":2,"id":2278,"repo_name":"google@guava","build_id":"84682282","commit":"0db6529e47db0d0e5e695d44ea5af26ce836efa7","pull_req":2183,"branch":"master","status":"passed","message":"Set release version numbers to 19.0-rc2","duration":3501,"started_at":"2015-10-10T16:57:30Z","jobs":[84682283,84682284,84682285],"event_type":"pull_request","author_email":"cgdecker@google.com","committer_email":"cgdecker@google.com","tr_virtual_merged_into":"80b78c8ba68e32963e1684787a10b7f78c91e81a","merge_commit":"07326071e771c9244123791f00b848cc4f44fd9f","father_id":1}]
    arry=[]

    builds=builds.uniq
    repos = Rugged::Repository.new("repos/#{user}/#{repo}")
    #repo = Rugged::Repository.new("git_travis_torrent/repos/threerings/tripleplay")
    #builds.map do|build|
    
      
    filepath={}
    build_compare=[]
    
    for build in builds
      
      #commits_tree=repo.lookup("666f593b94f504316eca4813cbfe42f615cad633").tree
      begin
      from = repos.lookup(build[:now_build_commit])
      to = repos.lookup(build[:last_build_commit])
      rescue
        #处理需要远程话获取diff信息的compare
        puts "处理需要远程话获取diff信息的compare"
        build_compare << build[:now_build_commit]
        c=git_compare(build[:now_build_commit],build[:last_build_commit],user,repo)
        unless c.empty?
          puts "处理diff"
          diff_compare(c,build)
        end
        next
        
      end

      diff = to.diff(from)
      #puts diff.patch
      test_added = test_deleted = 0
      test_num=src_num=txt_num=config_num=0
      src_arry=[]
      state = :none
      arry= diff.stat#number of filesmodified/added/delete
      build[:filesmodified]= arry[0]
      build[:line_added]=arry[1]
      build[:line_deleted]=arry[2]
      build[:error_file_fixed]=0
      build[:src_modified]=0
      if !build.has_key?:tr_virtual_merged_into
        build[:tr_virtual_merged_into]= nil
      end
      #记录一下两次build修改的文件,key:build_id,value:[filepath]
      temp_filepath=[]
      diff.patch.lines.each do |line|
        if line.start_with? '---'
          file_path = line.strip.split(/---/)[1]
          next if file_path.nil?
          
          temp_filepath<<file_path.strip.split('a/',2)[1]
          #puts file_path
          file_name = File.basename(file_path)#文件名
          #puts file_name
          #file_dir = File.dirname(file_path)#路径/可以用来判断是否是test文件
          next if file_path.nil?
          
          if JavaData::test_file_filter.call(file_path)
            state = :in_test
            test_num+=1
          
          elsif $text_file.include? file_name.strip.split('.')[1] 
            state = :in_txt 
            txt_num+=1 
          elsif JavaData::src_file_filter.call(file_path)
            state = :in_src
            src_num+=1
            src_arry<< file_path.strip.split('a/',2)[1]
          else 
            state = :config
            config_num+=1
            
          end
            
        end
  
        if line.start_with? '- ' and state == :in_test
          if JavaData::test_case_filter.call(line)
            test_deleted += 1
          end
        end
  
        if line.start_with? '+ ' and state == :in_test
          if JavaData::test_case_filter.call(line)
            test_added += 1
          end
        end
  
        if line.start_with? 'diff --'
          state = :none
        end
      end
      puts build[:build_id]
      acc={:tests_added => test_added, :tests_deleted => test_deleted ,:test_file=>test_num, 
      :src_file=>src_num ,:txt_file=>txt_num,:cofig_file =>config_num,:build_id=>build[:build_id],:last_build_commit=>build[:last_build_commit],
      :repo_name=>"#{user}@#{repo}",:father_id=>build[:father_id]}
       filemodif_insert=Filemodif_info.new(acc)
       filemodif_insert.save

      
      #x={build[:build_id]=>{"filpath".to_sym=>temp_filepath,"src_path".to_sym=>src_arry}}
      file_paths=File_path.new
      file_paths.repo_name="#{user}@#{repo}"
      file_paths.build_id=build[:build_id]
      file_paths.father_id=build[:father_id]
      file_paths.last_build_commit=build[:last_build_commit]
      file_paths.filpath=temp_filepath
      file_paths.src_path=src_arry
      file_paths.save
      build.delete(:id)
      c=All_repo_data_virtual_prior_merge.new(build)
      c.save
    end
    
      
  end

  def self.run(user,repo) 
    FixSql.update_fail_build_rate(user,repo)
  end

  def lslr(tree, path = '')
      all_files = []
      for f in tree.map { |x| x }
        f[:path] = path + '/' + f[:name]
        if f[:type] == :tree
          begin
            all_files << lslr(git.lookup(f[:oid]), f[:path])
          rescue StandardError => e
            log e
            all_files
          end
        else
          all_files << f
        end
      end
      all_files.flatten
  end
#def files_at_commit(sha, filter = lambda { true })
  def files_at_commit(sha)

      begin
          repo = Rugged::Repository.new("git_travis_torrent/repos/#{@user}/#{@repo}")
          
        # build_commit = repo.lookup(sha)
        files = lslr(repo.lookup(sha).tree)#数组
        puts "files :#{files}"
        if files.size <= 0
          puts "No files for commit #{sha}"
        end
        #files.select { |x| filter.call(x) }
      rescue StandardError => e
        puts "Cannot find commit #{sha} in base repo"
        []
      end
  end


  def src_files(sha)
      files_at_commit(sha, src_file_filter)
  end

  def src_file_filter
      raise Exception.new("Unimplemented")
  end


# def load_builds(owner, repo,filename)
#   f = File.join("git_travis_torrent/build_logs", "#{owner}@#{repo}", filename)
#   unless File.exists? f
#     puts "不能找到"
#   end
  
#   JSON.parse File.open(f).read, :symbolize_names => true#return symbols
# end
  def self.load_builds(owner, repo,filename)
    f = File.join("build_logs", "#{owner}@#{repo}", filename)
    unless File.exists? f
      puts "不能找到"
    end
    
    JSON.parse File.open(f).read, :symbolize_names => true#return symbols
  end


  def self.git_compare(now,last,owner,repo)
      parent_dir = File.join('compare', "#{owner}@#{repo}")
      commit_json = File.join(parent_dir, "#{last[0,7]}@#{now[0,7]}.json")
      FileUtils::mkdir_p(parent_dir)

      r = {}
    if File.exists? commit_json
        r= begin
          JSON.parse File.open(commit_json).read
      rescue
        {}
      
      end
    end
    unless r.empty?
      return r
    end
    if r.empty? ||  !(File.exists? commit_json)
    
      unless r.nil? || r.empty?
          return r
        
      else
      

      url = "https://api.github.com/repos/#{owner}/#{repo}/compare/#{last}...#{now}"
      puts "Requesting #{url} (#{@remaining} remaining)"

      contents = nil
      begin
        puts "begin"
        puts $token
        r = open(url, 'User-Agent' => 'ghtorrent', 'Authorization' => "token #{$token}")
        
        @remaining = r.meta['x-ratelimit-remaining'].to_i
        puts "@remaining"
        puts @remaining
        @reset = r.meta['x-ratelimit-reset'].to_i
        contents = r.read
        JSON.parse contents
      rescue OpenURI::HTTPError => e
        @remaining = e.io.meta['x-ratelimit-remaining'].to_i
        @reset = e.io.meta['x-ratelimit-reset'].to_i
        puts  "Cannot get #{url}. Error #{e.io.status[0].to_i}"
        {}
      rescue StandardError => e
        puts "Cannot get #{url}. General error: #{e.message}"
        {}
      ensure
        File.open(commit_json, 'w') do |f|
          f.write contents unless r.nil?
          if r.nil? and 5000 - @remaining >= 6
            puts "xxxxx"
            git_compare(now, last, owner,repo)
          end
          
        
        end

        if 5000 - @remaining >= $REQ_LIMIT
          to_sleep = @reset - Time.now.to_i + 2
          puts "Request limit reached, sleeping for #{to_sleep} secs"
          sleep(to_sleep)
        end
      end
    end
  end
  end  



def self.diff_compare(compare_json,build)
  test_added = test_deleted = 0
  test_num=src_num=txt_num=config_num=0
  src_arry=[]
  state = :none
  #number of filesmodified/added/delete
  build[:filesmodified]= compare_json['files'].size
  line_added=0
  line_deleted=0
  build[:error_file_fixed]=0
  build[:src_modified]=0
  temp_filepath=[]
      
  for info in compare_json['files']
    line_added+=info['additions']
    line_deleted+=info['deletions']
  end
  build[:line_added]=line_added
  build[:line_deleted]=line_deleted
  parse_html=ParseHtml.new
  diff=parse_html.download_diff(compare_json['diff_url'])
  i=0
  diff.lines do |line|
    if line.start_with? '---'
      file_path = line.strip.split(/---/)[1]
      next if file_path.nil?
      
      temp_filepath<<file_path.strip.split('a/',2)[1]
      #puts file_path
      file_name = File.basename(file_path)#文件名
      #puts file_name
      #file_dir = File.dirname(file_path)#路径/可以用来判断是否是test文件
      next if file_path.nil?
      
      if JavaData::test_file_filter.call(file_path)
        state = :in_test
        test_num+=1
      
      elsif $text_file.include? file_name.strip.split('.')[1] 
        state = :in_txt 
        txt_num+=1 
      elsif JavaData::src_file_filter.call(file_path)
        state = :in_src
        src_num+=1
        src_arry<< file_path.strip.split('a/',2)[1]
      else 
        state = :config
        config_num+=1
        
      end
        
    end

    if line.start_with? '- ' and state == :in_test
      if JavaData::test_case_filter.call(line)
        test_deleted += 1
      end
    end

    if line.start_with? '+ ' and state == :in_test
      if JavaData::test_case_filter.call(line)
        test_added += 1
      end
    end

    if line.start_with? 'diff --'
      state = :none
    end
  end
  puts build[:build_id]
  acc={:tests_added => test_added, :tests_deleted => test_deleted ,:test_file=>test_num, 
  :src_file=>src_num ,:txt_file=>txt_num,:cofig_file =>config_num,:build_id=>build[:build_id],:last_build_commit=>build[:last_build_commit],
  :repo_name=>"#{@user}@#{@repo}",:father_id=>build[:father_id]}
   filemodif_insert=Filemodif_info.new(acc)
   filemodif_insert.save

  
  #x={build[:build_id]=>{"filpath".to_sym=>temp_filepath,"src_path".to_sym=>src_arry}}
  file_paths=File_path.new
  file_paths.repo_name="#{@user}@#{@repo}"
  file_paths.build_id=build[:build_id]
  file_paths.father_id=build[:father_id]
  file_paths.last_build_commit=build[:last_build_commit]
  file_paths.filpath=temp_filepath
  file_paths.src_path=src_arry
  file_paths.save
  build.delete(:id)
  c=All_repo_data_virtual_prior_merge.new(build)
  c.save
  



end


# def self.test_diff(user,repo)
#     #small_test=Small_test.new
#     '''
#     builds = load_builds(user, repo,"all_repo_virtual_prior_mergeinfo.json")
#     '''
#     builds={"now_build_commit":"0db6529e47db0d0e5e695d44ea5af26ce836efa7","commit_list":["0db6529e47db0d0e5e695d44ea5af26ce836efa7","80b78c8ba68e32963e1684787a10b7f78c91e81a"],"last_build_commit":"80b78c8ba68e32963e1684787a10b7f78c91e81a","authors":["hugo.van.rijswijk@hva.nl","cpovirk@google.com"],"num_author":2,"id":2278,"repo_name":"google@guava","build_id":"84682282","commit":"0db6529e47db0d0e5e695d44ea5af26ce836efa7","pull_req":2183,"branch":"master","status":"passed","message":"Set release version numbers to 19.0-rc2","duration":3501,"started_at":"2015-10-10T16:57:30Z","jobs":[84682283,84682284,84682285],"event_type":"pull_request","author_email":"cgdecker@google.com","committer_email":"cgdecker@google.com","tr_virtual_merged_into":"80b78c8ba68e32963e1684787a10b7f78c91e81a","merge_commit":"07326071e771c9244123791f00b848cc4f44fd9f","father_id":1}
#     arry=[]

#     builds=builds.uniq
#     repos = Rugged::Repository.new("git_travis_torrent/repos/#{user}/#{repo}")
#     #repo = Rugged::Repository.new("git_travis_torrent/repos/threerings/tripleplay")
#     #builds.map do|build|
    
      
#     filepath={}
#     build_compare=[]
    
#     for build in builds
      
#       #commits_tree=repo.lookup("666f593b94f504316eca4813cbfe42f615cad633").tree
#       begin
#       from = repos.lookup(build[:now_build_commit])
#       to = repos.lookup(build[:last_build_commit])
#       rescue
#         #处理需要远程话获取diff信息的compare
#         puts "处理需要远程话获取diff信息的compare"
#         build_compare << build[:now_build_commit]
#         c=git_compare(build[:now_build_commit],build[:last_build_commit],user,repo)
#         unless c.empty?
#           puts "处理diff"
#           diff_compare(c,build)
#         end
#         next
        
#       end

#       diff = to.diff(from)
#       #puts diff.patch
#       test_added = test_deleted = 0
#       test_num=src_num=txt_num=config_num=0
#       src_arry=[]
#       state = :none
#       arry= diff.stat#number of filesmodified/added/delete
#       build[:filesmodified]= arry[0]
#       build[:line_added]=arry[1]
#       build[:line_deleted]=arry[2]
#       build[:error_file_fixed]=0
#       build[:src_modified]=0
#       if !build.has_key?:tr_virtual_merged_into
#         build[:tr_virtual_merged_into]= nil
#       end
#       #记录一下两次build修改的文件,key:build_id,value:[filepath]
#       temp_filepath=[]
#       diff.patch.lines.each do |line|
#         if line.start_with? '---'
#           file_path = line.strip.split(/---/)[1]
#           next if file_path.nil?
          
#           temp_filepath<<file_path.strip.split('a/',2)[1]
#           #puts file_path
#           file_name = File.basename(file_path)#文件名
#           #puts file_name
#           #file_dir = File.dirname(file_path)#路径/可以用来判断是否是test文件
#           next if file_path.nil?
          
#           if JavaData::test_file_filter.call(file_path)
#             state = :in_test
#             test_num+=1
          
#           elsif $text_file.include? file_name.strip.split('.')[1] 
#             state = :in_txt 
#             txt_num+=1 
#           elsif JavaData::src_file_filter.call(file_path)
#             state = :in_src
#             src_num+=1
#             src_arry<< file_path.strip.split('a/',2)[1]
#           else 
#             state = :config
#             config_num+=1
            
#           end
            
#         end
  
#         if line.start_with? '- ' and state == :in_test
#           if JavaData::test_case_filter.call(line)
#             test_deleted += 1
#           end
#         end
  
#         if line.start_with? '+ ' and state == :in_test
#           if JavaData::test_case_filter.call(line)
#             test_added += 1
#           end
#         end
  
#         if line.start_with? 'diff --'
#           state = :none
#         end
#       end
#       puts build[:build_id]
#       acc={:tests_added => test_added, :tests_deleted => test_deleted ,:test_file=>test_num, 
#       :src_file=>src_num ,:txt_file=>txt_num,:cofig_file =>config_num,:build_id=>build[:build_id],:last_build_commit=>build[:last_build_commit],
#       :repo_name=>"#{user}@#{repo}"}
#        filemodif_insert=Filemodif_info.new(acc)
#        filemodif_insert.save

      
#       #x={build[:build_id]=>{"filpath".to_sym=>temp_filepath,"src_path".to_sym=>src_arry}}
#       file_paths=File_path.new
#       file_paths.repo_name="#{user}@#{repo}"
#       file_paths.build_id=build[:build_id]
#       file_paths.last_build_commit=build[:last_build_commit]
#       file_paths.filpath=temp_filepath
#       file_paths.src_path=src_arry
#       file_paths.save

#       c=All_repo_data_virtual_prior_merge.new(build)
#       c.save
#     end
#     # puts "acc :#{acc}"
#     # puts builds  
#     # puts filepath
#     # for build in builds
#     #   if build.keys.size > 22
#     #   #build[:repo_name]="#{user}@#{repo}"
#     #   build.delete(:id)
#     #   c=All_repo_data_virtual_prior_merge.new(build)
#     #   c.save
#     #   end
      
# end
     
  


end
owner = ARGV[0]
repo = ARGV[1]

#hashnew
#puts Diff_test.instance_methods(false)

#Diff_test.test_diff(owner,repo)
Diff_test.run(owner,repo)

#test_diff(owner,repo)