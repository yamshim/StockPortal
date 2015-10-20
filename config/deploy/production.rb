# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.

role :app, %w{akasatana@153.126.139.250}
role :web, %w{akasatana@153.126.139.250}
role :db,  %w{akasatana@153.126.139.250}


# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

server '153.126.139.250', user: 'akasatana', roles: %w{web app db}


# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#
# And/or per server (overrides global)
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
set :ssh_options, {
  user: 'akasatana', # overrides user setting above
  keys: %w(/Users/akasatana/.ssh/id_rsa),
  forward_agent: true,
  auth_methods: %w(publickey),
  port: '61203'
#     # password: 'please use keys'
}