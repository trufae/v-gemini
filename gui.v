import ui
import os
import gemini

[heap]
struct App {
mut:
	window    &ui.Window = unsafe { nil }
	input_url string     = 'gemini://geminispace.info/'
	text      string     = '?'
	font_size int        = 24
	history   []string   = []string{}
	history2  []string   = []string{}
	content   []ui.Widget
	gmiview   ui.Widget = ui.button()
	textbox   []&ui.TextBox
	doc       gemini.Document
}

const textarea_mode = false

fn (mut app App) on_enter(w &ui.TextBox) {
	app.btn_go(unsafe { nil })
	// do not much
}

fn (mut app App) get_nlink(n int) ?gemini.Link {
	mut i := 0
	for ele in app.doc.content {
		if ele is gemini.Link {
			if n == i {
				if ele.link.starts_with('gemini://') {
					app.input_url = ele.link
				} else {
					// relative vs absolute
					if ele.link.starts_with('/') {
						host := app.input_url.split_nth('://', 2)
						if host.len > 1 {
							args := host[1].split_nth('/', 2)
							app.input_url = host[0] + '://' + args[0] + ele.link
						} else {
							app.input_url += ele.link.substr(1, ele.link.len)
						}
					} else {
						app.input_url += ele.link
					}
				}
				return ele
			}
			i++
		}
	}
	return error('not found')
}

fn (mut app App) key_down(w &ui.Window, e ui.KeyEvent) {
	if mut tbox := app.window.get[ui.TextBox]('input_url') {
		if tbox.is_focused {
			return
		}
	}
	// open links
	if e.key == ._1 {
		if link := app.get_nlink(0) {
			unsafe { app.btn_go(nil) }
			return
		}
	}
	if e.key == ._2 {
		if link := app.get_nlink(1) {
			unsafe { app.btn_go(nil) }
			return
		}
	}
	if e.key == ._3 {
		if link := app.get_nlink(2) {
			unsafe { app.btn_go(nil) }
			return
		}
	}
	if e.key == ._4 {
		if link := app.get_nlink(3) {
			unsafe { app.btn_go(nil) }
			return
		}
	}
	if e.key == ._5 {
		if link := app.get_nlink(4) {
			unsafe { app.btn_go(nil) }
			return
		}
	}
	if e.key == ._6 {
		if link := app.get_nlink(5) {
			unsafe { app.btn_go(nil) }
			return
		}
	}
	if e.key == ._7 {
		if link := app.get_nlink(6) {
			unsafe { app.btn_go(nil) }
			return
		}
	}
	if e.key == ._8 {
		if link := app.get_nlink(7) {
			unsafe { app.btn_go(nil) }
			return
		}
	}
	if e.key == ._9 {
		if link := app.get_nlink(8) {
			unsafe { app.btn_go(nil) }
			return
		}
	}
	if e.key == .escape {
		if ui.shift_key(e.mods) {
			unsafe { app.btn_fwd(nil) }
		} else {
			unsafe { app.btn_bck(nil) }
		}
		//
		/*
		// TODO: w.close() not implemented (no multi-window support yet!)
		if w.ui.dd is ui.DrawDeviceContext {
			w.ui.dd.quit()
		}
		*/
	}
}

fn (mut app App) btn_fwd(b &ui.Button) {
	if app.history2.len > 0 {
		mut text := app.history2.pop()
		if text == app.input_url && app.history2.len > 0 {
			text = app.history2.pop()
		}
		eprintln('=> ${text}')
		app.input_url = text
		app.btn_go(b)
	}
	app.window.get_or_panic[ui.Button]('bck').disabled = app.history.len == 0
	app.window.get_or_panic[ui.Button]('fwd').disabled = app.history2.len == 0
}

fn (mut app App) btn_bck(b &ui.Button) {
	if app.history.len > 0 {
		mut text := app.history.pop()
		if text != '' {
			if (text == app.input_url && app.history.len > 0) {
				text = app.history.pop()
			}
			eprintln('=> ${text}')
			app.input_url = text
			app.btn_go(b)
			app.history.pop()
			app.history2 << text
		}
	}
	app.window.get_or_panic[ui.Button]('bck').disabled = app.history.len == 0
	app.window.get_or_panic[ui.Button]('fwd').disabled = app.history2.len == 0
}

fn (mut app App) btn_go_selection(b &ui.Button) {
	/*
	s := app.textbox[0].sel_start
	println('p=... ${s}')
	mut tbox := b.ui.window.get_or_panic[ui.TextBox]('frame')
	tbox.style.bg_color = gx.red
	println('jeje is new ${tbox.sel_direction}')
	println(tbox.text.substr(tbox.cursor_pos, tbox.cursor_pos + 100))
	*/
}

fn (mut app App) history_push(text string) {
	if app.history.len > 0 {
		last := app.history.pop()
		if last != text {
			app.history << last
		}
	}
	app.history << text
	app.window.get_or_panic[ui.Button]('bck').disabled = app.history.len == 0
	app.window.get_or_panic[ui.Button]('fwd').disabled = app.history2.len == 0
}

fn (mut app App) history_pop() string {
	if app.history.len == 0 {
		return ''
	}
	return app.history.pop()
}

fn (mut app App) btn_go(b &ui.Button) {
	// app.window.needs_refresh = true
	if unsafe { b != nil } {
		mut chis := app.gmiview.parent.get_children()
		chis << ui.button(text: 'test')
		app.window.needs_refresh = true
	}
	if app.input_url.starts_with('file://') {
		file_path := app.input_url.substr(7, app.input_url.len)
		data := os.read_file(file_path) or {
			app.text = 'cannot open file'
			return
		}
		app.text = data
		app.history_push(app.input_url)
	} else {
		// do the query and fill the website
		mut res := gemini.fetch(app.input_url) or { return }
		code := unsafe { gemini.StatusCode(res.code) }
		match code {
			.input {
				app.input_url += '?'
				if mut tbox := app.window.get[ui.TextBox]('input_url') {
					// tbox.cursor_pos++
				}
			}
			.success {
				// document := gemini.parse_document(res.body) or { return }
				if doc := gemini.parse_document(res.body) {
					app.doc = doc
				}
				app.text = res.body
				app.history_push(app.input_url)
			}
			else {
				app.text = 'EOF'
				eprintln('unknown gemini error code ${res.code}')
			}
		}
	}
}

fn (mut app App) btn_font_inc(b &ui.Button) {
	app.font_size += 1
	mut tbox := b.ui.window.get_or_panic[ui.TextBox]('frame')
	// tbox.style_params.text_size = app.font_size
	//	tbox.style_params.bg_color = gx.yellow
	mut dtw := ui.DrawTextWidget(tbox)
	dtw.update_text_size(app.font_size)
	dtw.update_text_size(app.font_size)
	tbox.tv.update_lines()
	dtw.update_style(size: app.font_size)
	app.window.needs_refresh = true
}

fn (mut app App) btn_font_dec(b &ui.Button) {
	app.font_size -= 1
	if app.font_size < 8 {
		app.font_size = 8
	}
	mut tbox := b.ui.window.get_or_panic[ui.TextBox]('frame')
	tbox.style_params.text_size = app.font_size
	mut dtw := ui.DrawTextWidget(tbox)
	dtw.update_text_size(app.font_size)
	tbox.tv.update_lines()
	app.window.needs_refresh = true
}

fn main() {
	mut app := &App{}

	app.textbox = [
		ui.textbox(
			id: 'frame'
			mode: .multiline | .word_wrap | .read_only
			is_wordwrap: true
			text_font_name: 'fixed_bold'
			text_size: app.font_size
			text: &app.text
		),
	]
	// app.content = [&app.textbox]
	app.gmiview = ui.row(
		widths: ui.stretch
		heights: ui.stretch
		children: [app.textbox[0].parent.as_widget()]
	)
	app.gmiview = ui.row(
		widths: ui.stretch
		heights: ui.stretch
		children: [ui.Widget(app.textbox[0])]
	)
	app.window = ui.window(
		width: 800
		height: 600
		title: 'Vemini'
		on_key_down: app.key_down
		layout: ui.row(
			children: [
				ui.column(
					heights: [ui.compact, ui.compact, ui.stretch]
					widths: ui.stretch
					children: [
						// toolbar
						ui.row(
							heights: ui.compact
							widths: ui.compact
							children: [
								ui.column(
									children: [
										ui.button(text: 'Go', on_click: app.btn_go),
									]
								),
								ui.column(
									children: [
										ui.button(text: '<', on_click: app.btn_bck, id: 'bck'),
									]
								),
								ui.column(
									children: [
										ui.button(text: '>', on_click: app.btn_fwd, id: 'fwd'),
									]
								),
								ui.column(
									children: [
										ui.button(text: '-', on_click: app.btn_font_dec),
									]
								),
								ui.column(
									children: [
										ui.button(text: '+', on_click: app.btn_font_inc),
									]
								),
								ui.column(
									children: [
										ui.button(
											text: 'Go Selection'
											on_click: app.btn_go_selection
										),
									]
								),
							]
						),
						// addressbar
						ui.row(
							widths: ui.stretch
							heights: ui.compact
							children: [
								ui.textbox(
									id: 'input_url'
									on_enter: app.on_enter
									text: &app.input_url
								),
							]
						),
						// frame
						app.gmiview,
					]
				),
			]
		)
	)
	unsafe {
		app.btn_go(nil)
	}
	ui.run(app.window)
}
