require 'net/http'
require 'open-uri'
require 'json'
require 'date'
require 'time'
require 'fileutils'



#@date_threshold = Date.parse("2019-02-02")
#zh
module DownloadJobs
def self.download_job(job, name, wait_in_s = 1)
  if (wait_in_s > 64)
    STDERR.puts "Error: Giveup: We can't wait forever for #{job}"
    return 0
  elsif (wait_in_s > 1)
    sleep wait_in_s
  end

  begin
    begin
      log_url = "http://s3.amazonaws.com/archive.travis-ci.org/jobs/#{job}/log.txt"
      STDERR.puts "Attempt 1 #{log_url}"
      log = Net::HTTP.get_response(URI.parse(log_url)).body
    rescue
      # Workaround if log.body results in error.
      log_url = "http://s3.amazonaws.com/archive.travis-ci.org/jobs/#{job}/log.txt"
      STDERR.puts "Attempt 2 #{log_url}"
      log = Net::HTTP.get_response(URI.parse(log_url)).body
    end

    File.open(name, 'w') { |f| f.puts log }
    log = '' # necessary to enable GC of previously stored value, otherwise: memory leak
  rescue
    error_message = "Retrying, but Could not get log #{name}"
    puts error_message
    File.open(@error_file, 'a') { |f| f.puts error_message }
    download_job(job, wait_in_s*2)
  end
end

def self.job_logs(path,job_id)
  
    #name = File.expand_path(File.join('..', '..', '..', 'bodyLog2', 'build_logs', info.repo_name, job.sub(/\./, '@')+'.log'), File.dirname(__FILE__))
    unless File.exists?(path) and File.size(path) > 1

    download_job(job_id,path)
    end
  
end
end