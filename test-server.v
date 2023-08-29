import gemini
import os

fn main() {
	mut s := gemini.serve(gemini.ServerOptions{})!
	mut arg := 'text/gemini'
	for {
		arg = 'text/gemini'
		mut query := s.accept()!
		dotdot := query.path.index('..') or { -1 }
		if query.path.starts_with('/') || dotdot != -1 {
			query.respond(51, 'invalid path', '')!
			continue
		}
		if query.path == '' {
			query.path = 'index.gmi'
		}
		dump(query)
		mut response := ''
		mut code := gemini.ErrorCode.not_found
		arg = 'text/gemini'
		if query.path == '' {
			response = 'hello world\n'
			code = .success
		} else {
			if query.path == 'search' {
				if query.data != '' {
					response = '# Ok\n' + 'We search for ${query.data}\n' + '=> search again\n' +
						'=> / root\n'
					code = .success
				} else {
					code = .input
					// arg = 'text/gemini'
					arg = ''
					response = '' // 'What is your question?'
				}
			} else if query.path.ends_with('.gmi') {
				eprintln('=> ${query.path}')
				data := os.read_file(query.path) or {
					query.respond(51, 'file not found', '')!
					continue
				}
				code = .success
				response = data
			}
		}
		query.respond(int(code), arg, response)!
	}
}
