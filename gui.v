import ui
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
}

fn (mut app App) btn_go(b &ui.Button) {
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
			eprintln('unknown gemini error code')
		}
	}
}

fn (mut app App) btn_render(b &ui.Button) {
	// do the query and fill the website
	//	mut tbox := b.ui.window.get_or_panic[ui.TextBox]('frame')
	app.content << ui.button(text: 'JEJE')
}

fn (mut app App) btn_font_inc(b &ui.Button) {
	app.font_size += 1
	mut tbox := b.ui.window.get_or_panic[ui.TextBox]('frame')
	// tbox.style_params.text_size = app.font_size
	tbox.style_params.bg_color = gx.yellow
	mut dtw := ui.DrawTextWidget(tbox)
	dtw.update_text_size(app.font_size)
	dtw.update_text_size(app.font_size)
	tbox.tv.update_lines()
	dtw.update_style(size: app.font_size)
}

fn (mut app App) btn_font_dec(b &ui.Button) {
	app.font_size -= 1
	if app.font_size < 8 {
		app.font_size = 8
	}
	mut tbox := b.ui.window.get_or_panic[ui.TextBox]('frame')
	 tbox.style_params.text_size = app.font_size
	//mut dtw := ui.DrawTextWidget(tbox)
	//dtw.update_text_size(app.font_size)
	tbox.tv.update_lines()
}

fn main() {
	mut app := &App{}
	app.content = [
		ui.textbox(
			id: 'frame'
			mode: .multiline | .read_only | .word_wrap
			text_font_name: 'fixed_bold'
			text_size: app.font_size
			text: &app.text
		),
	]
	app.window = ui.window(
		width: 800
		height: 600
		title: 'Vemini'
		layout: ui.row(
			children: [
				ui.column(
					heights: [ui.compact, ui.compact, ui.stretch]
					widths: ui.stretch
					children: [
						ui.row(
							heights: ui.compact
							widths: ui.compact
							children: [
								ui.column(
									alignments: ui.HorizontalAlignments{
										right: [1]
									}
									children: [ui.button(text: 'Go', on_click: app.btn_go)]
								),
								ui.column(
									children: [ui.button(text: '<')]
								),
								ui.column(
									children: [ui.button(text: '>')]
								),
								ui.column(
									children: [ui.button(text: '-', on_click: app.btn_font_dec)]
								),
								ui.column(
									children: [ui.button(text: '+', on_click: app.btn_font_inc)]
								),
							]
						),
						ui.row(
							widths: ui.stretch
							heights: ui.compact
							children: [
								ui.textbox(
									text: &app.input_url
								),
							]
						),
						ui.row(
							widths: ui.stretch
							heights: ui.stretch
							children: &app.content
						),
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
