import gemini

fn main() {
	// 	gemini.cgi(20, "text/gemini", "")
	cgi := gemini.fcgi('/tmp/cgi.sock')!
	for {
		req := cgi.accept() or { break }
		println('get accept')
	}
}
