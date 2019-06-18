#gem 'activerecord', '< 5.2.3'
require 'active_record' 


class All_repo_data_virtual_prior_merge< ActiveRecord::Base
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

# build={"now_build_commit":"619c4fd127dc45a4668e3f25c7324f4c9b98e8e3",
# "commit_list":["519c4fd127dc45a4668e3f25c7324f4c9b98e8e3","838560034dfaa1afdf51a126afe6b8b8e6cce3dd"],"last_build_commit":"838560034dfaa1afdf51a126afe6b8b8e6cce3dd","authors":["noreply@github.com","shapiro.rd@gmail.com"],
# "num_author":2,"id":501,"repo_name":"google@guava","build_id":"487264792","commit":"519c4fd127dc45a4668e3f25c7324f4c9b98e8e3","pull_req":3372,"branch":"master","status":"errored","message":"adhere to style guidelines","duration":2149,"started_at":"2019-02-01T04:19:38Z","jobs":[487264793,487264794,487264795,487264796],
# "event_type":"pull_request","author_email":"hwaite@post.harvard.edu","committer_email":"hwaite@post.harvard.edu","tr_virtual_merged_into":"838560034dfaa1afdf51a126afe6b8b8e6cce3dd","merge_commit":"104759e7557437e968d1a673173b509bd48324c0"}
# puts build.keys.size
# # build[:filesmodified]= 0
# # build[:line_added]=0
# # build[:line_deleted]=0
# # build[:error_file_fixed]=0
# # build[:src_modified]=0
# build.delete(:id)
# c=All_repo_data_virtual_prior_merge.new(build)
# c.save
#set_table_name 'all_repo_data_virtual_prior_merges' 
end
