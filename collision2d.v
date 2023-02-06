module collision2d

import math.vec
import math

// --------------------------------------------------
// --- Point Collision ---
// --------------------------------------------------

// point_on_line Returns true if a Vec2(point) is on a line(Line2D)
pub fn point_on_line(point vec.Vec2[f32], line Line2D) bool {
	// Using Y=MX+B
	delta_y := line.end.y - line.start.y
	delta_x := line.end.x - line.start.x
	if delta_x == 0.0 { // Division by Zero is possible, so lets avoid that. (Fixes bug in vertical collisions)
		return compare_with_epsilon_float_min(point.x, line.start.x)
	}
	m := delta_y / delta_x
	b := line.end.y - (m * line.end.x)

	return (point.y == m * point.x + b)

}

// point_in_circle Returns true if a Vec2(point) is within a circle
pub fn point_in_circle(point vec.Vec2[f32], circle Circle) bool {
	circle_center := circle.get_center()
	center_to_point := point.sub(circle_center)
	squared := center_to_point.magnitude() * center_to_point.magnitude() // ^2 SAVES CPU CYCLES
	return (squared < circle.radius * circle.radius) // ^2 SAVES CPU CYCLES
}

// point_in_aabb Returns true if a Vec2(point) is within an axis aligned bounding box(AABB) A.K.A Rectangle
pub fn point_in_aabb(point vec.Vec2[f32], box AABB) bool {
	min := box.get_min()
	max := box.get_max()
	return (point.x >= min.x && point.x <= max.x && point.y >= min.y && point.y <= max.y)
}


/*
pub fn point_in_box2d(point vec.Vec2[f32], box2d Box2D) bool {
	mut local_point_box_space := point
	local_point_box_space = vec2_rotate_about_point(local_point_box_space, box2d.rotation, box2d.position)

	min := box2d.get_min()
	max := box2d.get_max()
	return (local_point_box_space.x <= max.x && min.x <= local_point_box_space.x && local_point_box_space.y <= max.y && min.y <= local_point_box_space.y)
}
*/

// --------------------------------------------------
// --- Line Collision ---
// --------------------------------------------------

// line_in_circle Returns true if a Line2D intersects a circle
pub fn line_in_circle(line Line2D, circle Circle) bool {

	if point_in_circle(line.start, circle) || point_in_circle(line.end, circle) {
		return true
	}
	ab := line.end.sub(line.start)

	// Project point onto Line2D
	circle_center := circle.get_center()
	center_to_line_start := circle_center.sub(line.start)
	t := center_to_line_start.dot(ab) / ab.dot(ab)

	if t < 0.0 || t > 1.0 {
		return false
	}

	// Find nearest point to line
	nearest_point := line.start.add(ab.mul_scalar(t))
	return point_in_circle(nearest_point, circle)
}

// line_in_aabb Returns true if a Line2D intersects an axis aligned bounding box
pub fn line_in_aabb(line Line2D, box AABB) bool {
	if point_in_aabb(line.start, box) || point_in_aabb(line.end, box) {
		return true
	}

	mut unit := line.end.sub(line.start)
	unit = unit.normalize()
	unit.x = if unit.x != 0.0 { 1.0 / unit.x } else { 0.0 }
	unit.y = if unit.y != 0.0 { 1.0 / unit.y } else { 0.0 }

	mut min := box.get_min()
	min = min.sub(line.start).mul(unit)
	mut max := box.get_max()
	max = max.sub(line.start).mul(unit)

	tmin := math.max[f32](math.min[f32](min.x, max.x), math.min[f32](min.y, max.y))
	tmax := math.min[f32](math.max[f32](min.x, max.x), math.max[f32](min.y, max.y))

	if tmax < 0.0 || tmin > tmax {
		return false
	}

	t := if tmin < 0.0 { tmax } else { tmin }
	return (t > 0.0 && t * t < line.length_squared())

}

/*
pub fn line_in_box2d(line Line2D, box Box2D) bool {

	theta := -box.rotation // Must be negative?
	center := box.position
	mut local_start := line.start
	mut local_end := line.end

	local_start = vec2_rotate_about_point(local_start, theta, center)
	local_end = vec2_rotate_about_point(local_end, theta, center)

	local_line := Line2D{
		start: local_start
		end: local_end
	}

	local_aabb := new_aabb(center, local_end.x, local_end.y)

	return (line_in_aabb(local_line, local_aabb))

}*/

/* --------------------------------------------------
// --- RAYCAST 2D ---
// --------------------------------------------------

pub fn raycast_circle_result(circle Circle, ray Ray2D, mut result Ray2DResult) bool {
	result.reset()

	origin_to_circle := circle.get_center().sub(ray.origin)
	radius_squared := circle.radius * circle.radius
	origin_circle_len_sqrd := origin_to_circle.magnitude() * origin_to_circle.magnitude()

	// Project vect from ray to direction of ray
	a := origin_to_circle.dot(ray.direction)
	b_sq := origin_circle_len_sqrd - (a * a)
	if radius_squared - b_sq < 0.0 {
		return false
	}

	// Ehhh...
	f := f32(math.sqrt(radius_squared - b_sq))
	mut t := f32(0.0)
	if origin_circle_len_sqrd < radius_squared {
		// ray begins in the circle
		t = a + f
	}else{
		t = a - f
	}
	point := ray.origin.add(ray.direction).mul_scalar[f32](t)
	normal := ray.origin.sub(point)//point.sub(circle.get_center())
	normal.normalize()

	result.init(point, normal, t, true)
	return true
}

/* This doesn't work for some reason... TODO: Verify maths
pub fn (inter IntersectionDetector2D) raycast_aabb_result(box AABB, ray Ray2D, mut result Ray2DResult) bool {

	// Reset raycast results for reuse
	result.reset()

	mut unit := ray.direction
	unit = unit.normalize()
	unit.x = if unit.x != 0 { 1.0 / unit.x } else { 0 }
	unit.y = if unit.y != 0 { 1.0 / unit.y } else { 0 }

	println("Unit: ${unit}")

	mut min := box.get_min()
	min = min.sub(ray.origin).mul(unit)
	mut max := box.get_max()
	max = max.sub(ray.origin).mul(unit)
	println("Min: ${min}")
	println("Max: ${max}")
	tmin := maxf(minf(min.x, max.x), minf(min.y, max.y))
	//tmin := math.max[f32](math.min[f32](min.x, max.x), math.min[f32](min.y, max.y))
	tmax := minf(maxf(min.x, max.x), maxf(min.y, max.y))
	// //math.min[f32](math.max[f32](min.x, max.x), math.max[f32](min.y, max.y))

	println("TMin: ${tmin}")
	println("TMax: ${tmax}")

	if tmin > tmax || tmax < 0 {
		println("Error: Tmin/Tmax")
		return false
	}

	//mut t :=
	t := if tmin < 0 { tmax } else { tmin }
	hit := (t > 0) //(math.sign(t) == 1.0) // && t * t < ray.max_distance

	println("T: ${t}")

	if !hit {
		println("No hit detected. Returning false.")
		return false
	}
	point := ray.origin.add(ray.direction.mul_scalar[f32](t))
	normal := ray.origin.sub(point)
	normal.normalize()

	result.init(point, normal, t, true)

	return true
	//return (t > 0.0 && t * t < ray.length_squared())
}*/

/* Trying a different format... AND Also doesn't work? :/
pub fn (inter IntersectionDetector2D) raycast_aabb_result(box AABB, ray Ray2D, mut result Ray2DResult) bool {

	// Reset raycast results for reuse
	result.reset()

	mut unit := ray.direction.normalize()
	unit.x = if unit.x != 0.0 { 1.0 / unit.x } else { 0.0 }
	unit.y = if unit.y != 0.0 { 1.0 / unit.y } else { 0.0 }

	println("Unit: ${unit}")

	bmin := box.get_min()
	bmax := box.get_max()

	min := bmin.sub(ray.origin).mul(unit)
	max := bmax.sub(ray.origin).mul(unit)

	tmin := maxf(minf(min.x, max.y), minf(min.x, max.y))
	//tmin := math.max[f32](math.min[f32](min.x, max.x), math.min[f32](min.y, max.y))
	tmax := minf(maxf(min.x, max.x), maxf(min.y, max.y))
	// //math.min[f32](math.max[f32](min.x, max.x), math.max[f32](min.y, max.y))

	println("TMin: ${tmin}")
	println("TMax: ${tmax}")

	if tmax < 0.0 || tmin > tmax {
		println("TMin ${tmin} is greater than ${tmax} ")
		//return false
	}


	t := if tmin < 0.0 { tmax } else { tmin }
	println(t)
	hit := (t > 0.0) //(math.sign(t) == 1.0) // && t * t < ray.max_distance

	if !hit {
		println("No hit detected. Returning false.")
		return false
	}
	point := ray.origin.add(ray.direction.mul_scalar[f32](t))
	normal := ray.origin.sub(point)
	normal.normalize()

	result.init(point, normal, t, true)

	return true
	//return (t > 0.0 && t * t < ray.length_squared())
}*/

pub fn raycast_box2d_result(box Box2D, ray Ray2D, mut result Ray2DResult) bool {
	result.reset()

	size := box.half_size
	mut x_axis := vec.Vec2[f32]{1, 0}
	mut y_axis := vec.Vec2[f32]{0, 1}
	x_axis = vec2_rotate_about_point(x_axis, box.rigidbody.rotation, vec.Vec2[f32]{0, 0})
	y_axis = vec2_rotate_about_point(y_axis, -box.rigidbody.rotation, vec.Vec2[f32]{0, 0})

	p := box.rigidbody.position.sub(ray.origin)

	// project direction of ray to each axis
	mut f := vec.Vec2[f32]{x_axis.dot(ray.direction), y_axis.dot(ray.direction)}
	mut e := vec.Vec2[f32]{x_axis.dot(p), y_axis.dot(p)}

	mut tmin := vec.Vec2[f32]{0,0}
	mut tmax := vec.Vec2[f32]{0,0}

	if compare_with_epsilon_float_min(f.x, 0) {
		// if ray x is parallel
		if -e.x - size.x > 0.0 || -e.x + size.x < 0.0 {
			return false
		}
		f.x = math.smallest_non_zero_f32 // Avoid div by 0 NOTE: Try 0.00001
		f.y = math.smallest_non_zero_f32
	}
	tmax.x = e.x + size.x / f.x
	tmax.y = e.y + size.y / f.y

	tmin.x = e.x - size.x / f.x
	tmin.y = e.y - size.y / f.y

	if compare_with_epsilon_float_min(f.y, 0) {
		// if ray y is parallel
		if -e.y - size.y > 0.0 || -e.y + size.y < 0.0 {
			return false
		}
		f.x = math.smallest_non_zero_f32 // Avoid div by 0  NOTE: Try 0.00001
		f.y = math.smallest_non_zero_f32
	}
	tmax.x = e.x + size.x / f.x
	tmax.y = e.y + size.y / f.y

	tmin.x = e.x - size.x / f.x
	tmin.y = e.y - size.y / f.y

	tmin_true_f := math.max[f32](math.min[f32](tmin.x, tmin.y), math.min[f32](tmax.x, tmax.y))
	tmax_true_f := math.min[f32](math.max[f32](tmin.x, tmin.y), math.max[f32](tmax.x, tmax.y))

	t := if tmin_true_f < 0.0 { tmax_true_f } else { tmin_true_f }
	println(tmin)
	println(tmax)
	println(t)
	hit := (t > 0.0) // && t * t < ray.max_distance
	if !hit {
		return false
	}
	point := ray.origin.add(ray.direction.mul_scalar[f32](t))
	normal := ray.origin.sub(point)
	normal.normalize()

	result.init(point, normal, t, true)

	return true
	//return (t > 0.0 && t * t < line.length_squared())
}*/


// --------------------------------------------------
// --- Circle VS Circle ---
// --------------------------------------------------

// circle_meets_circle Returns true if two circles are touching
pub fn circle_meets_circle(c1 Circle, c2 Circle) bool {
	vector_gap := c1.get_center().sub(c2.get_center())
	radius_sum := c1.radius + c2.radius
	return ( (vector_gap.magnitude() * vector_gap.magnitude()) <= radius_sum * radius_sum )
}

// --------------------------------------------------
// --- Circle VS AABB ---
// --------------------------------------------------

// circle_meets_aabb Returns true when a Circle intersects an axis align bounding box(Rectangle)
pub fn circle_meets_aabb(c1 Circle, box AABB) bool {
	min := box.get_min()
	max := box.get_max()

	mut closest_point_to_c1 := c1.get_center()

	if closest_point_to_c1.x < min.x {
		closest_point_to_c1.x = min.x
	}else if closest_point_to_c1.x > max.x {
		closest_point_to_c1.x = max.x
	}

	if closest_point_to_c1.y < min.y {
		closest_point_to_c1.y = min.y
	}else if closest_point_to_c1.y > max.y {
		closest_point_to_c1.y = max.y
	}

	circle_to_box := c1.get_center().sub(closest_point_to_c1)
	return ( circle_to_box.magnitude() * circle_to_box.magnitude() <= c1.radius * c1.radius )
}

// --------------------------------------------------
// --- Circle VS Box2D ---
// --------------------------------------------------

/*
pub fn circle_meets_box2d(c1 Circle, box Box2D) bool {

	// box2d as aabb but rotated
	min := vec.Vec2[f32]{0,0}
	max := box.size

	// circle to local box space

	mut r := c1.get_center().sub(box.position)
	r = vec2_rotate_about_point(r, -box.rotation, vec.Vec2[f32]{0, 0})
	local_circle_pos := r.add(box.half_size)

	mut closest_point_to_c1 := local_circle_pos.copy()
	if closest_point_to_c1.x < min.x {
		closest_point_to_c1.x = min.x
	}else if closest_point_to_c1.x > max.x {
		closest_point_to_c1.x = max.x
	}

	if closest_point_to_c1.y < min.y {
		closest_point_to_c1.y = min.y
	}else if closest_point_to_c1.y > max.y {
		closest_point_to_c1.y = max.y
	}

	circle_to_box := local_circle_pos.sub(closest_point_to_c1)
	println(closest_point_to_c1)
	return ( circle_to_box.magnitude() * circle_to_box.magnitude() < c1.radius * c1.radius )

}
*/

/*
pub fn circle_meets_box2d(c1 Circle, box Box2D) bool {

	// var cx = (Math.cos(rect_angle) * (circle_x - rect_centerX)) - (Math.sin(rect_angle) * (circle_y - rect_centerY)) + rect_centerX;
	// var cy = (Math.sin(rect_angle) * (circle_x - rect_centerX)) + (Math.cos(rect_angle) * (circle_y - rect_centerY)) + rect_centerY;

	rotation := -deg_to_rad(box.rotation)
	cx := (math.cosf(rotation) * (c1.position.x - box.position.x)) - (math.sinf(rotation) * (c1.position.y - box.position.y)) + box.position.x
	cy := (math.sinf(rotation) * (c1.position.x - box.position.x)) + (math.cosf(rotation) * (c1.position.y - box.position.y)) + box.position.y

	mut x := f32(0)
	mut y := f32(0)

	// closest x
	if cx < box.position.x {
		x = box.position.x
	}else if cx > box.position.x + box.half_size.x {
		x = box.position.x + box.half_size.x
	}

	// closest y
	if cy < box.position.y {
		y = box.position.y
	}
	else if cy > box.position.y + box.half_size.y {
		y = box.position.y + box.half_size.y
	} else {
		y = cy
	}

	// is colliding?
	mut collision := false
	distance := vec.vec2[f32](cx, cy).distance(vec.vec2[f32](x, y))

	if distance < c1.radius {
		collision = true
	}else{
		collision = false
	}
	return collision

}
*/

// --------------------------------------------------
// --- Overlap Axis ---
// --------------------------------------------------

pub fn overlap_axis_aabb(box1 AABB, box2 AABB, axis vec.Vec2[f32]) bool {
	interval1 := aabb_vec2_interval(box1, axis)
	interval2 := aabb_vec2_interval(box2, axis)
	return ( interval2.x <= interval1.y && interval1.x <= interval2.y)
}

/*
pub fn overlap_axis_aabb_box2d(box1 AABB, box2 Box2D, axis vec.Vec2[f32]) bool {
	interval1 := aabb_vec2_interval(box1, axis)
	interval2 := box2d_vec2_interval(box2, axis)
	return ( interval2.x <= interval1.y && interval1.x <= interval2.y)
}

pub fn overlap_axis_box2d(box1 Box2D, box2 Box2D, axis vec.Vec2[f32]) bool {
	interval1 := box2d_vec2_interval(box1, axis)
	interval2 := box2d_vec2_interval(box2, axis)
	return ( interval2.x <= interval1.y && interval1.x <= interval2.y)
}
*/

// --------------------------------------------------
// --- AABB Collision ---
// --------------------------------------------------

// aabb_meets_aabb Returns true if two rectangles(AABB) touch
pub fn aabb_meets_aabb(box1 AABB, box2 AABB) bool {
	axis_test := [vec.Vec2[f32]{0, 1}, vec.Vec2[f32]{1, 0}]
	for i:=0; i < axis_test.len; i+=1 {
		if !overlap_axis_aabb(box1, box2, axis_test[i]) {
			return false
		}
	}
	return true
}

/*
pub fn aabb_meets_box2d(box1 AABB, box2 Box2D) bool {
	mut axis_test := [
		vec.Vec2[f32]{0, 1}, vec.Vec2[f32]{1, 0}
		vec.Vec2[f32]{0, 1}, vec.Vec2[f32]{1, 0}
	]
	axis_test[2] = vec2_rotate_about_point(axis_test[2], box2.rotation, box2.position)
	axis_test[3] = vec2_rotate_about_point(axis_test[3], box2.rotation, box2.position)
	for i:=0; i < axis_test.len; i+=1 {
		if !overlap_axis_aabb_box2d(box1, box2, axis_test[i]) {
			return false
		}
	}
	return true
}
*/





