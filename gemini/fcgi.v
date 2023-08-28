module gemini

import net.unix

enum RequestType {
	begin_request = 1
	end_request = 3
	params = 4
	stdin = 5
	stdout = 6
}

[heap]
struct FastCGI {
	path string
mut:
	sock &unix.StreamListener
}

// rename to Connection
pub struct FastCGIRequest {
	fcgi &FastCGI
pub mut:
	client &unix.StreamConn
	env    map[string]string
}

pub fn fcgi(unix_socket_path string) !FastCGI {
	s := unix.listen_stream(unix_socket_path)!
	return FastCGI{
		path: unix_socket_path
		sock: s
	}
}

struct FastCGIHeader {
	version  u8
	typ      u8
	req1     u8
	req0     u8
	clen1    u8
	clen0    u8
	padding  u8
	reserved u8
mut:
	content0 string
	content1 string
}

pub fn (mut fcgi FastCGIRequest) read_header() !FastCGIHeader {
	mut header := [u8(0), 0, 0, 0, 0, 0, 0, 0]
	fcgi.client.read_ptr(&u8(header.data), header.len)!
	// println('READ header ${header}')
	mut hdr := FastCGIHeader{
		version: header[0]
		typ: header[1]
		req1: header[2]
		req0: header[3]
		clen1: header[4]
		clen0: header[5]
		padding: header[6]
		reserved: header[7]
	}
	content0 := []u8{len: 256, init: 0}
	content1 := []u8{len: 256, init: 0}
	padding := []u8{len: 256, init: 0}
	if hdr.clen1 > 0 {
		// packet is too large, not supported
	}
	if hdr.clen0 > 0 {
		// println('READING clen0 ${hdr.clen0}')
		fcgi.client.read_ptr(&u8(content0.data), hdr.clen0)!
		hdr.content0 = content0.bytestr().substr(0, hdr.clen0)
	}
	if hdr.padding > 0 {
		// padding is ignored
		fcgi.client.read_ptr(&u8(padding.data), hdr.padding)!
	}
	return hdr
}

pub fn (mut fcgi FastCGIRequest) send(code int, message string) ! {
	mut hdr := []u8{len: 8, init: 0}
	// why not	hdr := [8]u8{}
	match code {
		6 {
			// stdout
			hdr[0] = 1
			hdr[1] = 6
			hdr[3] = 1 // req0
			// hdr[2] = req1
			// hdr[3] = req0
			hdr[4] = 0 // clen1 (size >> 8)
			hdr[5] = u8(message.len) // (size & 0xff)
			fcgi.client.write_ptr(hdr.data, hdr.len)!
			m := message.bytes()
			if m.len > 0 {
				fcgi.client.write_ptr(m.data, m.len)!
			}
		}
		3 {
			// end_request
			hdr[0] = 1
			hdr[1] = 3
			hdr[3] = 1 // req0 taken from the request
			hdr[4] = 0 // clen1
			hdr[5] = 8 // u8(message.len)
			fcgi.client.write_ptr(hdr.data, hdr.len)!
			mut ereq := []u8{len: 8, init: 0}
			fcgi.client.write_ptr(ereq.data, ereq.len)!
		}
		else {}
	}
}

pub fn (mut fcgi FastCGI) accept() !FastCGIRequest {
	mut client := fcgi.sock.accept()!
	mut env := map[string]string{}
	mut request := FastCGIRequest{
		client: client
		fcgi: fcgi
	}
	for {
		header := request.read_header()!
		htype := unsafe { RequestType(header.typ) }
		match htype {
			.begin_request {
				// .begin_request // not checking anything
			}
			.params {
				if header.content0.len > 1 {
					klen := u8(header.content0.bytes()[2])
					vlen := u8(header.content0.bytes()[3])

					txt := header.content0.substr(8, 8 + vlen).trim_space()
					val := header.content0.substr(vlen + 8, header.content0.len).trim_space()
					env[txt] = val
				}
			}
			.stdin {
				// .stdin // TODO: not used by gemini but must be handled too
			}
			else {
				eprintln('::unknown request type ${header.typ}')
			}
		}
		if header.typ == 5 && header.clen0 == 0 && header.clen1 == 0 {
			break
		}
	}

	return FastCGIRequest{
		client: client
		fcgi: fcgi
		env: env
	}
}

// submit a reqsponse using the gemini protocol. contents are limited to 256 bytes
pub fn (mut fcgi FastCGIRequest) submit(code int, mime string, data string) ! {
	msg := '${code} ${mime}\r\n${data}'
	fcgi.send(6, msg)!
	fcgi.send(3, '')!
}
