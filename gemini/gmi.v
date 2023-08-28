module gemini

pub struct Link {
	link  string
	title string
}

pub struct Title {
	text string
}

pub struct SubTitle {
	text string
}

pub struct SubSubTitle {
	text string
}

pub struct Text {
	text string
}

pub struct Quote {
	text string
}

pub struct CodeBlock {
	syntax string
	text   string
}

pub type Element = CodeBlock | Link | Quote | SubSubTitle | SubTitle | Text | Title

pub struct Document {
	content []Element
}

pub fn parse_document(text string) !Document {
	mut c := []Element{}
	mut in_code_block := false
	lines := text.split('\n')
	mut cb := []string{}
	mut syntax := ''
	for line in lines {
		if in_code_block {
			if line.starts_with('```') {
				c << CodeBlock{
					syntax: syntax
					text: cb.join('\n')
				}
				in_code_block = false
			} else {
				cb << line
			}
		} else if line.starts_with('###') {
			c << SubSubTitle{line.substr(3, line.len).trim_space()}
		} else if line.starts_with('##') {
			c << SubTitle{line.substr(2, line.len).trim_space()}
		} else if line.starts_with('#') {
			c << Title{line.substr(1, line.len).trim_space()}
		} else if line.starts_with('=>') {
			rest := line.substr(2, line.len).trim_space()
			sep := rest.split_nth(' ', 2)
			c << Link{sep[0], sep[1]}
		} else if line.starts_with('>') {
			c << Quote{line}
		} else if line.starts_with('```') {
			syntax = line.substr(3, line.len)
			in_code_block = true
		} else {
			c << Text{line}
		}
	}
	return Document{
		content: c
	}
}
