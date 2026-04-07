# GODOT GOLF PLATFORMER

*Project Design & Development Document*

*Solo Developer • Godot 4 • 2D Pixel Art Platformer*

---

## 1. Game Concept

A 2D precision platformer with golf mechanics. The player hits a golf ball and must then physically navigate to the ball's landing position to take the next shot. Movement skill and shot accuracy are both required to progress through each hole efficiently.

| Property | Value |
| :---- | :---- |
| Genre | 2D Precision Platformer + Golf |
| Engine | Godot 4 |
| Art Style | Pixel Art (asset pack base, custom additions) |
| Tile Size | 18x18px with 1px separation |
| Developer | Solo |
| Branch | main / dev |

---

## 2. Game Modes

### 2.1 Stroke Play

The primary scoring mode. Strokes are the score — lower is better. Medal thresholds are set per hole rather than using traditional golf par, keeping design flexible and accessible to a platformer audience.

- Enemies add a stroke penalty on contact
- Death respawns the player at the last hit position with a stroke penalty (equivalent to a golf penalty drop)
- Stroke count is a pure measure of shot-making skill — deaths from platforming cost a stroke, reinforcing intentional play
- Stroke count is always displayed even after a gold medal is achieved, allowing continued improvement

### 2.2 Time Trial

Complete the hole as fast as possible. Bronze, silver, gold, and secret medal times are set per hole. Best time is always saved and displayed.

- Death respawns at last hit position — navigation cost back to the ball is the primary penalty
- An optional time penalty on death can be tested during development
- Dash and wall jump mastery directly impacts achievable times

### 2.3 Medal System

Both modes share the same four-tier medal framework for consistency. Medals reflect best-ever performance, not most recent — a bad run never overwrites a good one.

| Medal | Stroke Play | Time Trial |
| :---- | :---- | :---- |
| 🥉 Bronze | Generous — most players finish | Slowest acceptable time |
| 🥈 Silver | Solid, clean play | Competent movement |
| 🥇 Gold | Strong shot optimization | Good dash and wall jump usage |
| ⭐ Secret | Near-perfect routing | Mastery level execution |

**Secret medal notes:**

- Thresholds sit above gold — tight enough to require near-perfect play
- No death is implicitly required at secret level since the penalties make it nearly impossible to achieve otherwise
- Thresholds must be verified as humanly achievable during playtesting

---

## 3. Core Mechanics

### 3.1 Golf Shot System

Classic aim and power bar with skill-based timing.

- Touching the ball immediately begins aiming — no button press required to enter aim mode
- Player movement is locked and invincibility is active for the entire shot sequence (AIMING through IN_FLIGHT)
- Left/right arrow keys rotate the aim arrow freely — no snapping, no time pressure
- Aim is clamped to 0–180 degrees (no downward shots), with horizontal shots permitted for strategic use
- Power bar oscillates between 0 and 1 continuously once started — pressing space locks the current value
- Shot power is a pure percentage of the bar value — no sweet spot zones
- Two club types: standard club for normal shots, putter for shots on the green
- The golf green area around the hole automatically switches to the putter

### 3.2 Ball and Respawn

- The ball lands and stays until the player reaches it and takes the next shot
- A visible marker shows the last hit-from position at all times
- On death the player respawns at the last hit-from position marker
- Brief invincibility frames on respawn, indicated by a flashing animation
- The marker doubles as a strategic element — players learn to consider their hit position as a safety net

### 3.3 Player Movement

Tight precision platformer movement in the style of Celeste. All values are exported for in-editor tuning.

#### Implemented and Tuned

| Variable | Current Value | Effect |
| :---- | :---- | :---- |
| speed | 300.0 | Top horizontal running speed |
| ground_acceleration | 1800.0 | How quickly full speed is reached on ground |
| ground_deceleration | 1800.0 | How quickly the player stops on ground |
| air_acceleration | 600.0 | Directional control strength in air |
| air_deceleration | 400.0 | How quickly horizontal speed bleeds off in air |
| jump_velocity | -400.0 | Jump height |
| coyote_time | 0.1 | Window to jump after leaving a ledge |
| jump_buffer_time | 0.1 | Window to pre-input a jump before landing |

#### Wall Jump

Jumps away from the wall horizontally — not straight up. Designed for lateral escape and momentum, not infinite vertical climbing.

| Variable | Current Value | Effect |
| :---- | :---- | :---- |
| wall_jump_velocity_x | 250.0 | Horizontal push away from wall |
| wall_jump_velocity_y | -350.0 | Vertical component of wall jump |
| wall_jump_lock_time | 0.15 | Input lockout window after wall jump fires |

#### Dash

Horizontal only. Acceleration-based burst that decelerates naturally. Refreshes on landing only. Green/red indicator shows availability — currently displayed in world space above the player.

| Variable | Current Value | Effect |
| :---- | :---- | :---- |
| dash_initial_speed | 900.0 | Burst speed at start of dash |
| dash_deceleration | 4000.0 | How fast dash speed scrubs off |
| dash_min_speed | 200.0 | Speed threshold where dash ends and movement resumes |
| dash_gravity | false | Toggle gravity during dash for feel comparison |

### 3.4 Green and Putting

The green is a self-contained scene (`scenes/green/green.tscn`) instanced into each hole. It owns the putting surface, hole detection, flag, and club switching logic.

#### Club Switching

- Ball entering the GreenDetector Area2D triggers `enter_green(hole_position)` on the ball
- Club switches to putter: `max_power` drops from 800 to 250
- Power bar behaviour is identical visually — oscillates 0 to 1 — only the behind-the-scenes `max_power` value changes
- Ball exiting the green triggers `exit_green()` — standard club and full aim range restored

#### Putter Aim

- Aim is locked to 0 degrees (right) or 180 degrees (left) only — no free rotation on the green
- Left/right arrow toggles between the two directions, snapping instantly
- Default direction on entering the green is toward the hole — ball queries the hole world position to determine left or right

#### Hole Completion

- Hole is a gap in the green TileMapLayer — one tile missing
- HoleDetector Area2D beneath the gap detects ball entry
- On detection: ball freezes and hides, player movement locks, completion delay timer starts (default 0.8s)
- Hole Complete overlay appears after delay showing stroke count and a restart button
- Restart reloads the current scene — GameState save/load will replace this when implemented

---

## 4. Level Structure

### 4.1 Holes

- Each hole is a fully self-contained scene loadable standalone or via adventure mode
- Scrolling camera within a hole is supported
- Holes do not connect to each other directly
- Each hole has its own HoleData resource defining medal thresholds for both modes

### 4.2 Transitional Platforming Levels

- Pure platforming levels placed between holes in adventure mode only
- Pass/fail — no stroke or time scoring
- Allows more complex platforming challenges without golf mechanics in the way
- Cleanly separated from hole scenes

### 4.3 Adventure Mode

- A meta-layer that sequences holes and transitional levels with story context
- Down the road feature — architecture supports it from day one
- Holes remain playable standalone outside of adventure mode

### 4.4 Test Hole (hole_test.tscn)

A dedicated testing environment under `scenes/holes/hole_01/hole_test.tscn`. Not a designed level — used to validate all feature additions before real level design begins. New mechanics (hazards, enemies, surface types) are prototyped here first. Actual level design is deferred until all core features are implemented.

---

## 5. Project Structure

### 5.1 Folder Layout

`res://` root structure:

| Folder | Contents |
| :---- | :---- |
| autoloads/ | Global singletons — GameState lives here |
| scenes/player/ | Player scene and scripts |
| scenes/ball/ | Golf ball scene and scripts |
| scenes/green/ | Reusable green scene (green.tscn, green.gd) |
| scenes/holes/hole_XX/ | One subfolder per hole |
| scenes/transitions/ | Platforming levels between holes |
| scenes/ui/ | HUD, menus, scorecard, medal display, ball indicator |
| scenes/adventure/ | Adventure mode sequencer |
| scenes/camera/ | Standalone camera scene and script |
| scripts/ | Standalone utility scripts and base classes |
| assets/sprites/ | PNG spritesheets and images |
| assets/audio/sfx/ | Sound effects |
| assets/audio/music/ | Music tracks |
| assets/fonts/ | Custom fonts |
| resources/tilesets/ | main_tileset.tres |
| resources/hole_data/ | Per-hole HoleData .tres files |
| resources/physics/ | PhysicsMaterial .tres files per surface type |
| addons/ | Installed plugins |

### 5.2 GameState Autoload

Registered as a singleton at Project Settings → Autoload. Accessible from any scene as `GameState`.

- Tracks current session: mode, hole, strokes, time, ball position, respawn state
- Tracks persistent records: best strokes and best time per hole, medals earned
- Tracks adventure mode state: sequence index, completed holes, story flags
- Responsible for save/load and medal calculation — not UI display or game logic

### 5.3 HoleData Resource

Custom Resource (`extends Resource`, `class_name HoleData`) saved as a `.tres` file per hole. Separates balance data from game logic so thresholds can be tuned without touching scripts.

- Fields: `hole_id`, stroke thresholds x4, time thresholds x4
- Loaded by GameState at the start of each hole

### 5.4 Tileset Setup

Single external TileSet resource at `resources/tilesets/main_tileset.tres` shared across all hole scenes.

- Tile size: 18x18px with 1px separation — configured in editor
- Physics layers defined: world (layer 1), hazards (layer 2), player (layer 3), ball (layer 4)
- Terrain sets: Ground, Ground (Snow), Water — mode: Match Corners and Sides
- Waterfall tiles are hand-placed, not terrain-set — top cap, middle, bottom cap variants
- Animated tiles: waterfall components at ~6fps, water surface at ~4fps, two frames each
- TileMapLayer structure per hole: background, platforms, hazards, foreground

### 5.5 Collision Layer Convention

| Layer | Purpose |
| :---- | :---- |
| Layer 1 — world | Solid ground tiles. Player and ball collide with this. |
| Layer 2 — hazards | Damaging tiles. Player detects this, ball does not. |
| Layer 3 — player | Player identity layer. Used by enemies and hazards to detect player. |
| Layer 4 — ball | Ball identity layer. Used by triggers to detect ball position. |

### 5.6 Global Groups

All groups are registered globally in Project Settings → Globals → Groups. Assigned in the editor on the relevant node — not via `add_to_group()` in script unless the node is a standalone scene root.

| Group | Scene | Node to Assign |
| :---- | :---- | :---- |
| golf_ball | scenes/ball/ball.tscn | RigidBody2D (root node) |
| player | scenes/player/player.tscn | CharacterBody2D (root node) |
| game_camera | scenes/camera/game_camera.tscn | Camera2D (root node) |
| golf_hole | scenes/green/green.tscn | Hole (Node2D) |
| golf_green | scenes/green/green.tscn | Green (root Node2D) |
| respawn_marker | scenes/holes/hole_XX/hole_XX.tscn | RespawnMarker (Node2D) — per hole |

### 5.7 Physics Materials

Surface-specific friction is handled through PhysicsMaterial resources assigned at the TileMapLayer level in the scene inspector. Per-tile PhysicsMaterial assignment is not supported in the Godot 4 TileSet editor.

| Resource | Path | Friction | Bounce | Usage |
| :---- | :---- | :---- | :---- | :---- |
| ground_material | resources/physics/ground_material.tres | 0.8 | 0.1 | Standard terrain TileMapLayers |
| green_material | resources/physics/green_material.tres | 1.0 | 0.05 | Green TileMapLayer in green.tscn |

All materials use `friction_combine` mode `MULTIPLY`. Future surfaces (sand, ice, rough) follow the same pattern: create a new `.tres` in `resources/physics/` and assign to the relevant TileMapLayer.

---

## 6. Player Scene

### 6.1 Node Structure

| Node | Purpose |
| :---- | :---- |
| CharacterBody2D | Root node |
| AnimatedSprite2D | Two-frame walk cycle from asset pack |
| CollisionShape2D | Player collision shape |
| WallRaycasts/ | Parent node for raycast organization |
| WallRaycasts/wall_left | RayCast2D pointing left (-30, 0), origin at mid-body |
| WallRaycasts/wall_right | RayCast2D pointing right (30, 0), origin at mid-body |
| DashIndicator | Polygon2D square above player — green available, red used (world space) |

### 6.2 Animation States

| State | Behaviour |
| :---- | :---- |
| IDLE | Stop on frame 0 |
| RUN | Play two-frame walk cycle |
| JUMP | Stop on frame 1 |
| FALL | Stop on frame 1 |
| WALL_SLIDE | Stop on frame 0, flipped toward wall |
| DASH | Stop on frame 1 |

### 6.3 Movement Lock

Player movement is fully locked during the shot sequence. Gravity and `move_and_slide()` continue to apply so the player stays grounded naturally.

- `movement_locked = true` when ball enters AIMING state (triggered by player touching ball)
- `movement_locked = false` when ball enters RESTING state
- `is_invincible` mirrors `movement_locked` — active for the full AIMING → POWER → IN_FLIGHT sequence
- All input handling (move, jump, dash, wall jump) is skipped while `movement_locked` is true

---

## 7. Ball Scene

### 7.1 Node Structure

| Node | Purpose |
| :---- | :---- |
| RigidBody2D | Root node, physics-driven |
| Sprite2D / AnimatedSprite2D | Ball visual |
| CollisionShape2D | CircleShape2D, radius 9px at scale 0.5 (4.5px effective radius, 9px diameter) |
| AimArrow (Node2D) | Container for aim arrow, rotates with aim_angle |
| AimArrow/ArrowLine (Line2D) | Visual aim arrow, points [0,0] to [0,-60] in local space |
| PlayerDetector (Area2D) | CircleShape2D trigger, mask set to layer 3 (player) |
| BallMarker (Node2D) | World-space marker above ball, visible when RESTING and on screen |

### 7.2 Shot State Machine

| State | Value | Behaviour |
| :---- | :---- | :---- |
| IDLE | 0 | Waiting, no interaction. Brief state before first touch. |
| AIMING | 1 | Player touching ball. Aim arrow visible. Left/right rotates aim (or toggles on green). Space → POWER. |
| POWER | 2 | Bar oscillates 0→1 continuously. Space locks power and fires shot. |
| IN_FLIGHT | 3 | Ball airborne, physics active. Camera follows ball. |
| RESTING | 4 | Ball settled, frozen. World marker visible. Player movement unlocked. |
| IN_HOLE | 5 | Ball in hole. Ball frozen and hidden. Hole completion sequence triggered. |

### 7.3 Shot Mechanics

- Aim rotates freely with left/right input, clamped to 0–180 degrees (no downward shots)
- On the green: aim locked to 0 or 180 only, left/right arrow toggles between them, defaults toward hole position
- Power bar oscillates continuously between 0 and 1 once POWER state begins
- Shot speed = `max_power` × power percentage
- Standard club: `max_power` 800. Putter: `max_power` 250 (used on green)
- Green area calls `ball.enter_green(hole_position)` / `ball.exit_green()` to switch clubs
- No physical collision between player and ball — player walks through cleanly

### 7.4 Ball Physics

Physics material and damping values to control roll and bounce behaviour.

| Property | Value | Notes |
| :---- | :---- | :---- |
| PhysicsMaterial friction | 0.6 | Ball baseline, combined with surface via MULTIPLY |
| PhysicsMaterial bounce | 0.2 (approx) | Tuned in editor |
| linear_damp | 1.5 | Exported — controls roll distance |
| angular_damp | 2.0 | Exported — controls spin resistance |

### 7.5 Signals

| Signal | When Emitted | Used By |
| :---- | :---- | :---- |
| ball_state_changed(state: int) | Every state transition | Camera, HUD, Player, Green |
| player_lock(locked: bool) | AIMING start / RESTING start | Player movement lock |
| stroke_taken | On every shot fired (_fire_shot) | HUD stroke counter, Hole scene |
| hole_completed | Emitted by green.gd when ball enters hole | Hole scene |

### 7.6 Respawn Marker

- Separate Node2D scene placed in each hole scene, added to group `respawn_marker` in editor
- Ball moves the marker to its hit-from position each time a shot is fired
- Player respawns here on death

---

## 8. Green Scene

Self-contained reusable scene at `scenes/green/green.tscn`. Instanced into each hole scene. Owns all putting surface logic.

### 8.1 Node Structure

| Node | Purpose |
| :---- | :---- |
| Node2D (Green) | Root node — in group golf_green |
| TileMapLayer | Green surface tiles — PhysicsMaterial: green_material.tres |
| GreenDetector (Area2D) | Triggers enter_green / exit_green on ball. CollisionShape2D covers full green area. |
| Hole (Node2D) | In group golf_hole. Contains hole detector, visuals, and position reference. |
| Hole/Area2D | HoleDetector — CircleShape2D ~10px radius over hole gap. Detects ball entry. |
| Hole/Sprite2D | Visual hole surface sprite |
| Hole/Line2D | Visual hole edge detail |
| Flag (Node2D) | Flag and pole visuals |
| Flag/AnimatedSprite2D | Animated flag wave |
| Flag/Pole | Flag pole sprite |

### 8.2 Green Script (green.gd)

- On GreenDetector `body_entered`: calls `ball.enter_green(Hole.global_position)`
- On GreenDetector `body_exited`: calls `ball.exit_green()`
- On Hole/Area2D `body_entered`: calls `ball.enter_hole()`, emits `hole_completed` signal

---

## 9. Camera System

Standalone Camera2D scene (`scenes/camera/game_camera.tscn`), not parented to player or ball. Finds targets via groups. All tuning values exported.

### 9.1 Camera Modes

| Mode | Trigger | Behaviour |
| :---- | :---- | :---- |
| FOLLOW_PLAYER | Default / ball enters RESTING | Smoothed platformer follow with horizontal deadzone |
| FOLLOW_BALL | Ball enters IN_FLIGHT | Threshold-based horizontal, free vertical with bounce filter |
| TRANSITIONING | Ball enters RESTING | Speed-based lerp back to player, max duration capped |

### 9.2 Player Follow

- Position smoothing via Godot built-in `position_smoothing_enabled`
- Horizontal deadzone — camera only moves when player exits deadzone band
- Separate vertical smoothing factor to avoid bounce on small jumps
- Respects Camera2D limit bounds set per hole in editor

### 9.3 Ball Follow (IN_FLIGHT)

- Horizontal: stationary until ball reaches 50% screen threshold, then follows keeping ball centered, stops at level bounds
- Vertical: ball kept centered with smoothing. Target only updates when ball velocity and displacement thresholds are both exceeded — prevents jitter on small bounces
- Shot direction locked at IN_FLIGHT start from ball `linear_velocity`
- `camera_target` Vector2 drives all movement — position never set directly during flight

### 9.4 Transition Back to Player

- Speed-based lerp — travel speed in px/s, faster for nearby landings
- Max duration cap prevents long transitions on distant landings
- Hard switches to FOLLOW_PLAYER on completion

### 9.5 Exported Tuning Variables

| Variable | Default | Effect |
| :---- | :---- | :---- |
| player_smoothing_speed | 8.0 | Overall player follow smoothing |
| player_horizontal_deadzone | 80.0 | Deadzone width before horizontal follow triggers |
| player_vertical_smoothing | 5.0 | Vertical follow responsiveness during platforming |
| flight_vertical_smoothing | 10.0 | Vertical smoothing during ball flight (deprecated — see below) |
| ball_horizontal_smoothing_speed | 8.0 | Horizontal catch-up speed once threshold crossed |
| ball_vertical_smoothing_speed | 6.0 | Vertical tracking speed during flight |
| ball_velocity_threshold | 150.0 | Min ball Y velocity to update vertical camera target |
| ball_displacement_threshold | 30.0 | Min pixel distance to update vertical camera target |
| transition_speed | 1200.0 | Camera travel speed px/s returning to player |
| max_transition_duration | 0.6 | Max seconds for player return transition |
| arrow_screen_margin | 24.0 | Screen edge margin for ball indicator arrow |
| show_debug_logs | true | Gates all camera debug print statements |

### 9.6 Ball Indicator

| Indicator | Visibility | Implementation |
| :---- | :---- | :---- |
| World marker (BallMarker) | Ball RESTING + ball on screen | Node2D child of ball, offset Y -24 |
| Screen edge arrow (HUD) | Ball RESTING + ball off screen | Control node in HUD, projects to screen edge with 24px margin, rotates toward ball |

---

## 10. HUD

Simple functional HUD for testing. Full HUD pass deferred until later.

### 10.1 Current Elements

| Element | Visibility | Notes |
| :---- | :---- | :---- |
| Power Bar | AIMING through IN_FLIGHT | Shows from aiming start. Fills during POWER only. 200x16px, yellow fill. |
| Stroke Counter | Always | Top left. Increments on stroke_taken signal. Format: Strokes: N |

### 10.2 Hole Complete Overlay

Triggered after hole completion with a configurable delay (default 0.8s). Handles end-of-hole flow until full scorecard is implemented.

- Darkened overlay (Color 0,0,0 alpha 0.6) covers full viewport
- Centered panel showing: hole complete title, stroke count, best score placeholder
- Restart button reloads current scene
- Best score and medal display slots present in UI, ready to be wired to GameState when implemented

---

## 11. Version Control

### 11.1 Branch Structure

| Branch | Purpose |
| :---- | :---- |
| main | Stable working state only — never broken |
| dev | Active development — commit freely |
| feature/* | Optional — only for risky experiments that might not work out |

Merge dev → main at coherent milestones (completed system, tested). Do not merge mid-feature.

### 11.2 .gitignore

Key exclusions:

- `.godot/` — local import cache, auto-regenerated
- `*.uid` — Godot 4.4+ UID files, safe to exclude solo
- `export_presets.cfg` — may contain sensitive signing keys
- `builds/` and `exports/` — compiled game output

### 11.3 Git LFS

Not required currently. Revisit if repository exceeds 1–2GB or asset replacement becomes frequent. Raw source files (PSDs, uncompressed audio, Blender files) should be kept out of the repository entirely and backed up separately.

---

## 12. Tools & Environment

| Tool | Details |
| :---- | :---- |
| Engine | Godot 4 |
| Script Editor | VS Code with godot-tools extension + Claude Code |
| VS Code Theme | Godot Editor Theme (custom extension) |
| Version Control | Git — GitHub remote, managed via VS Code Source Control panel |
| Art | Pixel art asset pack (18x18) with custom additions as needed |
| AI Workflow | Claude.ai for logic and design discussion, Claude Code for code generation via prompts |

---

## 13. Next Steps

Roughly prioritised — subject to change:

- Implement GameState autoload with session tracking and save/load
- Implement HoleData resource and medal calculation
- Wire GameState into hole complete overlay — best score, medal display
- Build scorecard/end-of-hole screen (full pass)
- Build main menu scene and set as project main scene
- Full HUD pass — move dash indicator to UI, add timer, medal display
- Enemy design and implementation for stroke play
- Transitional platforming level prototype
- Adventure mode sequencer (long term)
- Actual level design for hole_01 and beyond — deferred until all core features complete

---

*ℹ️ Resume this project by sharing this document with Claude at the start of a new session.*
