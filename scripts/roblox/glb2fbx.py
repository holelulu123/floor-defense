# Blender (headless) helper for scripts/roblox/import-models.py: glb -> fbx, optionally keeping one named object.
# blender -b --python scripts/roblox/glb2fbx.py -- in.glb out.fbx [ObjectName]
import bpy, sys, os
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


# Colour: Roblox keeps one texture per MeshPart and drops vertex colours and multi-material colours, so bake each
# model's final base colour (whatever its shader does: flat materials, vertex-colour mixes, textures) into one image
# on fresh UVs with Cycles, and give the joined mesh a single material using it. Models that already use a single
# image texture are left alone.
def single_texture(mats):
    imgs = set()
    for m in mats:
        if not (m and m.use_nodes):
            return False
        found = [n.image for n in m.node_tree.nodes if n.type == "TEX_IMAGE" and n.image]
        if not found:
            return False
        imgs.update(found)
    return len(imgs) == 1


meshes = [o for o in bpy.data.objects if o.type == "MESH"]
all_mats = [s.material for o in meshes for s in o.material_slots if s.material]
if meshes and all_mats:  # always bake: glb-packed textures did not survive the FBX upload either (grey models)
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    me = obj.data
    bake_uv = me.uv_layers.new(name="bake")
    me.uv_layers.active = bake_uv
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    img = bpy.data.images.new("baked", 512, 512)
    for m in all_mats:  # every material bakes into the same image through an unconnected, active image node
        if not m.use_nodes:
            m.use_nodes = True
        nt = m.node_tree
        # Route the material's colour (Principled base colour, or the emission colour of unlit packs) straight into an
        # Emission shader on the output, then bake EMIT: lighting-free and the same for lit, unlit and vertex-colour.
        src_socket, flat = None, tuple(m.diffuse_color)
        for n in nt.nodes:
            if n.type == "BSDF_PRINCIPLED":
                bc = n.inputs["Base Color"]
                src_socket, flat = (bc.links[0].from_socket if bc.is_linked else None), tuple(bc.default_value)
                break
            if n.type == "EMISSION":
                ec = n.inputs["Color"]
                src_socket, flat = (ec.links[0].from_socket if ec.is_linked else None), tuple(ec.default_value)
        out = next((n for n in nt.nodes if n.type == "OUTPUT_MATERIAL"), None) or nt.nodes.new("ShaderNodeOutputMaterial")
        emit = nt.nodes.new("ShaderNodeEmission")
        if src_socket:
            nt.links.new(src_socket, emit.inputs["Color"])
        else:
            emit.inputs["Color"].default_value = flat
        nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
        n = nt.nodes.new("ShaderNodeTexImage")
        n.image = img
        nt.nodes.active = n
        # keep the shader reading its own UV map (the active layer is now "bake")
        for t in [t for t in nt.nodes if t.type == "TEX_IMAGE" and t.image and t.image is not img]:
            if not t.inputs["Vector"].is_linked:
                uvn = nt.nodes.new("ShaderNodeUVMap")
                uvn.uv_map = next((u.name for u in me.uv_layers if u.name != "bake"), "")
                nt.links.new(uvn.outputs["UV"], t.inputs["Vector"])
    scn = bpy.context.scene
    scn.render.engine = "CYCLES"
    scn.cycles.device = "CPU"
    scn.cycles.samples = 1
    scn.render.bake.margin = 4
    bpy.ops.object.bake(type="EMIT")
    # A real file next to the output, so the FBX exporter embeds it (a packed generated image was dropped).
    img.filepath_raw = os.path.splitext(dst)[0] + "_baked.png"
    img.file_format = "PNG"
    img.save()
    for k in [u.name for u in me.uv_layers if u.name != "bake"]:
        me.uv_layers.remove(me.uv_layers[k])
    mat = bpy.data.materials.new("Baked")
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = img
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    me.materials.clear()
    me.materials.append(mat)
    px = list(img.pixels[: 4 * 512 * 64])
    avg = [sum(px[i::4]) / (len(px) / 4) for i in range(3)]
    print("BAKED avg colour (first rows)", [round(v, 2) for v in avg])
bpy.ops.export_scene.fbx(filepath=dst, path_mode="COPY", embed_textures=True, apply_unit_scale=True, axis_forward="-Z", axis_up="Y")
