# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_webmusicplayer_session',
  :secret      => 'c6e4a2fac31cb6160fc084abfe6a70820e9b96fb24e149844c068c7098cee14948d6b031dc2115a31e90907d2b77f3a8dd332314e1cadc25ca24d7fe3121a75c'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
