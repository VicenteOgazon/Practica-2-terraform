upstream backend {
%{ for b in backends ~}
    server ${b}:${backend_port};
%{ endfor ~}
}

server {
    listen ${listen_port};

    location / {
        proxy_pass http://backend;
    }

    location = /lb-health {
        access_log off;
        return 200 'OK';
        add_header Content-Type text/plain;
    }

        location = /__backends {
            default_type text/plain;
            return 200 "${backends_text}\n";
    }
}