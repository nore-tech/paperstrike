class_name PaperMaterial
extends Resource

## Shared paper or cardboard surface. Build a material per mesh so one flash cannot tint every surface.

@export var albedo := Color(0.93, 0.89, 0.82, 1)
@export var roughness := 0.94
@export var uv_scale := Vector3(2, 2, 2)

func build() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.albedo_texture = PaperTextures.fiber()
	material.roughness = roughness
	material.metallic = 0.0
	material.metallic_specular = 0.12
	material.uv1_scale = uv_scale
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return material
