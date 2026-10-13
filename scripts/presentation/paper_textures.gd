class_name PaperTextures
extends RefCounted

## Generated paper grain and a reusable cutout figure. Not finished artwork.

static var _fiber: ImageTexture

static func fiber() -> ImageTexture:
	if _fiber != null:
		return _fiber
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 14071
	for y in 128:
		for x in 128:
			var shade := rng.randf_range(0.84, 1.0)
			if (x + int(y * 0.2)) % 19 == 0:
				shade *= 0.88
			image.set_pixel(x, y, Color(shade, shade, shade))
	_fiber = ImageTexture.create_from_image(image)
	return _fiber

static func figure(face: Color, ink: Color) -> ImageTexture:
	var image := Image.create(96, 160, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_fill_rect(image, ink, 30, 10, 66, 50)
	_fill_rect(image, face, 34, 14, 62, 46)
	_fill_rect(image, ink, 24, 48, 72, 118)
	_fill_rect(image, face, 28, 52, 68, 114)
	_fill_rect(image, ink, 26, 112, 46, 154)
	_fill_rect(image, face, 30, 112, 42, 150)
	_fill_rect(image, ink, 50, 112, 70, 154)
	_fill_rect(image, face, 54, 112, 66, 150)
	_fill_rect(image, ink, 40, 26, 46, 32)
	_fill_rect(image, ink, 54, 26, 60, 32)
	return ImageTexture.create_from_image(image)

static func _fill_rect(image: Image, color: Color, x0: int, y0: int, x1: int, y1: int) -> void:
	for y in range(y0, y1):
		for x in range(x0, x1):
			image.set_pixel(x, y, color)
