require 'active_record' 


class All_repo_data_virtual< ActiveRecord::Base
    establish_connection(   
    adapter:  "mysql2",
    host:     "10.131.252.160",
    username: "root",
    password: "root",
    database: "cll_data",  
    encoding: "utf8mb4",
    collation: "utf8mb4_bin"
)
serialize :jobs, Array
serialize :jobs_arry, Array
has_many :maven_errors
end
 
  

