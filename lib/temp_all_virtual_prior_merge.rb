require 'active_record' 


class Temp_all_virtual_prior_merge< ActiveRecord::Base
    establish_connection(   
    adapter:  "mysql2",
    host:     "10.131.252.160",
    username: "root",
    password: "root",
    database: "cll_data",  
    encoding: "utf8mb4",
    collation: "utf8mb4_bin"
)
has_one :filemodif_infos
has_one :file_paths
serialize :jobs, Array
serialize :authors, Array
serialize :commit_list, Array
end