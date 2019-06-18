require File.expand_path('../../fix_sql.rb',__FILE__)
def run(user,repo) 
    #FixSql.update_last_build_status(user,repo)
    #FixSql.update_last_build_status2(user,repo)
    FixSql.update_job_number(user,repo)
  end
  owner = ARGV[0]
  repo = ARGV[1]
  run(owner,repo)