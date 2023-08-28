module gemini

import net.unix

enum RequestId {
	begin_request = 1
	end_request = 3
	params = 4
	stdin = 5
	stdout = 6
}

[heap]
struct FastCGI {
	path string
	sock &unix.StreamListener
}

struct FastCGIRequest {
	sock    &FastCGI
	content map[string]string
}

pub fn fcgi(unix_socket_path string) !FastCGI {
	// code int, format string, data string) {
	s := unix.listen_stream(unix_socket_path)!
	return FastCGI{
		path: unix_socket_path
		sock: s
	}
}

pub fn (fcgi &FastCGI) accept() !FastCGIRequest {
	sc := fcgi.accept()!
	mut header := [8]u8{}
	mut content := map[string]string{}
	content['REQUEST'] = 'GET'
	return FastCGIRequest{
		sock: fcgi
		content: content
	}
}

pub fn (fcgi &FastCGIRequest) submit(code int, mime string, data string) ! {
	// write response
	header := '${code} ${mime}\r\n${data}'
	// bytes := ''
	// fcgi.sock.write_ptr(bytes.data, bytes.len)
}
