require 'active_record' 
#require 'activerecord-jdbcmysql-adapter'
require File.expand_path('../string_to_arry.rb',__FILE__)
#require_relative 'string_to_arry.rb'
class  All_repo_data_virtual_prior_merge< ActiveRecord::Base
    #include Process_sql_string
    establish_connection(   
    adapter:  "mysql2",
    host:     "10.131.252.160",
    username: "root",
    password: "root",
    database: "cll_data",  
    encoding: "utf8mb4",
    collation: "utf8mb4_bin"
)

 
end  


detail_info= All_repo_data_virtual_prior_merge.first

puts detail_info.commit_list
puts Process_sql_string.string_arry(detail_info.commit_list)[0][0]
