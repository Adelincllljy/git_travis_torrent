require 'net/http'
require 'open-uri'
require 'json'
require 'date'
require 'time'
require 'fileutils'


class ParseHtml
def download_diff(url, wait_in_s = 1)
  if (wait_in_s > 64)
    STDERR.puts "Error: Giveup: We can't wait forever for #{url}"
    return 0
  elsif (wait_in_s > 1)
    sleep wait_in_s
  end

  begin
    begin
      log_url = url
      STDERR.puts "Attempt 1 #{log_url}"
      diff = Net::HTTP.get_response(URI.parse(log_url)).body
      return diff
    rescue
      # Workaround if log.body results in error.
      log_url = url
      STDERR.puts "Attempt 2 #{log_url}"
      diff = Net::HTTP.get_response(URI.parse(log_url)).body
      return diff
    end

    File.open(name, 'w') { |f| f.puts log }
    log = '' # necessary to enable GC of previously stored value, otherwise: memory leak
  rescue
    error_message = "Retrying, but Could not get log #{name}"
    puts error_message
    
    download_job(url, wait_in_s*2)
  end
end
end
