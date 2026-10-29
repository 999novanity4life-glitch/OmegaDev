# claude.ai connector registry check (SearchMcpRegistry, run 2026-10-29 by coordinator)

Searches run: "figma/design/UI mockup", "3D model/blender/game development", "image generation/texture/art", "unity/unreal/roblox", "meshy/3D generation/sketchfab/asset library", "icons/illustration/image editing/photoshop".

Relevant connectors that EXIST in the claude.ai directory (all currently not_installed for this user):
- Figma — "Generate diagrams and better code from Figma context". Tools: generate_diagram, get_design_context, get_screenshot, get_metadata, create_design_system_rules, get_variable_defs, get_code_connect_map, get_figjam (+1). Requires sign-in (not authless).
- Adobe — "Design, combine, and edit with Adobe pro tools". 100+ tools incl. animate_design, asset_add_file, asset_create_folders, acrobat... Requires sign-in.
- Canva — search/create/autofill/export Canva designs. Requires sign-in.
- Trimble SketchUp — "Create and iterate 3D models for use in SketchUp". Tools: build_model, get_docs, save_model.
- Wonder — "Create and edit designs with Claude on a canvas where every design is real code."
- Magic Patterns — get_design, read_files, update_design (UI prototyping).
- Moda — slides/designs/motion graphics (marketing oriented).
- Unsplash — free HD photo search (reference images).
- Mermaid Chart (authless) — diagrams; not relevant to art.

NOT found in the claude.ai directory: any Blender, Unity, Unreal, Godot, Roblox, Meshy, Tripo, Sketchfab, Substance, image-generation (e.g. Midjourney/Stable Diffusion/Scenario) connector. Those must be added as local MCP servers (Claude Code / Claude desktop on the Mac) instead.

Already in use in this project (per project memory, not from registry): Roblox Studio built-in MCP on Pranay's Mac exposing tools incl. execute_luau, generate_mesh, generate_material, generate_texture, generate_procedural_model, segment_mesh, insert_asset, search_asset, screen_capture, upload_image, store_image, start_stop_play, get_console_output, character_navigation, user_mouse_input/keyboard_input, subagent, skill. Blender (bpy) scripting also used on the Mac.
