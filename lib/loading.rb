require 'active_record' 


class Load_repo< ActiveRecord::Base
    establish_connection(   
    adapter:  "mysql2",
    host:     "10.131.252.160",
    username: "root",
    password: "root",
    database: "cll_data",  
    encoding: "utf8mb4",
    collation: "utf8mb4_bin"
)

#set_table_name 'all_repo_data_virtual_prior_merges' 
end