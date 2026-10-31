# Blender (headless) helper for scripts/roblox/import-models.py: glb -> fbx, optionally keeping one named object.
# blender -b --python scripts/roblox/glb2fbx.py -- in.glb out.fbx [ObjectName]
import bpy, sys
args = sys.argv[sys.argv.index("--") + 1:]
src, dst = args[0], args[1]
node = args[2] if len(args) > 2 else None
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
if node:  # keep only one named object (e.g. the staff inside a KayKit character file)
    keep = bpy.data.objects[node]
    mw = keep.matrix_world.copy()
    keep.parent = None
    keep.matrix_world = mw
    for o in list(bpy.data.objects):
        if o is not keep:
            bpy.data.objects.remove(o, do_unlink=True)
    keep.location = (0, 0, 0)
# Rigged models: bake one frame of an idle (else the first) clip into the mesh and drop the skeleton, so the static
# Roblox MeshPart shows a natural pose instead of the T-pose rest pose.
arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
if arms:
    acts = list(bpy.data.actions)
    act = next((a for a in acts if "idle" in a.name.lower()), acts[0] if acts else None)
    for arm in arms:
        if act:
            arm.animation_data_create()
            arm.animation_data.action = act
    bpy.context.scene.frame_set(int(act.frame_range[0]) + 1 if act else 0)
    for o in [o for o in bpy.data.objects if o.type == "MESH"]:
        bpy.context.view_layer.objects.active = o
        for m in list(o.modifiers):
            if m.type == "ARMATURE":
                bpy.ops.object.modifier_apply(modifier=m.name)
        mw = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = mw
    for arm in arms:
        bpy.data.objects.remove(arm, do_unlink=True)
# Quaternius rigs carry a stray "Icosphere" helper mesh (no material) that the glTF viewers never draw: drop it.
for o in [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith("Icosphere") and not o.material_slots]:
    bpy.data.objects.remove(o, do_unlink=True)


# Untextured models (colour per material, or vertex colours; most Quaternius packs): Roblox keeps one texture and no
# vertex colours per MeshPart, so paint every face's colour into a palette texture (8 px swatches so filtering does
# not blend neighbours), UV-map each face onto its swatch and join everything into one mesh with one material.
def textured(mat):
    if mat and mat.use_nodes:
        return any(n.type == "TEX_IMAGE" and n.image for n in mat.node_tree.nodes)
    return False


def base_color(mat):
    if mat and mat.use_nodes:
        for n in mat.node_tree.nodes:
            if n.type == "BSDF_PRINCIPLED" and not n.inputs["Base Color"].is_linked:
                return tuple(n.inputs["Base Color"].default_value)[:3]
    return tuple(mat.diffuse_color)[:3] if mat else (0.8, 0.8, 0.8)


meshes = [o for o in bpy.data.objects if o.type == "MESH"]
all_mats = {s.material for o in meshes for s in o.material_slots if s.material}
if meshes and not any(textured(m) for m in all_mats):
    face_cols = {}  # (object, polygon index) -> rgb
    for o in meshes:
        me = o.data
        attr = me.color_attributes.active_color if me.color_attributes else None
        for poly in me.polygons:
            if attr:
                cs = [attr.data[li if attr.domain == "CORNER" else me.loops[li].vertex_index].color for li in poly.loop_indices]
                rgb = tuple(sum(c[k] for c in cs) / len(cs) for k in range(3))
            else:
                m = o.material_slots[poly.material_index].material if o.material_slots else None
                rgb = base_color(m)
            face_cols[(o.name, poly.index)] = rgb
    step = 1 / 24
    while True:
        q = {k: tuple(round(v / step) * step for v in c) for k, c in face_cols.items()}
        palette = sorted(set(q.values()))
        if len(palette) <= 120:
            break
        step *= 1.5
    SW = 8
    W = max(64, 1 << (len(palette) * SW - 1).bit_length())
    img = bpy.data.images.new("palette", W, SW)
    px = [1.0] * (W * SW * 4)
    for y in range(SW):
        for i, c in enumerate(palette):
            for x in range(i * SW, i * SW + SW):
                j = (y * W + x) * 4
                px[j:j + 3] = [min(1.0, max(0.0, v)) for v in c]
    img.pixels = px
    img.filepath_raw = "//palette.png"
    img.file_format = "PNG"
    img.pack()
    pal = bpy.data.materials.new("Palette")
    pal.use_nodes = True
    nt = pal.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    index = {c: i for i, c in enumerate(palette)}
    for o in meshes:
        me = o.data
        uv = me.uv_layers.new(name="pal")
        me.uv_layers.active = uv
        for poly in me.polygons:
            i = index[q[(o.name, poly.index)]]
            for li in poly.loop_indices:
                uv.data[li].uv = ((i * SW + SW / 2) / W, 0.5)
        for k in [u.name for u in me.uv_layers if u.name != "pal"]:
            me.uv_layers.remove(me.uv_layers[k])
        me.materials.clear()
        me.materials.append(pal)
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
bpy.ops.export_scene.fbx(filepath=dst, path_mode="COPY", embed_textures=True, apply_unit_scale=True, axis_forward="-Z", axis_up="Y")
