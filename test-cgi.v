import gemini

fn main() {
	// sockfile := '/tmp/cgi.sock'
	sockfile := '/Users/pancake/prg/gemini/test.fcgi'
	mut cgi := gemini.fcgi(sockfile)!
	for {
		mut req := cgi.accept() or { break }
		dump(req)
		url_path := req.env['GEMINI_URL_PATH']
		match url_path {
			'cgi/tenis' {
				query_string := req.env['QUERY_STRING']
				if query_string.len > 0 {
					name := query_string
					req.submit(20, 'text/gemini', 'Hello World\nThis is great ${name}\n')!
				} else {
					req.submit(10, 'text/gemini', 'What is your name\n')!
				}
			}
			else {
				req.submit(20, 'text/gemini', '# TODO\n')!
			}
		}
	}
}
