# TRPG Map Editor — Agent Prompts for All 8 Phases

Each prompt below is self-contained and can be handed directly to a development agent.
The project uses **Godot 4.x + GDScript**, targeting Windows/Linux/macOS/Android.

---

## Phase 0 — Project Infrastructure (1–2 weeks)

```
You are building Phase 0 of a TRPG (Tabletop Role-Playing Game) 2D Map Editor in Godot 4.x with GDScript.

CONTEXT:
This is the first phase of an independent map editor that will later become the map component of a full TRPG platform. You are scaffolding the project: folder structure, core data models, basic UI framework, minimal tile editing, and file save/load.

DELIVERABLES:

1. Godot 4.x project
   - Configure autoload singletons: EventBus, ConfigManager, UndoRedoManager.
   - Set window base resolution to 1920×1080, allow resize.

2. Directory structure
   ```
   trpg-map-editor/
   ├── project.godot
   ├── assets/  (tilesets/, sprites/, shaders/, fonts/, icons/, themes/)
   ├── scenes/  (editor/, map/, dialogs/)
   ├── scripts/ (autoload/, core/, data/, serialization/, rendering/, tools/, ui/)
   ├── tests/   (unit/, integration/)
   ├── example_maps/
   └── docs/
   ```
   Create placeholder .gdignore files inside assets/ subdirectories so Godot imports them correctly.

3. Autoload — EventBus (scripts/autoload/event_bus.gd)
   - Define all signals listed below as a single Node-based autoload:
     - map_loaded, map_saved, floor_changed, floor_added, floor_removed
     - tile_placed, tile_removed, object_placed, object_removed
     - portal_created, portal_teleported
     - obstacle_placed, obstacle_updated, obstacle_removed
     - fog_updated, visibility_changed, light_source_updated
     - selection_changed

4. Autoload — ConfigManager (scripts/autoload/config_manager.gd)
   - Persistent key-value config store backed by a JSON file in user://config.json.
   - Methods: get_value(key, default), set_value(key, value), save(), load().
   - Load config automatically in _ready().

5. Autoload — UndoRedoManager (scripts/autoload/undo_redo_manager.gd)
   - Command pattern with an inner `Command` class (execute, undo, get_description).
   - Max undo stack depth: 100.
   - Methods: execute_command(cmd), undo(), redo().
   - Provide at least one concrete command: PlaceTileCommand.
   - Clear redo stack when a new command is executed.

6. Core data models (scripts/data/) — implement these Resource classes:
   - `MapData` — map_name, map_version, author, created_date, modified_date, description, grid_size (Vector2i default 32,32), map_dimensions (Vector2i default 100,100), grid_type enum (SQUARE/HEX_POINTY/HEX_FLAT), coordinate_system enum (OFFSET/AXIAL/CUBE), floors array, current_floor, portals array, light_sources array, fog_of_war array, vision_tokens array, tilesets array.
   - `FloorData` — floor_index, floor_name, floor_z, elevation, visible, locked, opacity, tint_color, terrain_layers array, objects array, walls array, floor_portals array, floor_lights array, fog_data.
   - `TerrainLayerData` — layer_name, layer_index, visible, locked, opacity, tileset_ref, tiles (Dictionary of Vector2i→tile_data).
   - `MapObjectData` — object_id, object_type, display_name, position, grid_position, rotation, scale, sprite_path, z_index, collision_shape enum, custom_properties.
   - `WallSegmentData` — segment_id, start_point, end_point, wall_type enum (SOLID/WINDOW/BARS/ILLUSION/HALF_HEIGHT/TRANSPARENT), height, thickness, block_flags (bit flags).
   - `PortalData` — portal_id, portal_name, source_floor, source_position, source_size, target_floor, target_position, target_map, is_bidirectional, is_active, visual_color, label_visible, label_text, trigger_type enum.
   - `LightData` — light_id, light_name, floor_index, position, grid_position, light_type enum (POINT/CONE/DIRECTIONAL/AMBIENT), intensity, color, radius, falloff, inner_angle, outer_angle, rotation, is_static, is_dynamic, flicker_enabled, flicker_speed, flicker_amount.
   - `FogData` — enabled, fog_type enum (NONE/GLOBAL/DYNAMIC/REVEALED), fog_color, unexplored_color, explored_color, fog_transition_speed, fog_grid (Dictionary), token_revealed (Dictionary).
   - `VisionTokenData` — token_id, token_name, floor_index, position, grid_position, vision_range, vision_arc, facing_angle, darkvision_range, low_light_multiplier, visible_cells, explored_cells, vision_height, can_see_invisible, is_player_controlled, owner_player_id.

7. Base UI framework (scenes/editor/map_editor.tscn)
   - A Control-rooted scene with these child containers (use MarginContainer, HBoxContainer, VBoxContainer, Panel):
     - MenuBar at top (File: New/Open/Save/SaveAs/Exit; Edit: Undo/Redo; View: ZoomIn/ZoomOut/ResetZoom; Help: About).
     - ToolBar (left side, vertical): placeholder icon buttons for Select, Brush, Line, Rect, Fill, Eraser, Wall, Portal, Light, Fog, Token, Measure tools. Each emits a signal via EventBus when selected.
     - Map editing area (center): a SubViewportContainer wrapping a SubViewport containing a Node2D root for map rendering.
     - LayerPanel (right, upper): a VBoxContainer with a tree/list showing layers, checkboxes for visibility/lock toggle, opacity slider, add/remove layer buttons.
     - TilePalette (right, lower): placeholder panel that will later host tile selection.
     - StatusBar (bottom): Label showing current grid position, zoom level, active tool name.
   All panels should have minimum reasonable sizes.

8. Grid rendering (scripts/rendering/grid_renderer.gd)
   - A Node2D that draws grid lines using draw_line() in _draw().
   - Configurable grid_size (pixels), grid color, line width.
   - Must support camera pan (middle-mouse drag or arrow keys) and zoom (mouse wheel, centered on cursor).
   - Clamp zoom between 0.25x and 4x.

9. Basic TileMap editing
   - Implement Brush tool: click on grid to place a tile (use a solid colored Rect2 as placeholder tile).
   - Implement Eraser tool: click to remove a tile.
   - Tiles are stored in the active TerrainLayerData.tiles dictionary.
   - Emit tile_placed / tile_removed signals on EventBus.

10. Layer management
    - Add/remove/reorder layers via the LayerPanel.
    - Toggle visibility and lock per layer.
    - Adjust opacity per layer.
    - Active layer is highlighted.

11. File save (.trpgmap format v1)
    - Save MapData to a JSON file via SerializationManager.
    - Serialize all fields from MapData, FloorData, TerrainLayerData.
    - Use JSON.stringify with proper indentation.
    - File extension: .trpgmap.

12. File open
    - Parse .trpgmap JSON back into MapData.
    - Emit map_loaded signal.
    - Rebuild the editor view from loaded data.

13. Unit test setup — GUT (Godot Unit Test)
    - Install GUT addon.
    - Create a test runner scene.
    - Write at least one passing test for MapData serialization round-trip.

TECHNICAL REQUIREMENTS:
- Godot 4.x (latest stable).
- GDScript only, no C#.
- All scripts use `class_name` where they define a reusable class.
- Signals go through the EventBus autoload; subsystems do NOT directly reference each other.
- Use `@export` for all serializable properties.
- Coordinate system: world coordinates are pixel-based, grid coordinates are cell-index-based. Grid origin is top-left.
- No external dependencies beyond Godot built-ins and GUT.

ACCEPTANCE CRITERIA:
- Godot project opens without errors.
- The editor loads with MenuBar, ToolBar, LayerPanel, TilePalette, StatusBar, and a zoomable/pannable grid view.
- Clicking Brush then clicking the grid places a placeholder tile; Eraser removes it.
- Layers can be added, removed, reordered, shown/hidden, locked/unlocked.
- Save creates a valid .trpgmap JSON file; Open reloads it correctly and restores placed tiles.
- GUT test for MapData serialization passes.
```

---

## Phase 1 — Core Map Editing & Floor System (3–4 weeks)

```
You are building Phase 1 of a TRPG 2D Map Editor in Godot 4.x with GDScript. Phase 0 (project scaffold) is already complete: the project has autoload singletons (EventBus, ConfigManager, UndoRedoManager), all core data models (MapData, FloorData, TerrainLayerData, etc.), a base UI framework with zoomable/pannable grid, basic brush/eraser tile editing, layer panel, and .trpgmap file save/load.

CONTEXT:
Phase 1 focuses on maturing the editing experience: multiple tile placement modes, object placement, wall editor, the full floor management system, hex grid support, clipboard, and undo/redo integration.

DELIVERABLES:

1. Enhanced TileMap editing modes (scripts/tools/brush_tool.gd)
   - Single-cell mode: click to place one tile (already exists, polish it).
   - Line mode: click start cell, click end cell, tiles fill the Bresenham line between them.
   - Rectangle mode: click start cell, drag to end cell, tiles fill the rectangular area.
   - Fill mode (flood-fill): click a cell, all contiguous same-or-empty cells within the current layer get filled with the selected tile.
   - Shift+click with Brush to sample the tile under the cursor.
   - Visual preview: before confirming placement, show a semi-transparent preview of the tiles that will be placed.

2. Tool system refactoring (scripts/tools/)
   - Define a `BaseTool` class with virtual methods: on_activate(), on_deactivate(), on_mouse_pressed(pos, button), on_mouse_moved(pos), on_mouse_released(pos), on_key_pressed(event).
   - Implement these concrete tools inheriting BaseTool:
     - SelectTool — click to select, drag to move selected items.
     - BrushTool — single/line/rect/fill modes.
     - EraserTool — click or drag to erase.
     - WallTool — click to place wall start, click to place wall end (see #4).
     - PortalTool — click to place portal (stub, full implementation in Phase 2).
     - LightTool — click to place light source (stub, full implementation in Phase 4).
   - The active tool is set via ToolBar and managed by a ToolManager.
   - Each tool change emits EventBus.selection_changed.

3. Object placement system (scripts/tools/object_tool.gd)
   - Place MapObjectData instances on the map.
   - Objects render as Sprite2D (use a colored rectangle as placeholder sprite).
   - SelectTool can select objects: show a selection rectangle with resize/rotate handles.
   - PropertyInspector (scenes/editor/property_inspector.tscn) shows editable fields when an object is selected: name, type, position, rotation, scale, z_index, collision shape, custom properties (key-value editor).
   - Objects are stored in the current FloorData.objects array.

4. Wall editor (scripts/tools/wall_tool.gd)
   - WallTool: click a grid cell to set wall start_point, click another to set end_point.
   - While dragging, show a preview line from start to cursor.
   - Walls are stored per floor in FloorData.walls as WallSegmentData.
   - WallRenderer (scripts/rendering/wall_renderer.gd): draw walls as colored lines with configurable thickness. Different wall types have different visual styles:
     - SOLID: thick dark line.
     - WINDOW: dashed line with gap markers.
     - BARS: thin parallel lines.
     - ILLUSION: dotted semi-transparent line.
     - HALF_HEIGHT: medium line with height label.
     - TRANSPARENT: very faint line.
   - SelectTool can select walls: show endpoint handles for dragging.

5. Floor management system (scripts/core/floor_manager.gd)
   - FloorManager signals: floor_switch_start, floor_switch_complete.
   - Methods:
     - add_floor(name) → creates a new FloorData at the end.
     - remove_floor(index) → removes and cleans up.
     - duplicate_floor(index) → deep-copies the floor at index.
     - switch_to_floor(index, transition_type) → changes active floor.
     - reorder_floors(from_index, to_index).
   - Transition types: INSTANT (immediate swap), FADE (brief darken then show new floor).
   - When switching floors, save current floor state, then load target floor's terrain layers, objects, and walls into the viewport.
   - MapData.current_floor tracks the active floor index.

6. Floor selector UI (scenes/editor/floor_selector.tscn)
   - Vertical list of floor entries, each showing:
     - Floor name (editable by double-click).
     - Mini thumbnail preview (render a downscaled snapshot of the floor).
   - Current floor highlighted.
   - Buttons: Add Floor, Duplicate Floor, Delete Floor, Move Up, Move Down.
   - Checkbox: "Show adjacent floors" — when checked, the floors above/below render with reduced opacity (configurable slider 10%–50%).

7. Stair connection definition (scripts/data/stair_connection.gd)
   - A Resource class: from_floor, from_position, to_floor, to_position, stair_type enum (STAIRS/LADDER_UP/LADDER_DOWN/SHAFT/RAMP).
   - Stair connections are stored in MapData.
   - In the floor selector, stair connections are shown as linked indicators between floor entries.
   - Placing a stair: select Stair tool, click source cell on current floor, choose target floor from a popup, click target cell.

8. Hex grid support
   - GridRenderer must support three grid types: SQUARE, HEX_POINTY, HEX_FLAT.
   - Draw hex outlines using draw_polyline() for hexes.
   - Grid coordinate conversion functions in a GridUtils helper:
     - grid_to_world(grid_pos, grid_type) → Vector2
     - world_to_grid(world_pos, grid_type) → Vector2i
     - For hex: implement offset-to-axial and axial-to-offset conversions.
   - Grid type is stored in MapData.grid_type, settable in New Map dialog.
   - Corner/edge neighbors for hexes in a `get_neighbors(cell, grid_type)` function.

9. Undo/Redo integration
   - Create concrete Command subclasses for every edit action:
     - PlaceTileCommand, RemoveTileCommand
     - PlaceObjectCommand, RemoveObjectCommand, MoveObjectCommand
     - PlaceWallCommand, RemoveWallCommand, MoveWallEndpointCommand
     - AddLayerCommand, RemoveLayerCommand, ReorderLayerCommand
     - AddFloorCommand, RemoveFloorCommand
   - Bind Ctrl+Z / Ctrl+Y (Cmd+Z / Cmd+Shift+Z on macOS) to UndoRedoManager.undo() / redo().
   - MenuBar Edit→Undo and Edit→Redo call these as well.
   - The undo description should be human-readable (e.g., "Placed tile at (5, 10)").

10. Clipboard system
    - Copy (Ctrl+C): store selected tiles/objects/walls in a serializable ClipboardData structure.
    - Paste (Ctrl+V): paste at cursor position, offset so the top-left of the copied region aligns to the cell under the cursor.
    - Cut (Ctrl+X): copy then delete originals.
    - Clipboard holds: tiles (Dictionary of relative Vector2i→tile_data), objects (Array of MapObjectData with adjusted relative positions), walls (Array of WallSegmentData with adjusted relative endpoints).
    - Show paste preview before committing.

11. Snap-to-grid
    - Objects and wall endpoints snap to the nearest grid intersection or cell center (configurable).
    - Hold Shift to temporarily disable snapping.
    - Snap setting stored in ConfigManager.

12. New Map dialog (scenes/dialogs/new_map_dialog.tscn)
    - Fields: map name, author, description, grid type (dropdown), grid size (pixels), map width (cells), map height (cells), initial floor name.
    - Creates a MapData with one FloorData containing one default TerrainLayerData.
    - Opens the new map in the editor.

13. Extend .trpgmap format
    - Serialize all new data: objects, walls, floor metadata, grid type, stair connections.
    - Maintain backward compatibility with Phase 0 .trpgmap files (missing fields get defaults).

TECHNICAL REQUIREMENTS:
- All edit actions go through UndoRedoManager.
- FloorData.objects and FloorData.walls are the single source of truth per floor.
- The rendering in the viewport reflects exactly what is in the data model at all times.
- Coordinate conversions go through GridUtils, never inline math.
- Camera pan/zoom from Phase 0 must continue to work.

ACCEPTANCE CRITERIA:
- Can place tiles in single, line, rectangle, and fill modes with undo/redo for each.
- Can place objects, select them, move them, and edit their properties.
- Can draw walls between two cells; wall type is selectable and rendered distinctly.
- Can add/remove/duplicate/reorder floors; switching floors updates the viewport correctly.
- Can see floor thumbnails in the floor selector.
- Can define stair connections between floors.
- Hex grid renders correctly and tile placement works on hex cells.
- Copy/Paste/Cut work for tiles, objects, and walls.
- New Map dialog creates a valid new map.
- Save and Open work with the extended format; Phase 0 files still open correctly.
```

---

## Phase 2 — Portal System & Obstacle System (2–3 weeks)

```
You are building Phase 2 of a TRPG 2D Map Editor in Godot 4.x with GDScript. Phase 1 is complete: the editor has full tile editing (single/line/rect/fill modes), object placement with property inspector, wall drawing with type rendering, floor management (add/copy/remove/switch with thumbnails), stair connections, hex grid support, undo/redo for all edits, clipboard, and snap-to-grid.

CONTEXT:
Phase 2 adds two subsystems: the Portal system (in-map teleporters that can cross floors or reference external maps) and the extended Obstacle system (bit-flag-based blocking properties on walls and objects, plus projectile trajectory tools).

DELIVERABLES:

1. Portal data & manager (scripts/core/portal_manager.gd)
   - PortalManager extends Node, registered under MapCoreManager.
   - Internal registry: Dictionary of portal_id → PortalData.
   - Portal pairing: Dictionary of portal_id → destination_portal_id.
   - Methods:
     - register_portal(portal: PortalData) — add to registry.
     - unregister_portal(portal_id: String) — remove and clean up pairings.
     - create_pair(portal_a_id, portal_b_id) — establish bidirectional or unidirectional link.
     - get_destination(portal_id) → PortalData or null.
     - execute_teleport(token: VisionTokenData, portal_id) → void — update token position/floor, emit portal_activated.
   - Signals: portal_activated(portal_id, trigger_token_id).

2. Portal placement tool (scripts/tools/portal_tool.gd)
   - Click a cell to place a portal footprint (default 1×1, resizable by dragging handles).
   - After placing source, a dialog or side-panel prompts for target: target floor, target position, target map (file path or blank for same map).
   - On confirm, create PortalData and register with PortalManager.
   - PortalTool emits EventBus.portal_created.

3. Portal renderer (scripts/rendering/portal_renderer.gd)
   - Extends Node2D, attached to PortalLayer in the scene tree.
   - For each portal, render:
     - A colored dashed rectangle (visual_color).
     - Semi-transparent fill with a subtle shimmer/ripple animation (use a shader or animate alpha).
     - Direction arrow(s) indicating one-way or two-way.
     - Floating label above the portal area (label_text).
   - In editor mode, draw a dotted connection line between paired portals, even across floors (show a curved line with an arrowhead).

4. Portal property inspector
   - When a portal is selected, show in PropertyInspector:
     - Name, Source Floor, Source Position, Source Size (width×height in cells).
     - Target Floor, Target Position, Target Map (file picker).
     - Bidirectional toggle.
     - Trigger type dropdown (WALK_ON / INTERACT / AUTOMATIC).
     - Visual color picker.
     - Label text and label visibility toggle.
     - Active toggle.
   - Changes update the portal renderer in real time.

5. Portal list panel
   - A dockable panel or tab showing all portals in the map as a table.
   - Columns: Name, Source (floor + position), Target (floor + position + map), Type (1-way/2-way), Active.
   - Click a row to select and focus the viewport on that portal.
   - Delete button to remove a portal.

6. Cross-map portal support
   - If target_map is not empty, the portal references an external .trpgmap file.
   - In the editor, show the external map reference as a colored icon on the portal.
   - The actual cross-map loading logic can be stubbed (it will be used at runtime by the full platform).

7. Obstacle flags — extend WallSegmentData and MapObjectData
   - Ensure block_flags on WallSegmentData uses the bit flags from ObstacleFlags:
     - BLOCK_VISION (1), BLOCK_LIGHT (2), BLOCK_PROJECTILE (4), BLOCK_MOVEMENT (8), BLOCK_FLYING (16), BLOCK_BURROWING (32).
   - Add block_flags to MapObjectData with default NONE.
   - Create ObstacleProperties resource: height, thickness, material_type enum (WOOD/STONE/METAL/GLASS/FORCE/ORGANIC), projectile_deflection, wall_ac, wall_hp, hardness.
   - Attach ObstacleProperties to WallSegmentData.

8. Obstacle visualization overlay
   - A debug/editor overlay that color-codes cells based on blocking properties:
     - Red tint: blocks vision.
     - Yellow tint: blocks light.
     - Blue tint: blocks projectiles.
     - Dark overlay: blocks movement.
   - Toggle overlay from View menu or a toolbar button.
   - Opacity of the overlay is adjustable.

9. Wall property inspector (enhanced)
   - When a wall is selected, show the full property set:
     - Wall type dropdown with visual preview icons.
     - Start/End positions (editable spinboxes).
     - Height (float), Thickness (int).
     - Checkboxes for each block flag.
     - Material type dropdown.
     - AC, HP, Hardness spinboxes.
     - Projectile deflection slider (0.0–1.0).
   - Changes update the wall renderer and obstacle overlay in real time.

10. Projectile trajectory preview tool (scripts/tools/measurement_tool.gd, extended)
    - MeasurementTool gets a "projectile mode" toggle.
    - In projectile mode: click origin cell, set launch height and velocity (or use defaults), click target cell.
    - The tool computes and draws the parabolic arc as a series of points.
    - If the arc intersects any obstacle with BLOCK_PROJECTILE, show the intersection point in red and stop the arc there.
    - Display arc parameters in StatusBar: max height, time of flight, impact point.
    - Use the projectile calculation provided in the design doc (gravity-based step simulation).

11. Object collision shapes
    - Complete the collision_shape implementation on MapObjectData:
      - RECTANGLE: define width/height in cells.
      - CIRCLE: define radius in cells.
      - POLYGON: define a custom polygon (editor: click to add vertices, drag to adjust).
      - GRID_FILL: fill the entire cell(s) the object occupies.
    - Render collision shapes as semi-transparent outlines in the editor overlay.
    - Collision shapes participate in obstacle blocking (if BLOCK_MOVEMENT or other flags are set).

12. Area selection tool improvements
    - SelectTool in area mode: drag to select all tiles, objects, and walls within a rectangle.
    - Multi-select: hold Ctrl to add to selection.
    - Move all selected items together.
    - The PropertyInspector shows common properties when multiple items are selected (or shows count + types).

TECHNICAL REQUIREMENTS:
- Portal teleport logic must handle floor switching via EventBus.floor_changed.
- All portal changes go through UndoRedoManager (CreatePortalCommand, RemovePortalCommand, EditPortalCommand).
- Obstacle flag checks use bitwise AND, never integer equality.
- The obstacle overlay is a separate CanvasItem layer rendered on top of the map.
- Projectile preview is purely visual/debug; it does not modify map data.

ACCEPTANCE CRITERIA:
- Can place a portal on floor A, set destination to floor B, and the connection line is visible in the editor.
- Portal renders with ripple animation, label, and direction arrow.
- Portal list panel shows all portals; clicking one focuses the viewport on it.
- Obstacle overlay toggles and correctly shows which cells block vision/light/projectiles/movement.
- Wall property inspector shows all obstacle properties; changes reflect immediately in the overlay.
- Projectile tool draws a parabolic arc and correctly stops at walls with BLOCK_PROJECTILE.
- Object collision shapes render and can be edited.
- Multi-select and area-select work for tiles, objects, and walls.
```

---

## Phase 3 — Fog of War & Vision System (3–4 weeks)

```
You are building Phase 3 of a TRPG 2D Map Editor in Godot 4.x with GDScript. Previous phases are complete: the editor has full tile/object/wall editing, floor management with thumbnails, portal placement with cross-floor pairing and ripple animation, obstacle bit-flag system with overlay visualization, and projectile trajectory preview.

CONTEXT:
Phase 3 is the most algorithmically intensive phase. It implements the Recursive Shadowcasting vision algorithm, the dynamic fog-of-war system (3 modes: None, Global, Dynamic Revealed), Vision Token management, and a player-perspective Preview mode. This phase directly enables the core TRPG experience of hidden/revealed maps.

DELIVERABLES:

1. Recursive Shadowcasting implementation (scripts/core/vision_manager.gd)
   - Implement as a RefCounted utility class (no Node dependency).
   - Entry point: `static func calculate_visibility(data: ShadowCastData) -> Array[Vector2i]`.
   - ShadowCastData inner class holds: origin (Vector2i), range (int), obstacle_check Callable (func(cell)→bool), visit_cell Callable, arc_start (float radians), arc_width (float radians, default TAU).
   - Implement `_cast_octant()` for all 8 octants with the transform table provided in the design doc.
   - The origin cell is always visible.
   - A cell is blocked if `obstacle_check.call(cell)` returns true.
   - Correctly handle the slope narrowing when a blocking cell is encountered.
   - Unit test: write tests/unit/test_vision_manager.gd with these cases:
     - Empty room: all cells within range are visible.
     - Single wall in front: cells behind the wall are not visible.
     - Diagonal wall: correct shadow casting at an angle.
     - Range limit: cells beyond range are not visible.
     - Arc restriction: only cells within the arc are visible.

2. Fog of War — FogManager (scripts/core/fog_manager.gd)
   - Extends Node2D, attached to FogLayer.
   - Fog data stored per floor in FloorData.fog_data (FogData resource).
   - Three fog modes:
     a) NONE: fog disabled, entire map visible. FogLayer is hidden.
     b) GLOBAL: fog enabled, fog_grid determines per-cell state (0=UNKNOWN, 1=EXPLORED, 2=VISIBLE). GM manually sets which cells are visible via the FogTool. Does not update automatically from token movement.
     c) DYNAMIC / REVEALED: standard TRPG mode. Initial state: all UNKNOWN. Token visibility updates cells to VISIBLE. When a cell leaves visibility, it transitions to EXPLORED (terrain visible but objects/dynamic elements hidden).
   - Fog cell state enum: UNKNOWN (opaque black), EXPLORED (semi-transparent dark, terrain shows through), VISIBLE (fully transparent, everything visible).
   - Fog rendering approach:
     - Create an Image of map dimensions, set each pixel based on fog_grid state.
     - Convert to ImageTexture and draw as a full-map overlay using draw_texture_rect().
     - Use `_dirty` flag to avoid re-rendering every frame.

3. Fog update logic
   - `update_visibility(token_positions: Array[Vector2i])`: 
     - Record previous visible cells.
     - Compute new visible cells (via VisionManager for each token, union the results).
     - For each newly visible cell: set fog_grid[cell] = VISIBLE.
     - For each previously-visible-but-no-longer-visible cell: if it was VISIBLE, set to EXPLORED.
     - Mark fog dirty for re-render.
   - Optimize: only recompute visibility for tokens that have moved. Cache visibility per token position.
   - FogManager listens to EventBus.visibility_changed and EventBus.floor_changed.

4. Fog editor tool (scripts/tools/fog_tool.gd)
   - FogTool modes (cycle with right-click or toolbar sub-options):
     - Reveal: paint cells as VISIBLE (brush).
     - Hide: paint cells as UNKNOWN.
     - Explore: paint cells as EXPLORED.
     - Clear all fog on current floor.
     - Reset all fog on current floor (all UNKNOWN).
   - Brush size adjustable (1–5 cells radius).
   - In Global fog mode, this is the primary way to set fog. In Revealed mode, it overrides the automatic state.
   - Visual feedback: show a colored overlay on the grid indicating what will be changed.

5. Vision Token system
   - VisionTokenData already exists from Phase 0. Now implement the runtime behavior.
   - Vision tokens are placed on the map via a VisionTokenTool (similar to ObjectTool).
   - Each token renders as a distinctive icon (e.g., an eye or a chess piece) with a direction indicator if vision_arc < 360.
   - Token properties editable in PropertyInspector:
     - Token name, controlled by (player ID or "GM").
     - Floor index.
     - Vision range (cells), vision arc (degrees, 360 = omnidirectional), facing angle.
     - Darkvision range (cells), low-light multiplier.
     - Vision height (meters, for future wall-height interactions).
     - is_player_controlled toggle.
   - When a token is selected or moved, its visible area is highlighted on the map (see #7).
   - Store tokens per floor, but MapData.vision_tokens holds the master list.

6. Vision + Fog integration
   - When in Preview mode or when fog is active:
     - For each active vision token, compute visible cells via VisionManager.calculate_visibility().
     - Pass the union of all visible cells to FogManager.update_visibility().
     - The obstacle check callback queries ObstacleManager: does any wall/object at this cell have BLOCK_VISION set?
   - Darkvision: if a cell is outside light range but within darkvision_range, it is visible but rendered in grayscale or with a blue tint.
   - Low-light vision: multiplies effective light radius for that token.
   - Cone vision (vision_arc < 360): pass arc_start and arc_width to ShadowCastData based on facing_angle.

7. Preview mode (player perspective)
   - Add a View menu toggle: "Edit Mode" / "Preview Mode".
   - In Preview Mode:
     - The toolbar is partially disabled (only Select and Token tools active).
     - Select a vision token to see the map from that token's perspective.
     - Fog overlay renders: UNKNOWN cells = black, EXPLORED cells = dim terrain, VISIBLE cells = normal.
     - Objects in EXPLORED cells are hidden (only terrain shows).
     - Vision range is highlighted as a subtle circle/cone around the selected token.
     - Light sources within visible range contribute to the visual (lite integration, full light in Phase 4).
   - Toggle between tokens with Tab or a dropdown.
   - Escape returns to Edit Mode.

8. Fog + Vision performance optimizations
   - Per-token visibility cache: if a token is at a position it was at before, reuse cached visible cells.
   - Dirty-token tracking: only recompute tokens that have moved or whose surroundings changed (walls added/removed within their vision range).
   - Fog Image reuse: only recreate the Image when fog grid dimensions change; otherwise, update pixels in-place.
   - For large maps, consider updating the fog texture in a background thread (Godot 4 supports threaded image updates).
   - `find_affected_tokens(changed_cell, radius)`: when walls/obstacles change, find all tokens within radius and mark them dirty.

9. Multi-token / multiplayer fog foundations
   - FogData.token_revealed: Dictionary of token_id → Array of explored cells.
   - When multiple tokens exist (e.g., 4 players in a party), each maintains its own explored set.
   - In Preview mode, you can select which token's perspective to view.
   - The GM always sees the full merge of all tokens' explored areas (or can toggle to see a specific token's view).
   - Stub for future: `update_player_visibility(player_id, token_positions)` method.

10. Fog transition animation
    - When fog state changes (VISIBLE→EXPLORED), apply a brief fade transition rather than an instant change.
    - Use a tween or a secondary texture that crossfades.
    - fog_transition_speed from FogData controls the duration.

11. Unit tests for vision
    - tests/unit/test_vision_manager.gd must include at minimum:
      - Open room: origin at (5,5), range=4, no obstacles → all cells within radius 4 are visible. Count and verify.
      - Single wall: origin at (0,0), wall at (2,0) extending vertically → cells behind the wall (x>2) are not visible.
      - Range boundary: origin at (0,0), range=3 → cell at (3,0) is visible, cell at (4,0) is not.
      - Arc restriction: origin at (0,0), range=5, arc_start=0, arc_width=PI/2 (90 degrees) → only cells in quadrant I are visible.
      - Performance: test with range=20 on an empty 100×100 map, must complete in under 100ms.

TECHNICAL REQUIREMENTS:
- VisionManager is a pure computation class; it does not depend on the scene tree.
- FogManager rendering uses Image + ImageTexture; do not use per-cell Sprite2D nodes (performance).
- The obstacle check callback passed to VisionManager queries ObstacleManager for BLOCK_VISION at the given cell.
- All fog tool actions go through UndoRedoManager (FogPaintCommand storing the previous state of changed cells).
- Preview mode rendering is a separate render pass that combines terrain + fog overlay.

ACCEPTANCE CRITERIA:
- Shadowcasting algorithm correctly computes visible cells for empty rooms, rooms with walls, and restricted arcs.
- Fog overlay renders correctly: UNKNOWN = opaque, EXPLORED = dim, VISIBLE = clear.
- FogTool can manually paint/reveal/hide/reset fog on any floor.
- Placing a vision token and entering Preview mode shows the map from that token's perspective with correct fog.
- Moving a token updates its visible area; previously-seen cells remain EXPLORED.
- Adding/removing walls updates affected tokens' visibility.
- Darkvision and cone vision tokens work correctly.
- All vision unit tests pass.
```

---

## Phase 4 — Light Source System (2–3 weeks)

```
You are building Phase 4 of a TRPG 2D Map Editor in Godot 4.x with GDScript. Previous phases are complete: full editing suite, floor system, portals, obstacle bit-flags, recursive shadowcasting vision engine, dynamic fog of war with Preview mode.

CONTEXT:
Phase 4 implements the light source subsystem: point/cone/directional/ambient lights, light attenuation calculations, obstacle-based light blocking, static light baking, a custom light shader, and the visual integration of light + fog + terrain.

DELIVERABLES:

1. LightManager (scripts/core/light_manager.gd)
   - Extends Node2D, attached to LightSourceLayer.
   - Maintains array of LightData per floor (via FloorData.floor_lights and MapData.light_sources).
   - Methods:
     - add_light_source(light: LightData) → creates backing data and emits light_source_updated.
     - remove_light_source(light_id: String) → cleans up and emits.
     - update_light_source(light_id, properties: Dictionary) → partial update.
     - get_lights_on_floor(floor_index: int) → Array[LightData].
     - calculate_light_at(cell: Vector2i, floor_index: int) → Color (total light contribution).
   - Light cache: per-floor Image that stores precomputed light values. Rebuilt when any light on that floor changes.

2. Light attenuation calculation
   - Implement `_calculate_light_contribution(cell, light) → Color`:
     - POINT light: attenuation = intensity / (1.0 + falloff * dist²). Color = light.color * attenuation.
     - CONE light: first check if cell is within the cone (angle between cell-to-light vector and light facing direction < outer_angle/2). If within inner_angle/2, full intensity; if between inner and outer, linear gradient. Then apply distance attenuation.
     - DIRECTIONAL light: uniform contribution in the light's direction. Simplified: all cells on the map get the same color * intensity.
     - AMBIENT light: added to every cell uniformly.
   - For a given cell, total light = ambient + sum of all non-ambient light contributions that reach the cell.
   - A light's contribution is blocked if any cell along the Bresenham line from light to target cell has an obstacle with BLOCK_LIGHT set. Use ObstacleManager's line-of-sight check.

3. Light source placement tool (scripts/tools/light_tool.gd)
   - Click to place a new light source at the grid cell.
   - Default: POINT light, warm white color, radius 5, intensity 1.0, falloff 0.5.
   - After placing, auto-select it for property editing.
   - Hold and drag to adjust radius visually (drag outward to increase radius ring).

4. Light renderer & visualization (scripts/rendering/light_renderer.gd)
   - In the editor viewport, for each light source draw:
     - A circle showing the light radius (dashed line).
     - For CONE lights: draw the inner and outer angle wedges.
     - For DIRECTIONAL lights: draw an arrow indicating direction.
     - A small icon at the light position (lightbulb / torch / sun / globe depending on type).
     - The circle/wedge color matches the light's color.
   - Selected light shows handles: drag the radius ring to resize, drag rotation handle for cone/directional.

5. Custom light shader (assets/shaders/light.gdshader)
   - A `canvas_item` shader that takes:
     - uniform sampler2D light_map: the precomputed light buffer.
     - uniform sampler2D fog_map: the fog overlay texture.
     - uniform vec4 ambient_color: ambient light contribution.
   - In `fragment()`:
     - Sample the terrain texture color.
     - Sample the light_map at the same UV.
     - Sample the fog_map.
     - lit_color = tex_color * (ambient_color + light_color).
     - final_color = mix(fog_overlay * tex_color, lit_color, 1.0 - fog_alpha).
   - Apply this shader material to the map rendering CanvasItem.

6. Light map generation
   - LightManager generates a light_map Image per floor:
     - Size: map_width × map_height pixels (or a scaled-down version for performance).
     - For each cell, compute total light contribution.
     - Store as RGBA8 where RGB = light color, A = unused (or used for intensity).
   - The light_map is uploaded to the shader as a uniform texture.
   - Rebuild light_map when any light on the floor changes (use dirty flag + deferred rebuild).
   - For large maps, rebuild at half or quarter resolution and let the shader bilinear-filter.

7. Static light baking
   - Static lights (is_static=true) are precomputed once and their contribution is baked into the light map.
   - Dynamic lights (is_dynamic=true) are recomputed each time a token moves or the light changes.
   - Provide a "Bake Static Lights" button in the Lights panel.
   - Baked static lights are stored in FloorData so they don't need recalculation on map load.

8. Light flicker effect
   - For lights with flicker_enabled=true:
     - Add a per-light timer that oscillates intensity based on flicker_speed and flicker_amount.
     - Use a noise function or sine wave to create natural-looking flicker.
     - Flickering lights are always treated as dynamic (even if is_static).
   - Flicker is computed in _process() delta and marks the light map dirty when intensity changes beyond a threshold.

9. Light + Fog interaction
   - A cell's final appearance = terrain_color × light_at_cell (if VISIBLE) or dim_terrain × light_at_cell (if EXPLORED) or black (if UNKNOWN).
   - In the shader, the fog texture alpha determines the blend:
     - fog.a = 1.0 → UNKNOWN → black.
     - fog.a = 0.5 → EXPLORED → dim terrain × light.
     - fog.a = 0.0 → VISIBLE → full terrain × light.
   - This means lights still affect EXPLORED cells (players remember the area was lit), but not UNKNOWN cells.

10. Light property inspector
    - When a light source is selected, show:
      - Name, Type dropdown (POINT/CONE/DIRECTIONAL/AMBIENT).
      - Color picker with preset palette (torch warm, magical blue, daylight white, etc.).
      - Intensity slider (0.0–3.0).
      - Radius slider (0.5–30.0 cells).
      - Falloff slider (0.0–2.0).
      - For CONE: inner angle (0–180°), outer angle (0–180°), rotation (0–360°).
      - Is Static checkbox, Is Dynamic checkbox.
      - Flicker enabled checkbox, Flicker Speed, Flicker Amount.
    - Changes update the light map and shader in real time during editing.

11. Light list panel
    - A dockable panel listing all lights on the current floor.
    - Columns: Name, Type, Color (swatch), Radius, Dynamic.
    - Click to select and focus; delete button; enable/disable toggle per light.
    - "Bake Static Lights" and "Clear Baked Lights" buttons.

12. Light + Vision token interaction in Preview mode
    - Preview mode now factors in lights:
      - If a token has darkvision, cells within darkvision_range but outside light range render in grayscale/blue.
      - If a token has low_light_multiplier, light radius is effectively multiplied for that token.
      - Cells in EXPLORED state + outside any light = render very dim (just visible enough to see terrain layout).
    - The combination: visibility (shadowcasting) ∩ light determines what the player actually sees and at what brightness.

13. Unit tests
    - tests/unit/test_light_manager.gd:
      - Point light at center of empty room: verify intensity at radius=0, radius=half, radius=max.
      - Cone light: cells inside inner angle get full intensity, cells outside outer angle get zero.
      - Light blocked by wall: cell behind BLOCK_LIGHT wall gets zero contribution.
      - Multiple lights: total contribution is additive.
      - Falloff curve correctness.

TECHNICAL REQUIREMENTS:
- The light shader is a canvas_item shader applied to the map viewport's root CanvasItem.
- Light calculations are in GDScript (CPU); the shader only composites. A future optimization could move calculations to GPU.
- Obstacle light-blocking uses the same Bresenham line check from the design doc.
- Static light baking saves computed light values into an Image stored alongside the floor data in the .trpgmap file.
- Flicker animation does not cause performance issues: only mark dirty when intensity delta > 0.01.

ACCEPTANCE CRITERIA:
- Can place point, cone, directional, and ambient lights via the LightTool.
- Light radius circles and cone wedges are visible in the editor.
- In Preview mode, lit cells are bright, unlit cells are dark, and walls cast light shadows.
- Flickering lights visibly oscillate in Preview mode.
- Static lights can be baked; dynamic lights update in real time.
- Darkvision renders unlit-but-visible cells in grayscale/blue tint.
- Multiple overlapping lights sum correctly.
- Light properties can be edited and changes reflect immediately.
- Light unit tests pass.
```

---

## Phase 5 — Import & Export (2–3 weeks)

```
You are building Phase 5 of a TRPG 2D Map Editor in Godot 4.x with GDScript. All previous phases (0–4) are complete: the editor can create and edit maps with floors, walls, objects, portals, lights, dynamic fog of war, and a vision/light preview mode. The native .trpgmap format is fully functional.

CONTEXT:
Phase 5 adds import and export support for multiple file formats, making the editor interoperable with DungeonDraft, Foundry VTT, Tiled Map Editor, ASCII maps, and plain images. It also adds PNG export for printing/sharing.

DELIVERABLES:

1. SerializationManager (scripts/serialization/serialization_manager.gd)
   - Extend the existing SerializationManager with a registry of importers and exporters.
   - Import registry: "trpgmap" → TRPGMapImporter, "dd2vtt" → DungeonDraftImporter, "uvtt" → UVTTImporter, "tmx" → TiledImporter, "ascii" → ASCIIMapImporter, "image" → ImageMapImporter.
   - Export registry: "trpgmap" → TRPGMapExporter, "json" → JSONExporter, "png" → PNGExporter, "uvtt" → UVTTExporter, "tmx" → TiledExporter, "pdf" → PDFExporter.
   - Base classes: MapImporter (extends RefCounted) with virtual method `import_file(path) → MapData`, and MapExporter with `export_to_file(map_data, path) → bool`.
   - `detect_format(file_path)` returns the format string from file extension.
   - `import_map(file_path, format)` and `export_map(map_data, file_path, format)` dispatch to the correct handler.
   - Emit import_started/import_completed/import_failed and export_started/export_completed/export_failed signals.

2. Import dialog (scenes/dialogs/import_dialog.tscn)
   - File picker to select the source file.
   - Format auto-detected from extension, with a manual override dropdown.
   - Preview area: after selecting a file, show a summary of what will be imported (map name, dimensions, floor count, wall count, light count, portal count).
   - Options specific to the format:
     - For image import: grid size, map dimensions, brightness threshold for wall detection.
     - For ASCII import: character-to-tile mapping (editable table).
   - "Import" button executes the import and loads the map into the editor.
   - On success, the map is treated as unsaved (so the user can save as .trpgmap).

3. Export dialog (scenes/dialogs/export_dialog.tscn)
   - Format dropdown (trpgmap, json, png, uvtt, tmx, pdf).
   - File path picker with auto-extension.
   - Format-specific options:
     - PNG: resolution multiplier (1x/2x/4x), include fog (player view) or exclude (GM view), show/hide grid.
     - JSON: pretty-print toggle, include resource paths or strip them.
     - UVTT: include image data (base64) or reference external file.
     - PDF: page size (A4/Letter), scale to fit or tiles per page.
   - "Export" button executes and shows a success/error message.

4. DungeonDraft .dd2vtt importer
   - .dd2vtt is a JSON format. Parse it:
     - `resolution.map_size` → map dimensions.
     - `resolution.pixels_per_grid` → grid_size.
     - `line_of_sight` array → convert each wall segment to WallSegmentData:
       - Each entry is an array of [x, y] points forming a polyline. Convert each segment to a WallSegmentData with default SOLID type and all block flags.
     - `portals` array → convert to PortalData.
     - `lights` array → convert to LightData (DungeonDraft lights have position, range, intensity, color).
     - `image` → extract the base64-encoded PNG and save it as the background layer of floor 0.
   - Map name taken from the filename.
   - Emit warnings for any unsupported DungeonDraft features.

5. Universal VTT .uvtt importer
   - .uvtt is similar to .dd2vtt but more standardized (Foundry VTT ecosystem).
   - Parse the same fields (resolution, line_of_sight, portals, lights, image).
   - Additional field: `environment` → convert ambient light settings.
   - Additional: `grid` → grid type and offset.

6. Tiled Map Editor .tmx importer & exporter
   - TMX is XML-based. Use Godot's XMLParser to parse:
     - `<map>` attributes: width, height, tilewidth, tileheight.
     - Each `<layer>` → create a TerrainLayerData.
     - Each `<tile>` in a layer → store in the layer's tiles Dictionary.
     - `<objectgroup>` → convert objects to MapObjectData.
     - `<properties>` → convert to custom_properties.
   - TMX exporter: reverse the process, writing standard TMX XML.
   - Limitation note: TMX does not support walls, portals, lights, or fog natively. Those are exported as custom properties or object groups with naming conventions (e.g., objects named "wall_001" with custom properties for wall attributes).

7. ASCII map importer (scripts/serialization/importers/ascii_map_importer.gd)
   - Parse a plain text file where each character represents a cell type.
   - Default mapping:
     - '#' → wall cell (solid wall on that cell).
     - '.' → floor cell (no tile, walkable).
     - '+' → door (wall with BLOCK_MOVEMENT but not BLOCK_VISION/LIGHT).
     - '>' / '<' → stairs down/up (stair connection to adjacent floor).
     - ' ' → empty/void.
   - User-configurable mapping via the import dialog (add custom character→meaning pairs).
   - Map dimensions determined by longest line and total line count.
   - Generate one floor with one terrain layer, placing appropriate tiles.

8. Image map importer (scripts/serialization/importers/image_map_importer.gd)
   - Load a PNG/JPG/WebP as the background image for floor 0.
   - Optional wall detection:
     - Apply edge detection (Sobel or Canny via an Image shader or CPU pixel iteration).
     - Or use brightness threshold: pixels darker than threshold are potential walls.
     - Present detected edges as an overlay; user can accept, adjust threshold, or manually trace.
   - User specifies grid size and map dimensions in the import dialog.
   - Generate WallSegmentData for detected walls (simplify edges to line segments using a basic line-following algorithm).

9. PNG export
   - Render the current viewport (or map at a given resolution) to an Image.
   - Two modes:
     - GM view: full map, all floors visible (or current floor), no fog, grid lines optional.
     - Player view: from the perspective of a selected vision token, with fog overlay applied.
   - Resolution multiplier: 1x = native grid resolution, 2x = double, 4x = quadruple.
   - Save as PNG with FileAccess.

10. JSON export
    - Export the complete map data as a clean JSON file (no Godot-specific resource references).
    - Follow the .trpgmap JSON structure from the design doc.
    - Option: strip asset paths and export only the logical structure (useful for sharing rule configurations).

11. PDF export
    - Use Godot's rendering to capture map slices.
    - Tile the map across multiple PDF pages if it exceeds one page at the target DPI.
    - Overlay page numbers and alignment marks for printing and assembling.
    - Since Godot doesn't have native PDF writing, you can:
      - Generate an HTML page with the map image and convert to PDF (stub for now), OR
      - Export as a multi-page PNG set and note that PDF conversion is done externally.
    - Mark the PDF exporter as "experimental" in the UI.

12. UVTT export
    - Export in the Universal VTT format:
      - Map image as base64-encoded PNG.
      - resolution block with map_size and pixels_per_grid.
      - line_of_sight from WallSegmentData.
      - portals array.
      - lights array.
    - This enables direct import into Foundry VTT.

13. Batch import/export
    - Import: select multiple files in the import dialog; each becomes a separate map (open the first, others added to recent files).
    - Export: "Export All Floors as PNGs" option that exports each floor as a separate image.

14. Round-trip tests
    - tests/integration/test_import_export.gd:
      - Create a test map with tiles, objects, walls, portals, lights.
      - Export to .trpgmap.
      - Import from .trpgmap.
      - Verify the imported map matches the original (cell-by-cell comparison for tiles and fog, field-by-field for objects/walls/portals/lights).
      - Same for .json format.

TECHNICAL REQUIREMENTS:
- Importers must be robust to malformed input: catch errors, emit import_failed with a descriptive message, never crash.
- Import errors should include line/field information where possible.
- Large image imports should process incrementally (show a progress bar).
- All exported files use the user's chosen file path; validate write permissions before starting.
- The SerializationManager uses signal-based progress reporting for long operations.

ACCEPTANCE CRITERIA:
- DungeonDraft .dd2vtt files import with walls, lights, portals, and the background image correctly placed.
- .uvtt files import similarly.
- Tiled .tmx files import correctly (layers become terrain layers); export produces a valid .tmx that Tiled can open.
- ASCII text maps import with correct wall/floor/door placement.
- Image import places the image as a background layer; wall detection produces a reasonable set of walls.
- PNG export produces a correctly-sized image at 1x/2x/4x resolution with optional grid and fog.
- JSON export is valid and can be re-imported without data loss.
- UVTT export can be imported by Foundry VTT (test manually or note limitations).
- Round-trip tests pass for .trpgmap and .json formats.
```

---

## Phase 6 — Optimization & Cross-Platform Polish (2–3 weeks)

```
You are building Phase 6 of a TRPG 2D Map Editor in Godot 4.x with GDScript. All features from Phases 0–5 are implemented: full map editing, floor management, portals, obstacle system, fog of war with recursive shadowcasting, light system with shader, and multi-format import/export.

CONTEXT:
Phase 6 is about making the editor production-ready: optimizing performance for large maps (>200×200), adapting the UI for Android touchscreens, polishing the user experience, adding internationalization (Chinese + English), and packaging the application for distribution on Windows, Linux, macOS, and Android.

DELIVERABLES:

1. Chunk-based map loading (scripts/rendering/map_chunk.gd)
   - Define CHUNK_SIZE = 64 cells.
   - A MapChunk class holding:
     - chunk_position (Vector2i chunk coordinates).
     - A pre-rendered ImageTexture of the terrain for that chunk.
     - Dirty flag.
   - Map renderer only draws chunks that intersect the current viewport.
   - When a tile changes within a chunk, mark that chunk dirty and redraw only that chunk's texture.
   - ChunkManager tracks all chunks for the current floor and manages their lifecycle.
   - On floor switch, dispose old chunks and create new ones for the target floor.

2. Large-map vision optimization
   - Limit visibility calculations to chunks near active tokens.
   - For maps >200×200, compute vision only for the token's surrounding area (e.g., range + 5 chunk radius).
   - FogImage only covers the visible area: use a sliding window that moves with the active token in Preview mode.
   - In Edit mode, fog rendering can be toggled off entirely for large maps.

3. GPU-accelerated fog rendering
   - Move fog rendering from CPU Image manipulation to a shader-based approach:
     - Store fog_grid as a texture (R8 format: 0=unknown, 128=explored, 255=visible).
     - Pass this texture to the existing composite shader.
     - Update the fog texture incrementally (only changed cells) rather than rebuilding the entire image.
   - This eliminates the CPU bottleneck for large maps.

4. Large-map light map optimization
   - Light maps are rebuilt at a reduced resolution (e.g., 1/4 scale) and upscaled in the shader with bilinear filtering.
   - Configurable via ConfigManager: light_map_scale (0.25, 0.5, 1.0).
   - Static lights are always baked at full quality once.

5. Performance settings panel
   - Add a Settings dialog (scenes/dialogs/settings_dialog.tscn) with a Performance tab:
     - Chunk size (32/64/128).
     - Fog render scale (full/half/quarter).
     - Light map scale (full/half/quarter).
     - Max undo steps.
     - Preview mode FPS cap.
     - Enable/disable real-time shadow updates.
   - Settings persist via ConfigManager.

6. Android touch adaptation (scripts/ui/responsive_ui.gd)
   - Detect platform: `OS.get_name()` returns "Android" or "iOS".
   - When on mobile:
     - All buttons minimum size 48×48 dp (use Godot's theme system).
     - Default font size increased to 16pt minimum.
     - Toolbar reorganized: icons larger, arranged in a scrollable grid or collapsible sections.
     - Floating action button for quick tool access.
   - Touch gestures:
     - Pinch to zoom (two-finger pinch, centered on midpoint).
     - Two-finger pan (two-finger drag to scroll).
     - Single tap to use active tool.
     - Long press (500ms) to open context menu (replaces right-click).
     - Double-tap to quick-switch to Select tool.
   - Virtual D-pad or on-screen joystick for fine-positioning the cursor.
   - Hide mouse-cursor-dependent features (hover previews, tooltips on hover) on mobile.
   - Add a mobile-specific HUD with undo/redo buttons always visible.

7. UI/UX polish
   - Design and add proper icons for all toolbar buttons (use simple SVG-style icons):
     - Select (arrow cursor), Brush (paintbrush), Line (diagonal line), Rect (dashed rectangle), Fill (paint bucket), Eraser (eraser).
     - Wall (brick wall segment), Portal (spiral/doorway), Light (lightbulb), Fog (cloud), Token (chess pawn), Measure (ruler).
   - Create these as simple .svg files in assets/icons/.
   - Add smooth transitions:
     - Tool switch: brief scale-bounce on the newly active tool icon.
     - Panel open/close: slide animation (use Tween).
     - Floor switch: crossfade (0.3s).
   - Dark theme and light theme support (switchable in Settings, default dark for map editing).
   - Keyboard shortcuts customization dialog:
     - List all actions and their current shortcuts.
     - Click an action, press new key combination to rebind.
     - Save to ConfigManager.

8. Internationalization (i18n)
   - Use Godot's built-in `tr()` and TranslationServer.
   - Create translation CSV files:
     - `translations/zh.csv` — Chinese (Simplified).
     - `translations/en.csv` — English.
   - Extract all user-visible strings into tr() calls. This includes:
     - All menu items (File, Edit, View, Tools, Help).
     - All toolbar tooltips.
     - All panel labels (Layers, Properties, Floor, Tiles).
     - All dialog titles and buttons.
     - All status bar messages.
     - All error/warning messages.
   - Add a language selector in Settings (dropdown, auto-detected from OS locale on first launch).
   - Ensure UI layouts accommodate both languages (Chinese text is more compact; English labels may need more width — test both).

9. Packaging for desktop
   - Windows:
     - Export template: Windows Desktop (x86_64).
     - Create a .exe with embedded .pck or alongside .pck.
     - Optionally wrap in an NSIS/InnoSetup installer.
   - Linux:
     - Export template: Linux (x86_64).
     - Create an AppImage using the official Godot AppImage scripts.
     - Also provide a plain binary + .pck for package managers.
   - macOS:
     - Export template: macOS (Universal).
     - Create a .app bundle.
     - Code-sign with `codesign` (ad-hoc signature is acceptable for now).
     - Wrap in a .dmg with a symlink to /Applications.
   - All platforms: include a README.txt and sample map.
   - Test each export on its target platform (or document what was tested).

10. Packaging for Android
    - Export template: Android (ARM64).
    - Configure Android export preset in project.godot:
      - Package name: com.trpg.mapeditor.
      - Min SDK 24, Target SDK 34.
      - Permissions: READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE (for file import/export).
      - Architecture: arm64-v8a.
    - Set up Android SDK/NDK paths.
    - Generate a debug .apk first, then a signed release .apk.
    - Handle Android file access via Godot's file dialogs (which map to Android's Storage Access Framework).
    - Test on at least one physical Android device or emulator.
    - Document any Android-specific limitations (e.g., some import formats may be slower).

11. Performance profiling & benchmarks
    - Use Godot's built-in profiler to identify bottlenecks in:
      - Map rendering (especially with fog + light).
      - Vision calculation for large ranges.
      - File I/O for large maps.
    - Create a benchmark scenario: 200×200 map, 20 lights, 50 walls, 4 vision tokens.
    - Measure and document:
      - FPS in Edit mode (target: >30 FPS).
      - FPS in Preview mode with fog + light (target: >20 FPS).
      - Vision calculation time for a single token with range=10 (target: <50ms).
      - File save time (target: <2s).
      - File open time (target: <3s).
    - If targets are not met, explore additional optimizations:
      - Multithreaded vision calculation.
      - Fog/Light update throttling (max once per 100ms).

12. Crash recovery & auto-save
    - Auto-save the current map to user://autosave.trpgmap every 5 minutes.
    - On editor start, check for autosave file. If found and newer than the last manual save, offer to restore it.
    - Configurable auto-save interval in Settings.

TECHNICAL REQUIREMENTS:
- All mobile adaptations must be gated by platform detection; desktop behavior must not change.
- Translations files must be UTF-8 encoded.
- Export templates must match the Godot version used for development.
- Chunk-based rendering is optional but strongly recommended for maps >150×150.

ACCEPTANCE CRITERIA:
- A 200×200 map with 50 walls, 10 lights, and 4 tokens runs at >30 FPS in Edit mode and >20 FPS in Preview mode.
- Pinch-to-zoom and two-finger-pan work smoothly on an Android device or emulator.
- UI elements are large enough to tap accurately on a phone screen.
- All UI text is translatable; switching to Chinese displays all menus and labels in Chinese.
- A working .exe, .AppImage, .dmg, and .apk can be generated.
- Auto-save recovers work after an unexpected quit.
- Keyboard shortcut customization dialog functions correctly.
```

---

## Phase 7 — Testing & Documentation (1–2 weeks)

```
You are building Phase 7 of a TRPG 2D Map Editor in Godot 4.x with GDScript. All features from Phases 0–6 are complete: the editor is fully functional, performant, and packages for Windows/Linux/macOS/Android.

CONTEXT:
Phase 7 is the final quality-assurance phase. It focuses on achieving >70% unit test coverage, writing integration tests for the complete editing workflow, running performance benchmarks, and producing user-facing and developer-facing documentation. An example map pack is also created to showcase the editor's capabilities.

DELIVERABLES:

1. Unit test suite expansion
   - Ensure all existing tests pass. Add new tests to reach >70% code coverage (measured by GUT's coverage tools).
   - Required test files and what they cover:

   tests/unit/test_map_data.gd:
     - MapData default values.
     - MapData JSON serialization round-trip.
     - Adding/removing floors updates MapData.floors array correctly.
     - FloorData deep-copy (duplicating a floor does not share references).
     - TerrainLayerData tile read/write.
     - WallSegmentData block_flags bit operations.
     - Enum serialization/deserialization for all enums.

   tests/unit/test_vision_manager.gd:
     - Open room visibility: all cells within range visible.
     - Single-cell wall: shadow cast correctly behind it.
     - Diagonal wall: correct asymmetric shadow.
     - Range boundary: cell at exactly range is visible; range+1 is not.
     - Arc restriction: 90° arc shows only quadrant I cells.
     - Large range performance: range=20 on 100×100 map completes in <100ms.
     - Origin always visible.
     - Edge case: range=0 (only origin visible).
     - Edge case: range=1 with surrounding walls.

   tests/unit/test_light_manager.gd:
     - Point light: intensity at center = 1.0, at radius = attenuated correctly.
     - Cone light: inside inner angle = full, outside outer angle = zero.
     - Light blocked by BLOCK_LIGHT wall.
     - Multiple lights additive.
     - Falloff = 0 (constant intensity within radius).
     - Falloff = 1.0 (linear drop-off).
     - Directional and ambient light uniform contribution.

   tests/unit/test_fog_manager.gd:
     - Fog cell state transitions: UNKNOWN → VISIBLE → EXPLORED.
     - Multiple tokens: union of visible areas.
     - Fog_updated signal emitted on state change.
     - Clearing fog resets all to UNKNOWN.
     - Global fog mode: manual state changes persist.
     - Fog grid serialization/deserialization.

   tests/unit/test_portal_manager.gd:
     - Portal registration and lookup by ID.
     - Pair creation: bidirectional vs unidirectional.
     - Teleport updates token position and emits signal.
     - Cross-floor teleport emits floor_changed.
     - Removing a portal cleans up pairings.

   tests/unit/test_serialization.gd:
     - .trpgmap round-trip: create MapData → save → load → compare all fields.
     - .json export round-trip.
     - .tmx import sample file.
     - Empty map save/load.
     - Map with all feature types save/load (walls, objects, portals, lights, fog).
     - Backward compatibility: Phase 0 format file loads correctly with defaults for missing fields.

   tests/unit/test_undo_redo.gd:
     - Execute command, undo restores previous state.
     - Undo then redo restores executed state.
     - Multiple commands: undo stack works in LIFO order.
     - Redo stack cleared on new command.
     - Max undo depth enforced (100).

   tests/unit/test_obstacle_flags.gd:
     - Bit flag setting and checking.
     - Combined flags (e.g., BLOCK_VISION | BLOCK_LIGHT).
     - ObstacleProperties default values.

2. Integration tests
   tests/integration/test_editor_workflow.gd:
     - Create new map via NewMapDialog → verify MapData created with correct defaults.
     - Place tiles in multiple modes → verify tile positions in TerrainLayerData.
     - Place objects → select → move → verify position updated.
     - Draw wall → change wall type → verify WallSegmentData updated.
     - Add floor → switch to it → place content → switch back → verify content preserved.
     - Place portal pair → verify PortalManager pairings.
     - Place light → enter Preview mode → verify light affects visibility.
     - Place token → move token → verify visible cells update.
     - Save map → close → reopen → verify all data intact.

   tests/integration/test_import_export.gd:
     - Export .trpgmap → import → compare md5-equivalent data.
     - Export .json → import → compare.
     - Import .dd2vtt sample → verify walls/lights/portals present.
     - Import .tmx sample → verify layers and tiles.
     - Export PNG at 1x and 2x → verify image dimensions.
     - Export all formats without crash.

3. Performance benchmark suite
   - Create a benchmark scene that:
     - Generates a map of configurable size (50×50, 100×100, 200×200, 400×400).
     - Fills it with randomly placed walls, lights, and tokens.
     - Measures and logs:
       - Time to generate map.
       - Time to save map.
       - Time to load map.
       - Time to compute vision for 4 tokens at range=10.
       - Time to rebuild light map.
       - FPS in Edit mode and Preview mode over a 10-second window.
   - Output results as a CSV or JSON file.
   - Define pass/fail thresholds:
     - Map load < 5s for 400×400 map.
     - Vision calculation < 50ms for range=10.
     - Preview mode FPS > 20 for 200×200 with fog + light.
   - If any threshold is not met, document it as a known limitation.

4. User manual (docs/user_manual.md)
   - Write in both English and Chinese (separate files: user_manual_en.md, user_manual_zh.md).
   - Sections:
     a. Introduction — what the TRPG Map Editor is and its role.
     b. Installation — per-platform instructions with screenshots.
     c. Quick Start — create a map, place tiles, add a floor, save.
     d. Interface Overview — annotated screenshot labeling all panels and tools.
     e. Terrain Editing — all tile placement modes, layers, tilesets.
     f. Objects and Walls — placing objects, drawing walls, wall types, obstacle flags.
     g. Floor Management — adding, switching, stair connections.
     h. Portals — creating portals, pairing, cross-floor/cross-map.
     i. Fog of War — fog modes, manual fog editing, dynamic fog.
     j. Vision Tokens — placing tokens, configuring vision, darkvision, cone vision.
     k. Light Sources — placing lights, types, attenuation, baking, flicker.
     l. Preview Mode — player perspective, token selection, fog + light combined.
     m. Import/Export — supported formats, step-by-step for each.
     n. Settings — performance, language, keyboard shortcuts.
     o. Keyboard Shortcuts — full reference table.
     p. Troubleshooting — common issues and solutions.
   - Screenshots: take actual screenshots of the running editor for each major section.

5. Developer documentation (docs/dev_guide.md)
   - Sections:
     a. Project Structure — directory tree with descriptions.
     b. Architecture Overview — signal-based communication, autoloads, manager pattern.
     c. Key Classes — MapData, FloorData, all managers, tools, renderers.
     d. Data Flow — how a tile placement propagates from input → tool → data model → renderer.
     e. Adding a New Tool — step-by-step guide with code snippets.
     f. Adding a New Import Format — implementing MapImporter subclass.
     g. Vision Algorithm — explanation of recursive shadowcasting, the octant system.
     h. Light System — how light maps are computed and composited in the shader.
     i. Fog System — fog state machine, rendering pipeline.
     j. Testing — how to run tests, how to write new tests.
     k. Building & Packaging — per-platform instructions.

6. API reference (docs/api_reference.md)
   - Auto-generate or manually document all `class_name` classes:
     - For each class: brief description, extends/inherits, signals, public methods (with parameters and return types), exported properties.
   - Organize by module: Data, Core, Rendering, Tools, UI, Serialization.

7. Example map pack
   - Create 3 example maps showcasing different feature sets:
     a. `tutorial_cave.trpgmap` — a simple 20×20 cave with:
        - 1 floor, 2 terrain layers (ground + decoration).
        - 3 walls (cave walls).
        - 2 light sources (torches).
        - 1 portal (entrance to exit).
        - 1 vision token for the player.
        - Fog enabled in Revealed mode.
     b. `multi_floor_keep.trpgmap` — a 30×30 multi-floor castle:
        - 4 floors (Dungeon, Ground, Upper, Tower).
        - Stairs connecting adjacent floors.
        - Portals for magical teleportation between tower and dungeon.
        - Various wall types (solid stone, windows, bars).
        - Multiple light sources (torches, magical glow, ambient).
        - 4 vision tokens for a party of adventurers.
     c. `hex_wilderness.trpgmap` — a 40×40 hex-grid wilderness:
        - Hex grid (HEX_FLAT).
        - Terrain: grass, forest, water, mountain (using colored placeholder tiles).
        - No walls (outdoor), but trees as objects with BLOCK_VISION.
        - Daylight: large directional light + ambient light.
        - No fog (NONE mode).

8. Changelog (CHANGELOG.md)
   - Record all notable changes per version:
     - v1.0.0 — Initial release with all Phase 0–7 features.
   - Follow Keep a Changelog format (https://keepachangelog.com/).

9. README.md
   - Project title, one-line description.
   - Feature highlights (bullet list).
   - Screenshot (main editor interface).
   - Quick install instructions per platform.
   - Link to user manual.
   - Link to developer guide.
   - License (MIT).
   - Credits (Godot Engine, GUT testing, etc.).

10. Final release checklist
    - All unit tests pass (GUT green).
    - All integration tests pass.
    - Benchmark thresholds met or documented as known limits.
    - User manual complete in EN and ZH.
    - Developer guide complete.
    - Example maps load correctly.
    - Desktop packages (.exe, .AppImage, .dmg) generated and smoke-tested.
    - Android .apk generated and tested.
    - Project clean: no debug prints left in code (or gated behind a verbose flag).
    - .gitignore includes: .import/, exports/, user:// config.

TECHNICAL REQUIREMENTS:
- Tests must be runnable with a single command (GUT panel or command-line).
- Documentation uses Markdown format.
- Screenshots should be PNG at reasonable resolution (max 1920px wide).
- Example maps must open correctly in the current editor version.

ACCEPTANCE CRITERIA:
- `>70%` unit test coverage (run GUT with coverage enabled and verify the report).
- All unit tests pass (no failures, no errors).
- All integration tests pass.
- Performance benchmarks are within defined thresholds.
- User manual covers every feature and is available in both English and Chinese.
- Developer guide enables a new developer to understand the architecture and add a simple feature.
- All 3 example maps open without errors and demonstrate their intended features.
- Clean release packages exist for all 4 target platforms.
```

---

## Usage Notes

- Each prompt is standalone. Hand it to an agent with access to the existing codebase.
- Prompts assume the previous phase is complete. An agent working on Phase N should have all Phase 0 through N−1 code available.
- "ACCEPTANCE CRITERIA" at the end of each prompt defines when the phase is done.
- Estimated durations are for a single experienced developer; double them if the agent is junior or the codebase is unfamiliar.
- The `[ ]` checkboxes in the design doc's Section 7 map roughly 1:1 to the deliverables listed above; use that section as a progress tracker.
