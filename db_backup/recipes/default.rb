package 'awscli' do
	action :install
end

package 'postgresql-client' do
	action :install
end

node[:deploy].each do |app_name, deploy|
	settings = node[:db_backup]

	s3_dir = settings[:s3_path];
	script_path = File.join(deploy[:deploy_to], "/shared/scripts/db_backup.sh")
	timestamp = Time.now.strftime("%Y.%m.%d.%H.%M.%S")

	template script_path do
	    source "db_backup.sh.erb"
	    mode 0755
	    group deploy[:group]
	    variables(
	    	access_key_id: settings[:s3_access_key_id],
			secret_access_key: settings[:s3_secret_access_key],
	    	db_host: deploy[:database][:host],
	    	db_port: deploy[:database][:port],
	    	db_name: deploy[:database][:database],
	    	db_username: deploy[:database][:username],
	    	db_password: deploy[:database][:password],
	    	s3_path: File.join(s3_dir, app_name, "#{timestamp}.pg_dump")
	    	dump_file: "/tmp/#{app_name}.psql.dump"
	    )
	end 

	cron "backup_database" do
		hour '3'
		minute '0'
		command script_path
	end
end