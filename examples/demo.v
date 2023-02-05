module main
import gg
import gx
import collision2d as collision
import math.vec

const (
	win_width  = 640
	win_height = 480
)

[heap]
struct App {
	mut:
	gg    &gg.Context

	circle1 collision.Circle
	circle2 collision.Circle
	aabb1 collision.AABB
	line1 collision.Line2D

	mouse_position vec.Vec2[f32]

}

fn main() {
	mut app := &App{
		gg: 0
	}

	app.circle1 = collision.new_circle(vec.Vec2[f32]{100.0, 32.0}, 32.0)
	app.circle2 = collision.new_circle(vec.Vec2[f32]{200.0, 100.0}, 32.0)

	app.aabb1 = collision.new_aabb(vec.Vec2[f32]{200.0, 200.0}, 100.0, 100.0)


	app.line1 = collision.Line2D{
		start: vec.Vec2[f32]{0.0, 0.0}
		end: vec.Vec2[f32]{300.0, 200.0}
	}

	app.gg = gg.new_context(
		bg_color: gx.black
		width: win_width
		height: win_height
		create_window: true
		window_title: 'Window'
		frame_fn: frame
		event_fn: event
		user_data:app
	)
	app.gg.run()
}

fn event(mut ev gg.Event, mut app App) {
	app.mouse_position = vec.vec2[f32](ev.mouse_x, ev.mouse_y)
	app.circle1.position = app.mouse_position
}

fn frame(mut app App){
	app.gg.begin()

	mut circle_indication_color := gx.white
	if collision.circle_meets_circle(app.circle1, app.circle2) {
		circle_indication_color = gx.red
	}else{
		circle_indication_color = gx.white
	}

	mut aabb_indication_color := gx.white
	if collision.circle_meets_aabb(app.circle1, app.aabb1) {
		aabb_indication_color = gx.red
	}else{
		aabb_indication_color = gx.white
	}

	if collision.line_in_aabb(app.line1, app.aabb1) {
		println("line1 is in aabb1")
	}
	if collision.line_in_circle(app.line1, app.circle1) {
		println("line1 is in circle")
	}

	app.gg.draw_line(app.line1.start.x, app.line1.start.y, app.line1.end.x, app.line1.end.y, gx.white)

	app.gg.draw_circle(app.circle1.position.x, app.circle1.position.y, app.circle1.radius, circle_indication_color)
	app.gg.draw_circle(app.circle2.position.x, app.circle2.position.y, app.circle2.radius, circle_indication_color)

	app.gg.draw_rect_filled(
		app.aabb1.position.x-(app.aabb1.half_size.x),
		app.aabb1.position.y-(app.aabb1.half_size.y),
		app.aabb1.size.x,
		app.aabb1.size.y,
		aabb_indication_color
	)


	app.gg.end()
}
