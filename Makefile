all:
	v run main.v
	v test-cgi.v

fmt:
	v fmt -w .
