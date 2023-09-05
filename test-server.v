import gemini
import os

fn respond(mut query gemini.Query) ! {
	mut response := ''
	mut code := gemini.StatusCode.not_found
	// append to any /? move outside here
	if query.path.starts_with('/') {
		eprintln('massage path')
		query.path = '.${query.path}'
	}
	if query.path == '' || query.path.ends_with('/') {
		query.path += 'index.gmi'
	}
	mut mime := 'text/gemini'
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
				// mime = 'text/gemini'
				mime = ''
				response = '' // 'What is your question?'
			}
		} else if query.path.ends_with('.gmi') {
			eprintln('=> ${query.path}')
			data := os.read_file(query.path) or {
				query.respond(int(gemini.StatusCode.not_found), 'file not found', '')!
				return
			}
			code = .success
			response = data
		}
	}
	query.respond(int(code), mime, response)!
}

fn valid(mut query gemini.Query) bool {
	query.path.index('..') or { return true }
	return false
	/*
	dotdot := query.path.index('..') or { -1 }
	if query.path.starts_with('/') || dotdot != -1 {
		return false
	}
	return true
	*/
}

fn main() {
	mut s := gemini.serve(gemini.ServerOptions{})!
	for {
		// mut mime := 'text/gemini'
		mut query := s.accept() or {
			eprintln(err)
			continue
		}
		dump(query)
		if valid(mut query) {
			respond(mut query) or {
				eprintln(err)
			}
		} else {
			query.respond(51, 'invalid path', '')!
		}
	}
}
