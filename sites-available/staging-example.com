server {
  # listen 80 deferred; # for Linux
  # listen 80 accept_filter=httpready; # for FreeBSD
  listen [::]:80;
  listen 80;

  # The host name to respond to
  server_name staging.example.com;

  # Path for static files
  root /opt/staging/example.com;

  # Exclude from search engines
  location /robots.txt {
    return 200 "User-agent: *\nDisallow: /";
  }

  # Exclude favicon from logs
  location ~* /favicon.ico {
    log_not_found off;
    access_log off;
  }

  #Specify a charset
  charset utf-8;

  # Custom 404 page
  error_page 404 /404.html;

  # Include the basic h5bp config set
  include h5bp/basic.conf;
}