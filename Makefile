all:
	v test-cgi.v
	v run main.v

fmt:
	v fmt -w .
