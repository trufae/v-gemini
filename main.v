import gemini

fn main() {
	// mut res := gemini.fetch('gemini://radare.org/first.gmi')!
	mut res := gemini.fetch('gemini://radare.org/')!
	if res.code == 20 {
		document := gemini.parse_document(res.body)!
		println(res.body)
		println(document)
	}
}
