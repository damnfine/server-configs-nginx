upstream cms_app {
    server  unix:/tmp/example_gunicorn.sock;
}

# www to non-www redirect -- duplicate content is BAD:
# https://github.com/h5bp/html5-boilerplate/blob/5370479476dceae7cc3ea105946536d6bc0ee468/.htaccess#L362
# Choose between www and non-www, listen on the *wrong* one and redirect to
# the right one -- http://wiki.nginx.org/Pitfalls#Server_Name
server {
  # don't forget to tell on which port this server listens
  listen [::]:80;
  listen 80;

  # listen on the www host
  server_name www.example.com;

  # and redirect to the non-www host (declared below)
  return 301 $scheme://example.com$request_uri;
}

server {
  # listen 80 deferred; # for Linux
  # listen 80 accept_filter=httpready; # for FreeBSD
  listen [::]:80;
  listen 80;

  client_max_body_size 20M;

  # The host name to respond to
  server_name example.com;

  # Path for static files
  root /opt/example/current;

  #Specify a charset
  charset utf-8;

  # Custom 404 page
  error_page 404 /404.html;

  location / {
    proxy_pass          http://cms_app;
    proxy_redirect      off;
    proxy_set_header    Host $host;
    proxy_set_header    X-Real-IP $remote_addr;
    proxy_set_header    X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Host $server_name;
  }

  location /static/ {
    root            /opt/example/current/static;
    access_log      off;
    log_not_found   off;
  }

  location /robots.txt {
    return 200 "User-agent: *\nDisallow: /";
    access_log      off;
    log_not_found   off;
  }

  location /favicon.ico {
    root            /opt/example/current/static/img;
    access_log      off;
    log_not_found   off;
  }

  # Include the basic h5bp config set
  include h5bp/basic.conf;
}
