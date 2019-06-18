#gem 'activerecord', '< 5.2.3'
require 'active_record' 
require 'activerecord-import'
#require 'activerecord-jdbcmysql-adapter'
require 'rugged'

class Test< ActiveRecord::Base
    establish_connection(   
    adapter:  "mysql2",
    host:     "10.131.252.160",
    username: "root",
    password: "root",
    database: "cll_data",  
    encoding: "utf8mb4", 
    collation: "utf8mb4_bin"
)
belongs_to :category
serialize :jobs, Array
#set_table_name 'all_repo_data_virtual_prior_merges' 
end
def xx
c=[{ "parents": [
  {
    "sha": "e1894d0f34628d8b7313ca53fe71dc7e9ea300a3",
    "url": "https://api.github.com/repos/google/guava/commits/e1894d0f34628d8b7313ca53fe71dc7e9ea300a3",
    "html_url": "https://github.com/google/guava/commit/e1894d0f34628d8b7313ca53fe71dc7e9ea300a3"
  },
  {
    "sha": "x3189d0f34628d8b7313ca53fe71dc7e9ea300a3",
    "url": "https://api.github.com/repos/google/guava/commits/e1894d0f34628d8b7313ca53fe71dc7e9ea300a3",
    "html_url": "https://github.com/google/guava/commit/e1894d0f34628d8b7313ca53fe71dc7e9ea300a3"
  }
],
"commit": {
    "author": {
      "name": "cgdecker",
      "email": "cgdecker@google.com",
      "date": "2015-12-14T21:53:16Z"
    },
    "committer": {
      "name": "Chris Povirk",
      "email": "cpovirk@google.com",
      "date": "2015-12-14T22:23:15Z"
    }}},{"commit": {
      "author": {
        "name": "cgdecker",
        "email": "cgdecker@google.com",
        "date": "2015-12-14T21:53:16Z"
      },
      "committer": {
        "name": "Chris Povirk",
        "email": "cpovirk@google.com",
        "date": "2015-12-14T22:23:15Z"
      }}}]
d=[{"test":22},"test":33]

  puts c[0].has_key? :parents
   c=format("%.3f",Float(2)/3)
   puts c
    end
def test_build_prior_commit(owner,repo)
  repo = Rugged::Repository.new("git_travis_torrent/repos/#{owner}/#{repo}")
        
  build_commit = repo.lookup("cd2ecf0d9f9e73d8ded1f17b1c1a4f1b07cebb0c")
  puts build_commit
end
#ss=[{:repo_name=>"newcll"},{:repo_name=>"newcll"}]
# ss=[{:build_id=>1,:repo_name=>"xb"},{:build_id=>2,:repo_name=>"wx"}]
# ss.map  do |build|
#   if build[:build_id]==1
#     build[:new]=nil
#   else
#     build[:old]=nil
#   end
# end
#puts ss[0][:new].nil?

# puts Test.where("repo_name=?","cll5").find_each.size
# if Test.where("repo_name=?","cll5").find_each.size!=0
#     puts"test"
#     Test.where("repo_name=?","cll5").find_each do |test|
        
#     puts test[:build_id]
#     end
 
# else 
#     puts "nofind"

# end
def thread_test
Thread.abort_on_exception = true
threads=[] 
files_name=[]
filepath=["git_travis_torrent/build_logs/threerings@tripleplay","git_travis_torrent/commits/google@guava"]
10.times do |i|
  puts i
  thread=Thread.new(i/2) do |num|
    puts "num#{num}"
  for x in filepath 
    Dir.children(x).each do |m|
      files_name << m
    end
      
  end
end
  threads<< thread
end
threads.each { |thr| thr.join }

def thread_init
  Thread.abort_on_exception = true
  @queue = SizedQueue.new(10*2)
  puts "initai"
  threads = []
  10.times do |i|
    thread = Thread.new{
      

      loop do
        puts "deqqqq"
        hash = @queue.deq
        puts "hash"
        puts hash

        break if hash == :END_OF_WORK
        puts "crawl"
      end
    }
    threads << thread
  end
  threads
end
end

def run
  threads = thread_init
 
  for i in (10..13)
    #FileUtils.mkdir_p(parent_dir) unless File.exist?(parent_dir)
    if i<11
      puts " doesn't exist"
      next
    end
    puts i
    for m in (i/2..i+20)
      puts "#{m}进队列"
      @queue.enq m
    end

  end
  puts"end_of_work进队列"
  @queue.size
  10.times do
    
    @queue.enq :END_OF_WORK
    puts"end_of_work进了一次进队列"
  end
  threads.each { |t| t.join }
  puts "Over"
end  

def test 
  for i in (1..10)
    if i<3
      puts "xiaoyu3"
      next
    end
    puts "dayusan"
  end
end


def runtest
  threads = []
threads << Thread.new { puts "Whats the big deal" }
threads << Thread.new { 3.times { puts "Threads are fun!" } }
threads.each { |thr| thr.join }
end

owner=ARGV[0]
repo=ARGV[1]
#test_build_prior_commit(owner,repo)