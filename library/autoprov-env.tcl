# Set the mode. Can be normal or stateless
set mode "normal"

# The URL prefix to download the SCP password Include the / at the end!
set scp_password_url "tftp://100.100.100.100/scp_passwords"

# Set the url_scheme to download configs. Can be scp or http
set url_scheme "scp"

# The URL prefix for downloading configs. Include the / at the end!
set http_url_prefix "100.100.100.100:8080/autoprov/startup/"

# The URL for downloading configs via scp. Dont include the scheme or user!
set scp_url_prefix "ztp.cutel.net/"

# Service discovery registration host[:port] and key. Don't include the scheme!
# Full URL built as: http://${sd_url_prefix}/register/${sd_key}?target=host[:port][&label.foo=bar...]
set sd_url_prefix "sd.cutel.net:8080"
set sd_key "8rjx1EuU9Z7usHWw"

