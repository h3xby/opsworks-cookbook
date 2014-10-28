package 'awscli' do
  action :install
end

package 'postgresql-client' do
	action :install
end

node[:deploy].each do |app_name, deploy|
	dump_file = "/tmp/#{app_name}.sql.dump"
	s3_dir = node[:s3_backups_path];
	s3_path = "#{s3_dir}/#{app_name}.pg_dump"
	script_path = "#{deploy[:deploy_to]}/shared/scripts/db_backup.sh"

	template script_path do
	    source "db_backup.sh.erb"
	    mode 0755
	    group deploy[:group]
	    variables(
	    	access_key_id: node[:s3_access_key_id],
			secret_access_key: node[:s3_secret_access_key],
	    	db_host: deploy[:database][:host],
	    	db_port: deploy[:database][:port],
	    	db_name: deploy[:database][:name],
	    	db_username: deploy[:database][:username],
	    	db_password: deploy[:database][:password],
	    	s3_path: "#{s3_dir}/#{app_name}.pg_dump",
	    	dump_file: "/tmp/#{app_name}.sql.dump"
	    )
	end 

	cron "backup_database" do
		hour '3'
		minute '0'
		command script_path
	end
end