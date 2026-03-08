# Set the mode. Can be normal or stateless
set mode "stateless"

# The URL prefix to download the SCP password Include the / at the end!
set scp_password_url "tftp://100.100.100.100/scp_passwords"

# Set the url_scheme to download configs. Can be scp or http
set url_scheme "scp"

# The URL prefix for downloading configs. Include the / at the end!
set http_url_prefix "100.100.100.100:8080/autoprov/startup/"

# The URL for downloading configs via scp. Dont include the scheme or user!
set scp_url_prefix "100.64.0.1/" 

