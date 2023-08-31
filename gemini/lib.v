module gemini

import io
import strings
import net.mbedtls

pub struct Uri {
	protocol string
	peer     string
	port     int
	page     string
}

pub struct Response {
pub:
	code int
	mime string
	body string
}

pub fn parse_uri(url string) !Uri {
	kv := url.split('://')
	if kv.len != 2 {
		return error('missing ://')
	}
	if kv[0] != 'gemini' {
		return error('invalid protocol. only gemini:// is supported')
	}
	rest := kv[1].split_nth('/', 2)
	hp := rest[0].split(':')
	port := if hp.len > 1 { hp[1].int() } else { default_port }
	page := if rest.len > 1 { rest[1] } else { '' }
	return Uri{
		protocol: 'gemini'
		peer: hp[0]
		port: port
		page: page
	}
}

pub fn fetch(url string) !Response {
	r := parse_uri(url)!
	mut client := mbedtls.new_ssl_conn(mbedtls.SSLConnectConfig{ validate: false })!
	client.dial(r.peer, r.port)!
	// client.write_string('gemini://${r.peer}:${r.port}/${r.page}\r\n')!
	client.write_string('${url}\r\n')!
	mut reader := io.new_buffered_reader(reader: client)
	response := reader.read_line() or { return error('cannot read response from socket') }
	res := response.split_nth(' ', 2)
	mut text := strings.new_builder(32)
	for {
		curline := reader.read_line() or { break }
		text.write_string(curline)
		text.write_string('\n')
	}
	return Response{
		code: res[0].int()
		mime: res[1]
		body: text.str()
	}
}
