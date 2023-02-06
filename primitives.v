module collision2d

import math.vec
//import math

// AABB: Axis Aligned Bounding Box

pub struct AABB {
	pub mut:
		position vec.Vec2[f32]
		center vec.Vec2[f32]
		size vec.Vec2[f32]
		half_size vec.Vec2[f32]
}

/*
pub fn new_aabb(min vec.Vec2[f32], max vec.Vec2[f32]) AABB {
	n_size := max.sub(min)
	n_center := min.add(n_size.mul(vec.Vec2[f32]{0.5, 0.5}))
	return AABB {
		size: n_size
		center: n_center
		half_size: n_size.mul_scalar[f32](0.5)
	}
}
*/
// new_aabb Convenience function that returns a new instance of a AABB struct
pub fn new_aabb(pos vec.Vec2[f32], width f32, height f32) AABB {
	n_size := vec.Vec2[f32]{width, height}
	n_center := n_size.mul_scalar[f32](0.5)
	return AABB {
		position: pos
		size: n_size
		center: n_center
		half_size: n_size.mul_scalar[f32](0.5)
	}
}

// get_min Retrieves the AABB 'min' (|Position| - Half Size) Vec2 - Vec2 Scalar
pub fn (aabb AABB) get_min() vec.Vec2[f32] {
	return aabb.position.sub(aabb.half_size)
}

// get_min Retrieves the AABB 'max' (|Position| + Half Size) Vec2 + Vec2 Scalar
pub fn (aabb AABB) get_max() vec.Vec2[f32] {
	return aabb.position.add(aabb.half_size)
}

// set_size Sets the AABB(Rect) size and calculates size/2 (half_size)
pub fn (mut aabb AABB) set_size(size vec.Vec2[f32]) {
	aabb.size = size
	aabb.half_size = size.mul_scalar[f32](0.5)
}

/* --- Box2D ---

pub struct Box2D {
	pub mut:
		position vec.Vec2[f32]
		rotation f32
		size vec.Vec2[f32]
		half_size vec.Vec2[f32]

}
pub fn new_box2d(min vec.Vec2[f32], max vec.Vec2[f32]) Box2D {
	n_size := max.sub(min)
	return Box2D{
		size: n_size
		half_size: n_size.mul(vec.Vec2[f32]{0.5,0.5})
	}
}
pub fn (box2d Box2D) get_min() vec.Vec2[f32] {
	return box2d.position.sub(box2d.half_size)
}

pub fn (box2d Box2D) get_max() vec.Vec2[f32] {
	return box2d.position.add(box2d.half_size)
}

pub fn (box2d Box2D) get_verticies() []vec.Vec2[f32] {
	min := box2d.get_min()
	max := box2d.get_max()

	mut verts := [
		min,
			vec.Vec2[f32]{min.x, max.y}
			vec.Vec2[f32]{max.x, min.y}
		max
	]

	if box2d.rotation != 0.0 { // TODO: Use compare_with_epsilon_float_min()
		for mut vert in verts {
			vert = vec2_rotate_about_point(vert,box2d.rotation, box2d.position)
		}
	}

	verts_result := [
		verts[0],
		verts[1],
		verts[2],
		verts[3],
	]

	return verts_result
}*/


// --- Circle ---
pub struct Circle {
	pub mut:
		radius f32 = 1.0
		position vec.Vec2[f32]
}

// new_circle Convenience function for creating a circle struct
pub fn new_circle(position vec.Vec2[f32], radius f32) Circle {
	return Circle{
		position: position
		radius: radius
	}
}

// get_center Retrieves the Circle center. Due to having a literal center shape origin, this would be the 'position'
pub fn (circle Circle) get_center() vec.Vec2[f32] {
	return circle.position
}

// --- Line ---

pub struct Line2D {
	pub mut:
		start vec.Vec2[f32]
		end vec.Vec2[f32]
}

// length_squared Returns the length of Line2D squared (|Vector.Magnitude| * |Vector.Magnitude|) V^2
pub fn (line Line2D) length_squared() f32 {
	length := line.end.sub(line.start).magnitude()
	return (length * length)
}
