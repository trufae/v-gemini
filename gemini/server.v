module gemini

import io
import os
import net.mbedtls

pub struct ServerOptions {
	root string = '.'
	port int    = default_port
	// ca_path string = 'ca.pem'
	cert_path string = default_cert
	key_path  string = default_key
	validate  bool
}

pub struct Server {
	options ServerOptions
pub mut:
	server &mbedtls.SSLListener
}

pub struct Query {
pub mut:
	client   &mbedtls.SSLConn
	text     string
	protocol string
	host     string
	path     string
	data     string
}

pub fn (mut gs Server) accept() !Query {
	mut client := gs.server.accept()!
	mut reader := io.new_buffered_reader(reader: client)
	mut request := reader.read_line()!
	reader.end_of_stream = true
	reader.free()
	mut proto := ''
	mut path := ''
	mut host := ''
	mut data := ''
	index := request.index('://') or { -1 }
	if index != -1 {
		words := request.split_nth('://', 2)
		proto = words[0]
		host_path := words[1].split_nth('/', 2)
		host = host_path[0]
		path_data := host_path[1].split_nth('?', 2)
		path = path_data[0]
		data = if path_data.len > 1 { path_data[1] } else { '' }
	} else {
		proto = ''
		path = request
	}
	return Query{
		client: client
		text: request
		protocol: proto
		host: host
		path: path
		data: data
	}
}

pub fn (mut gs Server) shutdown() ! {
	gs.server.shutdown()!
}

pub fn (mut q Query) respond(code int, mime string, data string) ! {
	q.client.write_string('${code} ${mime}\r\n${data}')!
	q.client.shutdown()!
}

pub fn serve(opt ServerOptions) !Server {
	mut server := mbedtls.new_ssl_listener('0.0.0.0:${opt.port}', mbedtls.SSLConnectConfig{
		// CA pathverify: opt.verify
		cert: os.resource_abs_path(opt.cert_path)
		cert_key: os.resource_abs_path(opt.key_path)
		validate: opt.validate
	})!
	return Server{
		options: opt
		server: server
	}
}
