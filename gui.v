import ui
import os
import gx
import gemini

[heap]
struct App {
mut:
	window    &ui.Window = unsafe { nil }
	input_url string     = 'gemini://geminispace.info/'
	text      string     = '?'
	font_size int        = 24
	content   []ui.Widget
	gmiview   ui.Widget = ui.button()
	textbox   []&ui.TextBox
}

const textarea_mode = false

fn (mut app App) on_enter(w &ui.TextBox) {
	app.btn_go(unsafe { nil })
	// do not much
}

fn win_key_down(w &ui.Window, e ui.KeyEvent) {
	if e.key == .escape {
		// TODO: w.close() not implemented (no multi-window support yet!)
		if w.ui.dd is ui.DrawDeviceContext {
			w.ui.dd.quit()
		}
	}
}

fn (mut app App) btn_go_selection(b &ui.Button) {
	s := app.textbox[0].sel_start
	println('p=... ${s}')
	/*
	mut tbox := b.ui.window.get_or_panic[ui.TextBox]('frame')
	tbox.style.bg_color = gx.red
	println('jeje is new ${tbox.sel_direction}')
	println(tbox.text.substr(tbox.cursor_pos, tbox.cursor_pos + 100))
	*/
}

fn (mut app App) btn_go(b &ui.Button) {
	// app.window.needs_refresh = true
	if unsafe { b != nil } {
		mut chis := app.gmiview.parent.get_children()
		chis << ui.button(text: 'hehe')
		app.window.needs_refresh = true
	}
	if app.input_url.starts_with('file://') {
		file_path := app.input_url.substr(7, app.input_url.len)
		data := os.read_file(file_path) or {
			app.text = 'cannot open file'
			return
		}
		app.text = data
	} else {
		// do the query and fill the website
		mut res := gemini.fetch(app.input_url) or { return }
		match res.code {
			10 {
				println('TODO: query input from user')
				app.input_url += '?hello'
				app.btn_go(b)
			}
			20 {
				// document := gemini.parse_document(res.body) or { return }
				app.text = res.body
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
		on_key_down: win_key_down
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
										ui.button(text: '<'),
									]
								),
								ui.column(
									children: [
										ui.button(text: '>'),
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
