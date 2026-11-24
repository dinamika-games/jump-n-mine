class_name EffectLayer
extends Node2D

## A layer which draws with a shader (e.g., the gas or the explosions): it
## calls [member paint] to draw, and the shader of its material colors each
## rectangle; the parameters of a rectangle travel in its modulate color (see
## the shaders in scenes/effects/).

## Draw the layer: called with the layer as the canvas.
var paint: Callable

var _white: ImageTexture = null


func _init(shader_path: String) -> void:
    var material_now := ShaderMaterial.new()
    material_now.shader = load(shader_path)
    material = material_now


## A white texture for the rectangles of the shaders.
func white() -> Texture2D:
    if _white == null:
        var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
        image.fill(Color.WHITE)
        _white = ImageTexture.create_from_image(image)
    return _white


func _process(_delta: float) -> void:
    queue_redraw()


func _draw() -> void:
    if paint.is_valid():
        paint.call(self)
