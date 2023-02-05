module collision2d

import math.vec
import math

fn deg_to_rad(degrees f32) f32 {
	pi := f32(math.pi)
	return (pi / 180.0) * degrees
}

fn vec2_rotate_about_point(v2d vec.Vec2[f32], angle_deg f32, origin vec.Vec2[f32]) vec.Vec2[f32] {
	xx := v2d.x - origin.x
	yy := v2d.y - origin.y

	cos := f32(math.cosf(deg_to_rad(angle_deg)))
	sin := f32(math.sinf(deg_to_rad(angle_deg)))
	mut x_prime := (xx * cos) - (yy * sin)
	mut y_prime := (xx * sin) - (yy * cos)

	x_prime += origin.x
	y_prime += origin.y

	return vec.Vec2[f32]{x_prime, y_prime}
}

fn compare_with_epsilon(x f32, y f32, epsilon f32) bool {
	// Here be dragons
	return (math.abs(x - y) <= epsilon * math.max[f32](1.0, math.max[f32](math.abs(x), math.abs(y))))
}

fn compare_with_epsilon_vec2(vec_1 vec.Vec2[f32], vec_2 vec.Vec2[f32], epsilon f32) bool {
	return ( compare_with_epsilon(vec_1.x, vec_2.x, epsilon) && compare_with_epsilon(vec_1.y, vec_2.y, epsilon) )
}

fn compare_with_epsilon_float_min(x f32, y f32) bool {
	return compare_with_epsilon(x, y, math.smallest_non_zero_f32)
}

// --- Simpler min/max f32 functions. Stringing together math.max[f32]/min[f32] gets wild

fn minf(x f32, y f32) f32 {
	return math.min[f32](x, y)
}

fn maxf(x f32, y f32) f32 {
	return math.max[f32](x, y)
}

fn aabb_vec2_interval(box AABB, axis vec.Vec2[f32]) vec.Vec2[f32] {
	mut result := vec.Vec2[f32]{0, 0}
	min := box.get_min()
	max := box.get_max()
	verts := [
		min,
			vec.Vec2[f32]{min.x, max.y}
			vec.Vec2[f32]{max.x, min.y}
		max
	]

	result.x = axis.dot(verts[0])
	result.y = result.x

	for i := 0; i < 4; i+=1 {
		project := axis.dot(verts[i])
		if project < result.x {
			result.x = project
		}
		if project > result.y {
			result.y = project
		}
	}

	return result

}

fn box2d_vec2_interval(box Box2D, axis vec.Vec2[f32]) vec.Vec2[f32] {
	mut result := vec.Vec2[f32]{0, 0}
	min := box.get_min()
	max := box.get_max()
	verts := box.get_verticies()

	result.x = axis.dot(verts[0])
	result.y = result.x

	for i := 0; i < 4; i+=1 {
		project := axis.dot(verts[i])
		if project < result.x {
			result.x = project
		}
		if project > result.y {
			result.y = project
		}
	}

	return result

}
