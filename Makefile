CN=localhost

all:
	v test-cgi.v
	v run main.v
	v run test-server.v

fmt:
	v fmt -w .

serve:
	v run test-server.v

keys:
	openssl req -x509 -newkey rsa:4096 -nodes \
	      -keyout key.pem -out cert.pem \
	      -days 365 -subj "/CN=$(CN)"
	chmod 600 key.pem cert.pem
