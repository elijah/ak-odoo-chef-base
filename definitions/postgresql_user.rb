define :postgresql_user, :action => :create do

  case params[:action]
  when :create
    privileges = { :superuser => false, :createdb => false, :inherit => true, :login => true }
    privileges.merge! params[:privileges] if params[:privileges]
    bool_map = {true => "t", false => "f"}
    exists = "/usr/bin/psql -c 'SELECT usename FROM pg_catalog.pg_user' | grep '^ #{params[:name]}$'"
    is_equal = "/usr/bin/psql -c 'SELECT usesuper,usecreatedb,usename FROM pg_catalog.pg_user' | grep '^ #{bool_map[privileges[:superuser]]}        | #{bool_map[privileges[:createdb]]}           | #{params[:name]}$'"
    privileges = privileges.to_a.map! { |p,b| (b ? '' : 'NO') + p.to_s.upcase }.join(' ')

    if params[:password]
      password = "PASSWORD '#{params[:password]}'"
    end

    sql = "#{params[:name]} #{privileges} #{password}"

    execute "alter postgresql user #{params[:name]}" do
      user "postgres"
      command "/usr/bin/psql -c \"ALTER ROLE #{sql}\""
      only_if exists, user: "postgres"
      not_if is_equal, user: "postgres"
    end

    execute "create postgresql user #{params[:name]}" do
      user "postgres"
      command "/usr/bin/psql -c \"CREATE ROLE #{sql}\""
      not_if exists, user: "postgres"
    end
  when :drop
    execute "/usr/bin/psql -c 'DROP ROLE IF EXISTS #{params[:name]}'" do
      user "postgres"
    end
  end
end
