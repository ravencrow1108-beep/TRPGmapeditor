# 跨平台跑团（TRPG）平台 —— 2D地图编辑器策划书

---

## 目录

1. [项目概述](#1-项目概述)
2. [总体架构设计](#2-总体架构设计)
3. [地图核心数据结构](#3-地图核心数据结构)
4. [子系统详细设计](#4-子系统详细设计)
   - 4.1 [图层系统](#41-图层系统)
   - 4.2 [楼层转换系统](#42-楼层转换系统)
   - 4.3 [传送门系统](#43-传送门系统)
   - 4.4 [迷雾系统](#44-迷雾系统)
   - 4.5 [光源系统](#45-光源系统)
   - 4.6 [视野系统](#46-视野系统)
   - 4.7 [遮挡物系统](#47-遮挡物系统)
5. [文件格式与导入导出](#5-文件格式与导入导出)
6. [编辑器UI设计](#6-编辑器ui设计)
7. [开发路线图](#7-开发路线图)
8. [技术实现要点](#8-技术实现要点)

---

## 1. 项目概述

### 1.1 项目定位

本项目为跨平台TRPG（桌面角色扮演游戏）平台的**第一阶段——独立2D地图编辑器**。该编辑器可独立运行，后续将作为完整跑团平台的核心地图组件。

### 1.2 核心目标

- 支持GM创建和管理多层地图（楼层转换）
- 提供传送门功能实现跨楼层/跨地图跳转
- 实现动态迷雾系统，控制玩家可见区域
- 实现光源模拟，支持不同类型光源
- 实现基于网格的视野计算
- 支持障碍物标记（阻挡视野、阻挡光源、阻挡抛物线技能）
- 支持多种地图文件格式的导入导出
- 跨平台运行：Windows、Linux、macOS、Android

### 1.3 技术选型

| 项目 | 选择 | 理由 |
|------|------|------|
| 引擎 | Godot 4.x | 轻量、跨平台、GDScript开发效率高、MIT开源 |
| 渲染 | Godot内置2D渲染器 | 性能优秀、内置TileMap系统 |
| 脚本 | GDScript | Godot原生支持、易于调试 |
| UI | Godot Control节点 | 自适应多分辨率 |
| 网络 | ENet (Godot内置) / WebSocket | 多人联机基础 |
| 序列化 | Godot Resource / JSON | 地图数据存储 |

### 1.4 平台兼容性说明

Godot 4.x 原生导出目标包括：
- Windows (x86_64)
- Linux (x86_64, ARM64)
- macOS (Universal)
- Android (ARM64)

编辑器阶段以桌面平台（Windows/Linux/macOS）为主，导出至Android时需适配触屏UI。

---

## 2. 总体架构设计

### 2.1 架构概览

```
┌─────────────────────────────────────────┐
│              应用层 (App Layer)           │
├─────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │地图编辑器│  │ 地图查看 │  │ 导入导出 │ │
│  │ UI层    │  │ 器UI层  │  │ 管理器  │ │
│  └────┬────┘  └────┬────┘  └────┬────┘ │
├───────┼────────────┼────────────┼───────┤
│       ▼            ▼            ▼       │
│  ┌──────────────────────────────────┐   │
│  │         地图核心管理器            │   │
│  │       (MapCoreManager)           │   │
│  └──────────────┬───────────────────┘   │
│       ┌─────────┼─────────┐             │
│       ▼         ▼         ▼             │
│  ┌────────┐┌────────┐┌────────┐         │
│  │楼层系统││迷雾系统││光源系统│         │
│  └────────┘└────────┘└────────┘         │
│  ┌────────┐┌────────┐┌────────┐         │
│  │视野系统││传送系统││碰撞系统│         │
│  └────────┘└────────┘└────────┘         │
├─────────────────────────────────────────┤
│              数据层 (Data Layer)         │
│  ┌────────┐  ┌────────┐  ┌────────┐    │
│  │地图数据│  │图块数据│  │配置数据│    │
│  │ 模型   │  │ 集合   │  │ 管理器 │    │
│  └────────┘  └────────┘  └────────┘    │
├─────────────────────────────────────────┤
│           序列化层 (Serialization)        │
│  ┌────────┐ ┌──────────┐ ┌────────┐    │
│  │原生格式│ │JSON/MD   │ │其他格式│    │
│  │.tmap  │ │导入导出   │ │兼容    │    │
│  └────────┘ └──────────┘ └────────┘    │
└─────────────────────────────────────────┘
```

### 2.2 场景结构

```
Root (Node)
├── MapEditorUI (CanvasLayer)          # UI覆盖层
│   ├── ToolBar                        # 工具栏
│   ├── LayerPanel                     # 图层面板
│   ├── PropertyInspector              # 属性检查器
│   ├── TilePalette                    # 图块调色板
│   ├── FloorSelector                  # 楼层选择器
│   ├── MenuBar                        # 菜单栏
│   └── StatusBar                      # 状态栏
├── MapViewport (SubViewportContainer)  # 地图视口容器
│   └── MapViewport (SubViewport)      # 地图渲染视口
│       └── MapRoot (Node2D)           # 地图根节点
│           ├── TerrainLayer           # 地形层
│           │   └── TileMapLayer[]     # 各楼层TileMap
│           ├── ObjectLayer            # 物件层
│           │   └── ObjectLayer[]      # 各楼层物件
│           ├── WallLayer              # 墙壁层
│           │   └── WallLayer[]        # 各楼层墙壁
│           ├── PortalLayer            # 传送门层
│           ├── LightSourceLayer       # 光源层
│           ├── FogLayer               # 迷雾层
│           ├── GridOverlay            # 网格叠加层
│           └── EditorOverlay          # 编辑器辅助层
└── MapCoreManager (Node)             # 核心逻辑管理
    ├── FloorManager                   # 楼层管理
    ├── FogManager                     # 迷雾管理
    ├── LightManager                   # 光源管理
    ├── VisionManager                  # 视野管理
    ├── PortalManager                  # 传送门管理
    ├── ObstacleManager                # 遮挡物管理
    └── SerializationManager           # 序列化管理
```

### 2.3 信号通信设计

```gdscript
# 全局事件总线 (Autoload: EventBus)
# 解耦各子系统通信

# ---------- 地图信号 ----------
signal map_loaded(map_data: MapData)
signal map_saved(file_path: String)
signal floor_changed(old_floor: int, new_floor: int)
signal floor_added(floor_index: int)
signal floor_removed(floor_index: int)

# ---------- 编辑信号 ----------
signal tile_placed(cell: Vector2i, tile_id: int, layer: int)
signal tile_removed(cell: Vector2i, layer: int)
signal object_placed(position: Vector2, object_type: String, properties: Dictionary)
signal object_removed(object_id: String)

# ---------- 传送门信号 ----------
signal portal_created(portal_data: PortalData)
signal portal_teleported(portal_id: String, target_id: String)

# ---------- 遮挡物信号 ----------
signal obstacle_placed(obstacle_id: String, flags: int)
signal obstacle_updated(obstacle_id: String, flags: int)
signal obstacle_removed(obstacle_id: String)

# ---------- 迷雾/视野信号 ----------
signal fog_updated(floor: int)
signal visibility_changed(token_id: String, visible_cells: Array)
signal light_source_updated(light_id: String)

# ---------- 选择信号 ----------
signal selection_changed(selected_type: String, selected_data: Variant)
```

---

## 3. 地图核心数据结构

### 3.1 地图元数据 (MapData)

```gdscript
# map_data.gd - 地图根数据
class_name MapData
extends Resource

# ---------- 元信息 ----------
@export var map_name: String = "未命名地图"
@export var map_version: String = "1.0.0"
@export var author: String = ""
@export var created_date: String          # ISO 8601
@export var modified_date: String
@export var description: String = ""

# ---------- 地图参数 ----------
@export var grid_size: Vector2i = Vector2i(32, 32)    # 格子的像素大小
@export var map_dimensions: Vector2i = Vector2i(100, 100) # 每个楼层格子数
@export var grid_type: int = GridType.SQUARE          # 方格/六角
@export var coordinate_system: int = CoordSystem.OFFSET # 偏移/轴向坐标

# ---------- 楼层数据 ----------
@export var floors: Array[FloorData] = []
@export var current_floor: int = 0

# ---------- 全局数据 ----------
@export var portals: Array[PortalData] = []
@export var light_sources: Array[LightData] = []
@export var fog_of_war: Array[FogData] = []
@export var vision_tokens: Array[VisionTokenData] = []

# ---------- 规则书引用 ----------
@export var rulebook: RulebookReference = null

# ---------- 图集引用 ----------
@export var tilesets: Array[TilesetReference] = []

# ---------- 网格类型枚举 ----------
enum GridType {
    SQUARE,      # 方格
    HEX_POINTY,  # 尖顶六角
    HEX_FLAT     # 平顶六角
}

enum CoordSystem {
    OFFSET,      # 偏移坐标 (row/col)
    AXIAL,       # 轴向坐标 (q/r)
    CUBE         # 立方坐标 (q/r/s)
}
```

### 3.2 楼层数据 (FloorData)

```gdscript
# floor_data.gd
class_name FloorData
extends Resource

# ---------- 基础信息 ----------
@export var floor_index: int = 0
@export var floor_name: String = "地面层"
@export var floor_z: int = 0               # 显示层级(越高越靠前)
@export var elevation: float = 0.0         # 海拔高度(用于3D渲染参考)

# ---------- 楼层属性 ----------
@export var visible: bool = true
@export var locked: bool = false
@export var opacity: float = 1.0           # 半透明度
@export var tint_color: Color = Color.WHITE # 色调

# ---------- 地形图层 ----------
@export var terrain_layers: Array[TerrainLayerData] = []

# ---------- 物件数据 ----------
@export var objects: Array[MapObjectData] = []

# ---------- 墙壁/障碍物数据 ----------
@export var walls: Array[WallSegmentData] = []

# ---------- 楼层专属传送门 ----------
@export var floor_portals: Array[PortalData] = []

# ---------- 楼层专属光源 ----------
@export var floor_lights: Array[LightData] = []

# ---------- 楼层迷雾 ----------
@export var fog_data: FogData = FogData.new()
```

### 3.3 地形图层数据 (TerrainLayerData)

```gdscript
# terrain_layer_data.gd
class_name TerrainLayerData
extends Resource

@export var layer_name: String = "图层"
@export var layer_index: int = 0
@export var visible: bool = true
@export var locked: bool = false
@export var opacity: float = 1.0
@export var tileset_ref: String = ""         # 使用的图集资源ID
@export var tiles: Dictionary = {}           # {Vector2i: tile_data}
@export var tiles_as_texture: Dictionary = {} # 用于非TileMap的纹理放置
```

### 3.4 物件数据 (MapObjectData)

```gdscript
# map_object_data.gd
class_name MapObjectData
extends Resource

@export var object_id: String = ""
@export var object_type: String = ""          # 类型标识
@export var display_name: String = ""
@export var position: Vector2 = Vector2.ZERO  # 世界坐标
@export var grid_position: Vector2i = Vector2i.ZERO
@export var rotation: float = 0.0
@export var scale: Vector2 = Vector2.ONE
@export var sprite_path: String = ""
@export var z_index: int = 0
@export var collision_shape: int = CollisionShape.NONE
@export var custom_properties: Dictionary = {}

enum CollisionShape {
    NONE,        # 无碰撞
    RECTANGLE,   # 矩形
    CIRCLE,      # 圆形
    POLYGON,     # 多边形
    GRID_FILL    # 整格占据
}
```

### 3.5 墙壁线段数据 (WallSegmentData)

```gdscript
# wall_segment_data.gd
class_name WallSegmentData
extends Resource

@export var segment_id: String = ""
@export var start_point: Vector2i            # 网格坐标起点
@export var end_point: Vector2i              # 网格坐标终点
@export var wall_type: int = WallType.SOLID
@export var height: float = 2.0             # 墙高(米,用于抛物线计算)
@export var thickness: int = 1              # 厚度(格子数)

# ---------- 遮挡标志(位标志) ----------
@export_flags("视野", "光源", "抛物线技能", "移动") var block_flags: int = 0xF

enum WallType {
    SOLID,        # 实心墙
    WINDOW,       # 窗户墙(阻挡移动和技能,不挡视野和光)
    BARS,         # 栏杆(阻挡移动,不挡视野/光/技能)
    ILLUSION,     # 幻象墙(可见不可阻挡移动)
    HALF_HEIGHT,  # 半高墙(阻挡移动,抛物线可越过)
    TRANSPARENT   # 透明墙(阻挡移动,不阻挡任何其他)
}
```

### 3.6 传送门数据 (PortalData)

```gdscript
# portal_data.gd
class_name PortalData
extends Resource

@export var portal_id: String = ""
@export var portal_name: String = ""
@export var source_floor: int = 0
@export var source_position: Vector2i
@export var source_size: Vector2i = Vector2i(1, 1)  # 占几格
@export var target_floor: int = 0
@export var target_position: Vector2i
@export var target_map: String = ""           # 空=本图,可引用其他地图文件
@export var is_bidirectional: bool = true
@export var is_active: bool = true
@export var visual_color: Color = Color.PURPLE
@export var label_visible: bool = true
@export var label_text: String = ""
@export var trigger_type: int = TriggerType.WALK_ON

enum TriggerType {
    WALK_ON,      # 走入触发
    INTERACT,     # 交互触发
    AUTOMATIC     # 自动触发(进入范围)
}
```

### 3.7 光源数据 (LightData)

```gdscript
# light_data.gd
class_name LightData
extends Resource

@export var light_id: String = ""
@export var light_name: String = ""
@export var floor_index: int = 0
@export var position: Vector2
@export var grid_position: Vector2i

# ---------- 光源参数 ----------
@export var light_type: int = LightType.POINT
@export var intensity: float = 1.0
@export var color: Color = Color(1.0, 0.95, 0.8, 1.0)
@export var radius: float = 5.0              # 光照半径(格子数)
@export var falloff: float = 0.5             # 衰减因子(0=无衰减,1=线性)
@export var inner_angle: float = 0.0         # 内角(锥形光)
@export var outer_angle: float = 45.0        # 外角(锥形光)
@export var rotation: float = 0.0            # 旋转(锥形光)
@export var is_static: bool = true           # 静态光源(预烘焙)
@export var is_dynamic: bool = false         # 动态光源(实时计算)
@export var flicker_enabled: bool = false    # 闪烁效果
@export var flicker_speed: float = 1.0
@export var flicker_amount: float = 0.2

enum LightType {
    POINT,        # 点光源(全向)
    CONE,         # 锥形光(定向)
    DIRECTIONAL,  # 方向光(边缘/全局)
    AMBIENT       # 环境光(填充)
}
```

### 3.8 迷雾数据 (FogData)

```gdscript
# fog_data.gd
class_name FogData
extends Resource

@export var enabled: bool = true              # 是否启用迷雾
@export var fog_type: int = FogType.REVEALED
@export var fog_color: Color = Color(0.05, 0.05, 0.05, 0.9)
@export var unexplored_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var explored_color: Color = Color(0.05, 0.05, 0.05, 0.7)
@export var fog_transition_speed: float = 2.0 # 迷雾过渡速度

# ---------- 迷雾数据存储(每个格子一个状态) ----------
# 0=未知, 1=已探索, 2=当前可见
@export var fog_grid: Dictionary = {}         # {String(cell): int}

# ---------- 各玩家Token已揭示的单元格(用于多人) ----------
@export var token_revealed: Dictionary = {}   # {token_id: [cells]}

enum FogType {
    NONE,         # 无迷雾
    GLOBAL,       # 全局迷雾(预设哪些区域可见)
    DYNAMIC,      # 动态迷雾(根据玩家Token视野)
    REVEALED      # 揭示后留下痕迹(标准跑团模式)
}
```

### 3.9 视野Token数据 (VisionTokenData)

```gdscript
# vision_token_data.gd
class_name VisionTokenData
extends Resource

@export var token_id: String = ""
@export var token_name: String = ""
@export var floor_index: int = 0
@export var position: Vector2
@export var grid_position: Vector2i

# ---------- 视野参数 ----------
@export var vision_range: float = 6.0         # 视野范围(格子数)
@export var vision_arc: float = 360.0         # 视野弧度(360=全向)
@export var facing_angle: float = 0.0         # 面向角度
@export var darkvision_range: float = 0.0     # 黑暗视觉范围
@export var low_light_multiplier: float = 1.5 # 微光视觉倍率

# ---------- 当前可见格子(运行时计算) ----------
@export var visible_cells: Array[Vector2i] = []
@export var explored_cells: Array[Vector2i] = []

# ---------- 视觉层级 ----------
@export var vision_height: float = 1.7        # 视线高度(米)
@export var can_see_invisible: bool = false

# ---------- 运行时 ----------
@export var is_player_controlled: bool = true
@export var owner_player_id: String = ""
```

### 3.10 规则书引用 (RulebookReference)

```gdscript
# rulebook_reference.gd
class_name RulebookReference
extends Resource

@export var rulebook_name: String = ""
@export var rulebook_version: String = ""
@export var rules_path: String = ""           # 规则书JSON文件路径
@export var active_rules: Array[String] = []  # 启用的规则模块
```

---

## 4. 子系统详细设计

### 4.1 图层系统

#### 4.1.1 图层类型

```
图层栈 (从下到上):
┌──────────────────┐
│  编辑器辅助层     │ ← 网格线、选择框、控制手柄
├──────────────────┤
│  迷雾渲染层       │ ← 动态生成的迷雾多边形
├──────────────────┤
│  特效层           │ ← 法术效果、粒子
├──────────────────┤
│  物件层           │ ← 家具、道具、角色Token
├──────────────────┤
│  墙壁层           │ ← 墙壁、障碍物
├──────────────────┤
│  装饰地形层2      │ ← 装饰性图块(叠加)
├──────────────────┤
│  装饰地形层1      │ ← 装饰性图块
├──────────────────┤
│  基础地形层       │ ← 地面/地板/基础图块
├──────────────────┤
│  背景层           │ ← 天空/地下背景
└──────────────────┘
```

#### 4.1.2 图层管理

```gdscript
# layer_manager.gd
class_name LayerManager
extends Node

signal layer_added(layer_data: TerrainLayerData)
signal layer_removed(layer_index: int)
signal layer_reordered(from_index: int, to_index: int)
signal layer_visibility_changed(layer_index: int, visible: bool)
signal layer_opacity_changed(layer_index: int, opacity: float)

var _layers: Array[TerrainLayerData] = []
var _active_layer_index: int = 0

func add_layer(layer_data: TerrainLayerData) -> void:
    _layers.append(layer_data)
    layer_added.emit(layer_data)

func remove_layer(index: int) -> void:
    if index >= 0 and index < _layers.size():
        var removed := _layers.pop_at(index)
        layer_removed.emit(index)
        # 调整活动层索引
        if _active_layer_index >= _layers.size():
            _active_layer_index = max(0, _layers.size() - 1)

func move_layer(from_index: int, to_index: int) -> void:
    if from_index == to_index:
        return
    var layer := _layers.pop_at(from_index)
    _layers.insert(to_index, layer)
    layer_reordered.emit(from_index, to_index)

func get_active_layer() -> TerrainLayerData:
    if _layers.is_empty():
        return null
    return _layers[_active_layer_index]
```

#### 4.1.3 比Godot TileMap更灵活的方案

Godot 4.x的TileMapLayer在处理多层自定义数据时有局限，建议采用混合方案：

```
TileMapLayer (Godot原生) → 用于标准地形图块(性能最优)
CustomSpriteLayer (自定义) → 用于装饰和物件(灵活属性)
WallLineRenderer (自定义) → 用于墙壁线段渲染
```

---

### 4.2 楼层转换系统

#### 4.2.1 楼层概念

每个"楼层"是一个完整的二维平面，包含独立的地形图层、物件、墙壁、光源和迷雾状态。楼层之间通过z轴坐标区分。

#### 4.2.2 楼层切换逻辑

```gdscript
# floor_manager.gd
class_name FloorManager
extends Node

signal floor_switch_start(old_index: int, new_index: int)
signal floor_switch_complete(new_index: int)

var floors: Array[FloorData] = []
var _current_floor_index: int = 0

func switch_to_floor(index: int, transition_type: int = TransitionType.FADE) -> void:
    if index == _current_floor_index or index < 0 or index >= floors.size():
        return

    var old_index := _current_floor_index
    floor_switch_start.emit(old_index, index)

    match transition_type:
        TransitionType.INSTANT:
            _apply_floor_switch(index)
            floor_switch_complete.emit(index)
        TransitionType.FADE:
            _fade_transition(old_index, index)
        TransitionType.SLIDE:
            _slide_transition(old_index, index)

func _apply_floor_switch(index: int) -> void:
    # 保存当前楼层状态
    var old_floor := floors[_current_floor_index]

    # 切换
    _current_floor_index = index
    var new_floor := floors[_current_floor_index]

    # 通知各子系统切换楼层
    EventBus.floor_changed.emit(old_floor.floor_index, new_floor.floor_index)

enum TransitionType {
    INSTANT,   # 即时切换
    FADE,      # 淡入淡出
    SLIDE      # 滑动切换
}
```

#### 4.2.3 楼层可视化

- **楼层预览缩略图**：在楼层选择器中显示各楼层小地图
- **相邻楼层半透明叠加**：可选项，当前楼层的上/下一层以低透明度叠加显示
- **楼层颜色标记**：不同楼层用不同色温标记边界

#### 4.2.4 楼层间垂直连接

在墙壁层标记"楼梯/梯子"区域，这些区域在楼层切换时自动匹配：

```gdscript
# 楼梯连接点数据
class_name StairConnection
extends Resource

@export var from_floor: int
@export var from_position: Vector2i
@export var to_floor: int
@export var to_position: Vector2i
@export var stair_type: int = StairType.STAIRS

enum StairType {
    STAIRS,       # 楼梯(双向)
    LADDER_UP,    # 梯子(上)
    LADDER_DOWN,  # 梯子(下)
    SHAFT,        # 竖井(多楼层连接)
    RAMP          # 斜坡
}
```

---

### 4.3 传送门系统

#### 4.3.1 传送门类型

| 类型 | 描述 | 应用场景 |
|------|------|----------|
| 单向传送门 | 只能从A传送到B | 陷阱、秘密通道入口 |
| 双向传送门 | A和B可以互相传送 | 常规传送门 |
| 条件传送门 | 满足条件才触发 | 需要钥匙/技能的传送门 |
| 循环传送门 | 连接多个终点 | 迷宫传送 |
| 地图间传送门 | 跨地图文件传送 | 大世界的子区域连接 |

#### 4.3.2 传送门渲染

```gdscript
# portal_renderer.gd
class_name PortalRenderer
extends Node2D

# 传送门视觉表示：
# 1. 边框：发光虚线框/圆，颜色可自定义
# 2. 填充：半透明彩色区域（含波纹动画）
# 3. 标签：传送门名称浮动显示
# 4. 连接线：在编辑器模式下显示源→目标连线

func _draw() -> void:
    for portal in _active_portals:
        # 绘制传送门区域
        var rect := Rect2(portal.position * grid_size, portal.size * grid_size)
        draw_rect(rect, portal.visual_color, false, 2.0)
        draw_rect(rect, Color(portal.visual_color, 0.2), true)

        # 绘制方向指示
        _draw_portal_arrow(portal)

        # 绘制连接线(编辑器模式)
        if _editor_mode:
            _draw_connection_line(portal)
```

#### 4.3.3 传送门网络

```gdscript
# portal_manager.gd
class_name PortalManager
extends Node

signal portal_activated(portal_id: String, trigger_token: String)

var _portal_registry: Dictionary = {}  # portal_id -> PortalData
var _portal_pairs: Dictionary = {}     # 配对关系

func register_portal(portal: PortalData) -> void:
    _portal_registry[portal.portal_id] = portal

func create_portal_pair(portal_a: PortalData, portal_b: PortalData) -> void:
    register_portal(portal_a)
    register_portal(portal_b)
    _portal_pairs[portal_a.portal_id] = portal_b.portal_id
    if portal_a.is_bidirectional:
        _portal_pairs[portal_b.portal_id] = portal_a.portal_id

func get_destination(portal_id: String) -> PortalData:
    if not _portal_pairs.has(portal_id):
        return null
    return _portal_registry[_portal_pairs[portal_id]]

func execute_teleport(token: VisionTokenData, portal_id: String) -> void:
    var dest := get_destination(portal_id)
    if dest == null:
        return
    # 跨楼层
    if dest.target_floor != token.floor_index:
        EventBus.floor_changed.emit(token.floor_index, dest.target_floor)
    # 更新Token位置
    token.grid_position = dest.target_position
    token.floor_index = dest.target_floor
    portal_activated.emit(portal_id, token.token_id)
```

---

### 4.4 迷雾系统

#### 4.4.1 三种迷雾模式

**模式A：无迷雾 (None)**
- 整个地图完全可见
- 适用于不需要遮蔽的场景

**模式B：全局迷雾 (Global)**
- GM预设每个格子是否可见
- 不随玩家Token移动变化
- 适用于固定照明/固定视角的地图

**模式C：动态揭示迷雾 (Dynamic Revealed)** — 标准跑团模式
- 初始所有格子处于"未知"状态
- 玩家Token视野范围内的格子变为"当前可见"
- Token离开后格子变为"已探索"（显示地形但不见动态物件）
- 已探索的格子永久保留地形信息

#### 4.4.2 迷雾状态机

```
        ┌──────────┐
        │  UNKNOWN  │ 初始状态,完全不可见
        │  (未知)   │
        └─────┬────┘
              │ 进入视野范围
              ▼
        ┌──────────┐
        │  VISIBLE  │ 当前可见,地形和物件均可见
        │  (可见)   │
        └─────┬────┘
              │ 离开视野范围
              ▼
        ┌──────────────┐
        │  EXPLORED     │ 已探索,地形可见但物件隐藏
        │  (已探索)     │
        └──────────────┘
```

#### 4.4.3 迷雾渲染实现

```gdscript
# fog_manager.gd
class_name FogManager
extends Node2D

var _fog_grid: Dictionary = {}           # {String(cell): int}  状态
var _active_visible: Array[Vector2i] = [] # 当前帧可见格子
var _previous_visible: Array[Vector2i] = [] # 上一帧可见格子
var _fog_texture: ImageTexture           # 迷雾覆盖贴图
var _dirty: bool = true                  # 是否需要重绘

func _process(_delta: float) -> void:
    if _dirty:
        _render_fog()
        _dirty = false

func update_visibility(token_positions: Array[Vector2i]) -> void:
    _previous_visible = _active_visible.duplicate()
    _active_visible.clear()

    for token_pos in token_positions:
        var visible := _calculate_visible_cells(token_pos)
        for cell in visible:
            if not cell in _active_visible:
                _active_visible.append(cell)
            # 更新迷雾状态
            var key := _cell_to_key(cell)
            _fog_grid[key] = FogCellState.VISIBLE

    # 之前可见但现在不可见的 → 变为已探索
    for cell in _previous_visible:
        if not cell in _active_visible:
            var key := _cell_to_key(cell)
            if _fog_grid.get(key, FogCellState.UNKNOWN) == FogCellState.VISIBLE:
                _fog_grid[key] = FogCellState.EXPLORED

    _dirty = true

func _calculate_visible_cells(origin: Vector2i) -> Array[Vector2i]:
    # 使用递归阴影投射算法(Recursive Shadowcasting)
    # 这是最常用的跑团视野算法,O(n^2)复杂度,n为视野半径
    # 详见 4.6 视野系统
    return VisionManager.calculate_visibility(origin)

func _render_fog() -> void:
    # 使用Image动态生成迷雾贴图
    var image := Image.create(map_width, map_height, false, Image.FORMAT_RGBA8)

    for x in range(map_width):
        for y in range(map_height):
            var key := _cell_to_key(Vector2i(x, y))
            var state := _fog_grid.get(key, FogCellState.UNKNOWN)
            var color: Color
            match state:
                FogCellState.UNKNOWN:
                    color = Color(0, 0, 0, 1)        # 纯黑
                FogCellState.EXPLORED:
                    color = Color(0, 0, 0, 0.5)      # 半透明黑
                FogCellState.VISIBLE:
                    color = Color(0, 0, 0, 0)         # 完全透明
            image.set_pixel(x, y, color)

    _fog_texture = ImageTexture.create_from_image(image)
    queue_redraw()

func _draw() -> void:
    if _fog_texture:
        draw_texture_rect(_fog_texture,
            Rect2(Vector2.ZERO, Vector2(map_width, map_height) * grid_size),
            false)

enum FogCellState {
    UNKNOWN,   # 未知
    EXPLORED,  # 已探索
    VISIBLE    # 当前可见
}
```

#### 4.4.4 多人迷雾管理

每个玩家Token独立维护已探索格子集合：

```gdscript
# 多人模式下的迷雾
func update_player_visibility(player_id: String, token_positions: Array[Vector2i]) -> void:
    if not _player_fog.has(player_id):
        _player_fog[player_id] = {
            "explored": {},
            "visible": []
        }

    var player_data := _player_fog[player_id]
    # 更新该玩家的可见区域
    # 已探索区域只增不减
    for cell in visible_cells:
        var key := _cell_to_key(cell)
        player_data.explored[key] = true

    # 渲染时可以选择渲染某个玩家的视角,
    # 或合并所有玩家的可见区域
```

---

### 4.5 光源系统

#### 4.5.1 光源类型

| 类型 | 示意图 | 参数 |
|------|--------|------|
| 点光源 (Point) | 全向辐射 | 位置、半径、衰减 |
| 锥光源 (Cone) | 扇形 | 位置、半径、内角、外角、方向 |
| 方向光 (Directional) | 统一方向 | 方向、强度 |
| 环境光 (Ambient) | 全局 | 颜色、强度 |

#### 4.5.2 光源与迷雾交互

```
光照状态(每格) = f(光源可见性, 迷雾状态, 障碍遮挡)

规则:
- 如果格子是VISIBLE或EXPLORED:
    - 该格基础光照 = 环境光
    - 对每个光源,如果该格在光源范围内且未被障碍遮挡:
        - 该格光照 += 光源贡献
- 如果格子是UNKNOWN:
    - 光照 = 0 (不计算,因为不可见)

最终渲染: 地形颜色 × 光照颜色
```

#### 4.5.3 光源实现

```gdscript
# light_manager.gd
class_name LightManager
extends Node2D

var _light_sources: Array[LightData] = []
var _light_buffers: Dictionary = {}  # floor_index -> Image (光照贴图)
var _static_lights_baked: bool = false

func add_light_source(light: LightData) -> void:
    _light_sources.append(light)
    if light.is_static:
        _bake_static_lights(light.floor_index)
    _update_light_buffer(light.floor_index)

func remove_light_source(light_id: String) -> void:
    _light_sources = _light_sources.filter(func(l): return l.light_id != light_id)
    # 需要在所有涉及的楼层重建光照

func _bake_static_lights(floor_index: int) -> void:
    # 预计算静态光源的光照贴图
    # 在编辑器中提供"烘焙光照"按钮
    pass

func calculate_light_at(cell: Vector2i, floor_index: int) -> Color:
    var total_light := Color.BLACK
    for light in _light_sources:
        if light.floor_index != floor_index:
            continue
        if not _is_cell_in_light_range(cell, light):
            continue
        if ObstacleManager.is_light_blocked(cell, light.grid_position, floor_index):
            continue

        var contribution := _calculate_light_contribution(cell, light)
        total_light += contribution

    return total_light

func _calculate_light_contribution(cell: Vector2i, light: LightData) -> Color:
    var dist := cell.distance_to(light.grid_position)
    var attenuation := 1.0

    match light.light_type:
        LightData.LightType.POINT:
            attenuation = 1.0 / (1.0 + light.falloff * dist * dist)
        LightData.LightType.CONE:
            var to_cell := (Vector2(cell) - Vector2(light.grid_position)).normalized()
            var facing := Vector2.RIGHT.rotated(deg_to_rad(light.rotation))
            var angle := rad_to_deg(to_cell.angle_to(facing))
            if abs(angle) > light.outer_angle / 2.0:
                return Color.BLACK
            if abs(angle) < light.inner_angle / 2.0:
                attenuation = 1.0 / (1.0 + light.falloff * dist * dist)
            else:
                # 在内外角之间渐变
                var t := (abs(angle) - light.inner_angle / 2.0) / ((light.outer_angle - light.inner_angle) / 2.0)
                attenuation = lerp(1.0, 0.0, t) / (1.0 + light.falloff * dist * dist)

    var base_color := light.color * light.intensity * attenuation
    return base_color

func _is_cell_in_light_range(cell: Vector2i, light: LightData) -> bool:
    var dist := cell.distance_to(light.grid_position)
    return dist <= light.radius
```

#### 4.5.4 光源渲染方案

使用 Godot 的 `Light2D` 节点或自定义Shader：

```gdscript
# 方案一: 使用Godot Light2D(灵活性较低)
# 每个光源创建一个PointLight2D节点
# 用LightOccluder2D做遮挡

# 方案二(推荐): 自定义Shader光照
# 在CanvasItem的_draw中使用Shader
# 更灵活,支持复杂的光照计算和与迷雾系统整合

# 光照Shader(片段):
shader_type canvas_item;

uniform sampler2D light_map;     // 光照贴图
uniform sampler2D fog_map;       // 迷雾贴图
uniform vec4 ambient_color: source_color;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    vec4 light_color = texture(light_map, UV);
    vec4 fog = texture(fog_map, UV);

    // 光照计算
    vec4 lit = tex_color * (ambient_color + light_color);
    // 迷雾混合
    COLOR = mix(fog * tex_color, lit, 1.0 - fog.a);
}
```

---

### 4.6 视野系统

#### 4.6.1 视野计算算法

跑团游戏中最常用的视野算法是**递归阴影投射 (Recursive Shadowcasting)**：

```
算法原理:
从观察点出发,将360度(或指定弧度)分为8个八分象限(Octant),
在每个八分象限内递归处理,维护当前扫描线的"阴影角度"范围,
遇到障碍物则缩小可扫描角度。

优点:
- O(n^2)复杂度(n为视野半径)
- 结果精确,支持任意形状障碍
- 适合方形网格
- 可以处理全向和锥形视野

八分象限布局:
  \ 6|7 /
  5 \|/ 0
  ---+---
  4 /|\ 1
  / 3|2 \
```

#### 6.4.2 递归阴影投射实现

```gdscript
# vision_manager.gd - 视野计算核心
class_name VisionManager
extends RefCounted

# 八分象限转换表
const OCTANT_TRANSFORM := [
    # (xx, xy, yx, yy) 用于转换到对应八分象限
    [ 1,  0,  0,  1],  # Octant 0
    [ 0,  1,  1,  0],  # Octant 1
    [ 0, -1,  1,  0],  # Octant 2
    [-1,  0,  0,  1],  # Octant 3
    [-1,  0,  0, -1],  # Octant 4
    [ 0, -1, -1,  0],  # Octant 5
    [ 0,  1, -1,  0],  # Octant 6
    [ 1,  0,  0, -1],  # Octant 7
]

class ShadowCastData:
    var origin: Vector2i
    var range: int
    var visible_cells: Array[Vector2i]
    var obstacles: Callable          # func(cell) -> bool (是否阻挡视野)
    var visit_cell: Callable         # func(cell) 将格标记为可见
    var arc_start: float = 0.0      # 视野起始角度(弧度制)
    var arc_width: float = TAU      # 视野宽度(弧度制)

static func calculate_visibility(data: ShadowCastData) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    result.append(data.origin)  # 原点总是可见

    for octant in range(8):
        # 检查该八分象限是否在视野弧内
        var octant_angle := float(octant) * PI / 4.0
        if not _is_octant_in_arc(octant_angle, data.arc_start, data.arc_width):
            continue

        _cast_octant(data, octant, data.origin, data.range,
                     1, 1.0, 0.0, result)

    return result

static func _cast_octant(data: ShadowCastData, octant: int,
                         origin: Vector2i, _range: int,
                         col: int, top_slope: float, bottom_slope: float,
                         result: Array[Vector2i]) -> void:
    if top_slope < bottom_slope:
        return

    var transform := OCTANT_TRANSFORM[octant]
    var xx := transform[0]; var xy := transform[1]
    var yx := transform[2]; var yy := transform[3]

    var was_blocked := false

    for y in range(col, _range + 1):
        for x in range(y + 1):
            var map_x := origin.x + x * xx + y * xy
            var map_y := origin.y + x * yx + y * yy
            var cell := Vector2i(map_x, map_y)
            var dist2 := x * x + y * y

            if dist2 > _range * _range:
                # 超出范围,但需要检查当前列是否还有部分在范围内
                continue

            # 计算该格相对于观察点的斜率范围
            var bottom := float(2 * y - 1) / float(2 * x) if x > 0 else -INF
            var top := float(2 * y + 1) / float(2 * x) if x > 0 else INF

            # 检查是否在可扫描范围内
            if top < bottom_slope:
                continue
            if bottom > top_slope:
                continue

            if data.obstacles.call(cell):
                # 该格阻挡视野
                if not was_blocked:
                    # 第一次遇到阻挡,递归扫描后续列
                    _cast_octant(data, octant, origin, _range,
                                y + 1, top_slope, bottom, result)
                was_blocked = true
            else:
                # 该格不阻挡,标记为可见
                result.append(cell)
                if was_blocked:
                    # 之前有阻挡,现在遇到了空隙,更新top_slope
                    # (之前的阻挡在上面投下阴影)
                    top_slope = top
                    was_blocked = false
```

#### 4.6.3 优化策略

```gdscript
# 1. 增量更新
# 只在Token移动时重新计算该Token的视野
# 静态场景不需要每帧重新计算

# 2. 视野缓存
var _visibility_cache: Dictionary = {}  # {token_id: {position: [cells]}}
# 如果Token回到之前的位置,直接使用缓存

# 3. 脏区域更新
var _dirty_tokens: Array[String] = []  # 需要重新计算的Token
# 当光源/墙壁改变时,标记受影响的Token

# 4. 分层计算
# 先计算光源照明区域
# 再计算Token视野区域
# 最后合并得到每个Token实际看到的画面
```

#### 4.6.4 视野与光源的协同

```
玩家实际看到的画面 = 视野 ∩ 光照

伪代码:
for token in all_tokens:
    visible_cells = calculate_visibility(token)
    for cell in visible_cells:
        light_level = calculate_light(cell)
        final_visibility[token][cell] = (cell_state, light_level)

渲染:
    对每个格子:
        if 格子不在任何Token的视野内:
            按迷雾状态渲染(未知/已探索)
        else:
            按计算的光照水平渲染
            应用光源颜色
```

---

### 4.7 遮挡物系统

#### 4.7.1 遮挡物属性(位标志)

```gdscript
# obstacle_flags.gd
enum ObstacleFlags {
    NONE            = 0,
    BLOCK_VISION    = 1 << 0,   # 阻挡视野 (0x01)
    BLOCK_LIGHT     = 1 << 1,   # 阻挡光源 (0x02)
    BLOCK_PROJECTILE = 1 << 2,  # 阻挡抛物线技能 (0x04)
    BLOCK_MOVEMENT  = 1 << 3,   # 阻挡移动 (0x08)
    BLOCK_FLYING    = 1 << 4,   # 阻挡飞行 (0x10)
    BLOCK_BURROWING = 1 << 5,   # 阻挡掘地 (0x20)
}
```

#### 4.7.2 遮挡物理属性

每个遮挡物除了阻挡标志外,还有物理属性用于计算:

```gdscript
# obstacle_properties.gd
class_name ObstacleProperties
extends Resource

@export var flags: int = ObstacleFlags.BLOCK_VISION | ObstacleFlags.BLOCK_MOVEMENT
@export var height: float = 2.0           # 高度(米)
@export var thickness: int = 1             # 厚度(格子)
@export var material_type: int = MaterialType.STONE
@export var projectile_deflection: float = 0.0  # 偏转率(0=完全吸收,1=完全反弹)
@export var wall_ac: int = 5               # 墙壁护甲等级(破坏墙体时)
@export var wall_hp: int = 50              # 墙壁生命值
@export var hardness: int = 8              # 硬度(DND风格)

enum MaterialType {
    WOOD,        # 木质
    STONE,       # 石质
    METAL,       # 金属
    GLASS,       # 玻璃(允许视野,阻挡移动)
    FORCE,       # 力场(可选阻挡类型)
    ORGANIC      # 有机(藤蔓/蛛网)
}
```

#### 4.7.3 抛物线技能阻挡计算

```gdscript
# projectile_obstacle.gd
# 计算抛物线技能(如火球术)的轨迹是否被阻挡

static func is_projectile_blocked(
    origin: Vector3,        # 起始位置(含高度)
    target: Vector3,        # 目标位置(含高度)
    obstacles: Array[WallSegmentData],
    floor_index: int
) -> bool:
    # 使用射线检测,在3D空间中检测抛物线路径
    # 简化版: 检测从origin到target的直线
    # 完整版: 沿抛物线采样多个点检测

    var ray_origin := Vector2(origin.x, origin.y)
    var ray_end := Vector2(target.x, target.y)

    for obstacle in obstacles:
        if (obstacle.block_flags & ObstacleFlags.BLOCK_PROJECTILE) == 0:
            continue

        # 检查高度
        if origin.z > obstacle.height and target.z > obstacle.height:
            # 弹道全程高于障碍物,不阻挡
            continue

        # 检查射线与墙壁线段的交点
        if _ray_intersects_wall(ray_origin, ray_end, obstacle):
            return true

    return false

static func _ray_intersects_wall(
    origin: Vector2, target: Vector2, wall: WallSegmentData
) -> bool:
    var wall_start := Vector2(wall.start_point)
    var wall_end := Vector2(wall.end_point)
    var intersection := Geometry2D.segment_intersects_segment(
        origin, target, wall_start, wall_end
    )
    return intersection != null

# 抛物线轨迹可视化(调试/编辑器用)
static func get_projectile_arc(
    start: Vector3, velocity: Vector3, gravity: float,
    obstacles: Array[WallSegmentData]
) -> Array[Vector3]:
    var points: Array[Vector3] = []
    var pos := start
    var vel := velocity
    var dt := 0.05
    var time := 0.0

    while time < 5.0 and pos.y >= 0:
        points.append(pos)
        vel.y -= gravity * dt
        pos += vel * dt
        time += dt

        # 检测碰撞
        for obs in obstacles:
            if (obs.block_flags & ObstacleFlags.BLOCK_PROJECTILE) != 0:
                if pos.y < obs.height:
                    var pos2d := Vector2(pos.x, pos.z)
                    if _point_near_wall(pos2d, obs):
                        points.append(pos)  # 记录碰撞点
                        return points

    return points
```

#### 4.7.4 遮挡物在视野计算中的调用

```gdscript
# 视野计算时调用遮挡物检测
func _is_vision_blocked(cell: Vector2i) -> bool:
    # 检查该格子是否有阻挡视野的遮挡物
    var walls := ObstacleManager.get_walls_at_cell(cell)
    for wall in walls:
        if wall.block_flags & ObstacleFlags.BLOCK_VISION:
            return true
    return false

# 光源计算时调用遮挡物检测
func _is_light_blocked(from_cell: Vector2i, to_cell: Vector2i) -> bool:
    # 使用Bresenham线检测算法
    var cells := _bresenham_line(from_cell, to_cell)
    for cell in cells:
        if cell == from_cell:
            continue
        var walls := ObstacleManager.get_walls_at_cell(cell)
        for wall in walls:
            if wall.block_flags & ObstacleFlags.BLOCK_LIGHT:
                return true
    return false

func _bresenham_line(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var x0 := start.x; var y0 := start.y
    var x1 := end.x; var y1 := end.y
    var dx := abs(x1 - x0)
    var dy := -abs(y1 - y0)
    var sx := 1 if x0 < x1 else -1
    var sy := 1 if y0 < y1 else -1
    var err := dx + dy

    while true:
        result.append(Vector2i(x0, y0))
        if x0 == x1 and y0 == y1:
            break
        var e2 := 2 * err
        if e2 >= dy:
            if x0 == x1: break
            err += dy
            x0 += sx
        if e2 <= dx:
            if y0 == y1: break
            err += dx
            y0 += sy

    return result
```

---

## 5. 文件格式与导入导出

### 5.1 原生格式 .trpgmap (JSON-based)

```json
{
  "format_version": "1.0.0",
  "format_type": "trpg_map",
  "metadata": {
    "map_name": "龙之洞窟-第一层",
    "author": "GM_Name",
    "created_date": "2026-06-20T10:00:00+08:00",
    "modified_date": "2026-06-20T14:30:00+08:00",
    "description": "一个黑暗的洞穴入口",
    "rulebook": "DND5e",
    "grid_type": "square",
    "grid_size": 32,
    "map_width": 50,
    "map_height": 40
  },
  "tilesets": [
    {
      "id": "ts_cave_01",
      "name": "洞穴图块集",
      "source": "res://assets/tilesets/cave_01.tres",
      "tile_size": 32
    }
  ],
  "floors": [
    {
      "index": 0,
      "name": "洞穴入口",
      "elevation": 0,
      "terrain_layers": [
        {
          "index": 0,
          "name": "地面",
          "tileset_ref": "ts_cave_01",
          "tiles": {
            "0,0": {"id": 1, "flip_h": false, "flip_v": false},
            "1,0": {"id": 2, "flip_h": false, "flip_v": false}
          }
        }
      ],
      "objects": [
        {
          "id": "obj_001",
          "type": "chest",
          "display_name": "宝箱",
          "grid_position": [5, 10],
          "rotation": 0,
          "properties": {"locked": true, "dc": 15}
        }
      ],
      "walls": [
        {
          "id": "wall_001",
          "start": [0, 0],
          "end": [10, 0],
          "type": "solid",
          "height": 3.0,
          "block_flags": ["vision", "light", "projectile", "movement"]
        }
      ]
    }
  ],
  "portals": [
    {
      "id": "portal_001",
      "name": "前往地下二层",
      "source_floor": 0,
      "source_position": [25, 39],
      "target_floor": 1,
      "target_position": [25, 1],
      "bidirectional": true,
      "trigger": "walk_on"
    }
  ],
  "lights": [
    {
      "id": "light_001",
      "floor": 0,
      "position": [10, 15],
      "type": "point",
      "intensity": 1.0,
      "color": "#FFD700",
      "radius": 6.0,
      "falloff": 0.5,
      "dynamic": false
    }
  ],
  "fog": {
    "enabled": true,
    "type": "revealed",
    "fog_color": "#0D0D0DE6",
    "unexplored_color": "#000000FF",
    "explored_color": "#0D0D0DB3",
    "cells": {
      "0,0": 0,
      "0,1": 1
    }
  },
  "vision_tokens": [
    {
      "id": "token_pc1",
      "floor": 0,
      "position": [5, 5],
      "vision_range": 6,
      "vision_arc": 360,
      "darkvision": 60
    }
  ],
  "stairs": [
    {
      "from_floor": 0,
      "from_position": [30, 20],
      "to_floor": 1,
      "to_position": [30, 20],
      "type": "stairs"
    }
  ]
}
```

### 5.2 导入格式支持

#### 5.2.1 DungeonDraft (Universal VTT 格式)

DungeonDraft导出`.dd2vtt`格式,本质是包含地图数据的JSON文件。

```
.dd2vtt 结构:
├── format: 版本号
├── resolution: {map_size, pixels_per_grid}
├── line_of_sight: [墙壁线条]           → 转换为 WallSegmentData
├── portals: [传送门]                    → 转换为 PortalData
├── lights: [光源]                      → 转换为 LightData
├── image: 地图背景图(base64)
└── image_atlas: 切分信息(可选)
```

#### 5.2.2 通用VTT (Universal VTT / .uvtt)

FoundryVTT使用的通用格式,类似.dd2vtt但更标准化。

#### 5.2.3 Old-School Essentials / OSR地图格式

ASCII地图(文本地图)导入:
```
############
#....#.....#
#....#.....#
#....###...#
#..........#
############

图例:
# = 墙壁
. = 地板
+ = 门
> = 下楼楼梯
< = 上楼楼梯
```

#### 5.2.4 图片地图导入

对于没有矢量数据的纯图片地图:
- 导入为单层背景图
- 提供半自动墙壁检测(通过算法或手动描边)
- 手动放置光源/传送门/Token起点

#### 5.2.5 Tiled Map Editor (.tmx/.tsx)

Tiled是独立开源地图编辑器,其TMX格式支持多层TileMap。

### 5.3 导出格式支持

| 格式 | 用途 |
|------|------|
| .trpgmap | 原生格式,保留所有编辑器数据 |
| .json | 纯数据导出,不含资源引用 |
| .png | 地图截图为图片(可用于打印) |
| .uvtt | 通用VTT格式(导入FoundryVTT等) |
| .tmx | Tiled Map Editor格式 |
| .pdf | 打印用PDF地图 |

### 5.4 导入导出管理器

```gdscript
# serialization_manager.gd
class_name SerializationManager
extends Node

signal import_started(format: String)
signal import_completed(map_data: MapData)
signal import_failed(error: String)
signal export_started(format: String)
signal export_completed(file_path: String)
signal export_failed(error: String)

# 注册的导入器
var _importers: Dictionary = {
    "trpgmap": TRPGMapImporter.new(),
    "dd2vtt": DungeonDraftImporter.new(),
    "uvtt": UVTTImporter.new(),
    "tmx": TiledImporter.new(),
    "ascii": ASCIIMapImporter.new(),
    "image": ImageMapImporter.new(),
}

# 注册的导出器
var _exporters: Dictionary = {
    "trpgmap": TRPGMapExporter.new(),
    "json": JSONExporter.new(),
    "png": PNGExporter.new(),
    "uvtt": UVTTExporter.new(),
    "tmx": TiledExporter.new(),
    "pdf": PDFExporter.new(),
}

func import_map(file_path: String, format: String = "") -> MapData:
    if format.is_empty():
        format = _detect_format(file_path)

    if not _importers.has(format):
        import_failed.emit("不支持的导入格式: %s" % format)
        return null

    import_started.emit(format)
    var importer: MapImporter = _importers[format]
    var result := importer.import_file(file_path)

    if result:
        import_completed.emit(result)
    else:
        import_failed.emit("导入失败")

    return result

func export_map(map_data: MapData, file_path: String, format: String) -> bool:
    if not _exporters.has(format):
        export_failed.emit("不支持的导出格式: %s" % format)
        return false

    export_started.emit(format)
    var exporter: MapExporter = _exporters[format]
    var success := exporter.export_to_file(map_data, file_path)

    if success:
        export_completed.emit(file_path)
    else:
        export_failed.emit("导出失败")

    return success

func _detect_format(file_path: String) -> String:
    var ext := file_path.get_extension().to_lower()
    match ext:
        "trpgmap": return "trpgmap"
        "dd2vtt": return "dd2vtt"
        "uvtt": return "uvtt"
        "tmx": return "tmx"
        "txt", "asc": return "ascii"
        "png", "jpg", "jpeg", "webp": return "image"
        _: return ""
```

---

## 6. 编辑器UI设计

### 6.1 主界面布局

```
┌─────────────────────────────────────────────────────┐
│  Menu Bar: File Edit View Tools Help                │
├──────────┬────────────────────────────┬─────────────┤
│ Toolbar  │                            │  Layer      │
│ ┌──────┐ │                            │  Panel      │
│ │Select│ │                            │ ┌─────────┐ │
│ │Brush │ │      地图编辑区域           │ │✓ 迷雾层  │ │
│ │Line  │ │                            │ │✓ 光源层  │ │
│ │Rect  │ │     (可缩放/平移)          │ │✓ 墙壁层  │ │
│ │Fill  │ │                            │ │✓ 物件层  │ │
│ │Eraser│ │                            │ │✓ 装饰层  │ │
│ │- - - │ │                            │ │✓ 地形层  │ │
│ │Wall  │ │                            │ │✓ 背景层  │ │
│ │Portal│ │                            │ └─────────┘ │
│ │Light │ │                            │             │
│ │Fog   │ │                            │  Tile       │
│ │Token │ │                            │  Palette    │
│ └──────┘ │                            │ ┌─────────┐ │
│          │                            │ │[tile][t]│ │
│ Floor    │                            │ │[ile][til│ │
│ Selector │                            │ │[e][tile]│ │
│ ┌──────┐ │                            │ │[tile][t]│ │
│ │B1 B2 │ │                            │ └─────────┘ │
│ │1F 2F │ │                            │             │
│ │3F 4F │ │                            │ Properties  │
│ └──────┘ │                            │ ┌─────────┐ │
│          │                            │ │ Name:...│ │
├──────────┴────────────────────────────┤ │ Type:...│ │
│  Status Bar: Position | Grid | Zoom   │ │ Flags:..│ │
└───────────────────────────────────────┘ └─────────┘
```

### 6.2 工具栏详情

| 工具 | 图标 | 功能描述 | 快捷键 |
|------|------|----------|--------|
| 选择工具 | 箭头 | 选中图块/物件/墙壁进行移动/编辑 | S |
| 笔刷工具 | 笔刷 | 在TileMap上绘制图块 | B |
| 直线工具 | 斜线 | 绘制墙壁线段 | L |
| 矩形工具 | 矩形 | 矩形区域填充/选择 | R |
| 填充工具 | 油漆桶 | 填充连通区域 | G |
| 橡皮擦 | 橡皮 | 擦除图块/物件 | E |
| 墙壁工具 | 墙 | 放置墙壁线段 | W |
| 传送门工具 | 门 | 放置传送门 | P |
| 光源工具 | 灯泡 | 放置光源 | I |
| 迷雾工具 | 云 | 编辑迷雾区域 | F |
| Token工具 | 棋子 | 放置视野Token | T |
| 测量工具 | 尺子 | 测量距离 | M |

### 6.3 属性检查器

选中不同对象时显示对应的属性面板：

```
选中墙壁时:
┌─ 属性 ──────────────┐
│ 类型: [实心墙  ▼]   │
│ 起点: (10, 5)       │
│ 终点: (15, 5)       │
│ 高度: [3.0] 米      │
│ 厚度: [1]   格      │
│ 阻挡:               │
│  ☑ 视野  ☑ 光源    │
│  ☑ 抛物线 ☑ 移动   │
│  ☐ 飞行  ☐ 掘地    │
│ 材质: [石质  ▼]     │
│ AC:  [5]            │
│ HP:  [50]           │
└─────────────────────┘

选中光源时:
┌─ 属性 ──────────────┐
│ 名称: [火把]        │
│ 类型: [点光源 ▼]    │
│ 颜色: [████████]    │
│ 强度: [1.0] ────○── │
│ 半径: [6.0] 格      │
│ 衰减: [0.5]         │
│ ☐ 动态光源          │
│ ☐ 闪烁效果          │
└─────────────────────┘

选中传送门时:
┌─ 属性 ──────────────┐
│ 名称: [传送门]      │
│ 源楼层: [0]         │
│ 源位置: (25, 39)    │
│ 目标楼层: [1]       │
│ 目标位置: (25, 1)   │
│ ☑ 双向传送          │
│ 触发: [走入 ▼]      │
│ 颜色: [████████]    │
│ 标签: [前往地下]    │
└─────────────────────┘
```

### 6.4 楼层选择器

```
┌── 楼层 ─────────────┐
│                     │
│  ┌────────────────┐ │
│  │    预览缩略图   │ │ <- 3F (当前)
│  └────────────────┘ │
│       ▲ 上移        │
│  ┌────────────────┐ │
│  │    预览缩略图   │ │ <- 2F
│  └────────────────┘ │
│  ┌────────────────┐ │
│  │    预览缩略图   │ │ <- 1F
│  └────────────────┘ │
│                     │
│  [+ 添加楼层]      │
│  [复制楼层]        │
│  [删除楼层]        │
│                     │
│  ☐ 显示相邻楼层    │
│  透明度: [30%]     │
└─────────────────────┘
```

### 6.5 右键菜单

```
在编辑区域右键:
┌──────────────────┐
│ 放置墙壁         │
│ 放置传送门       │
│ 放置光源         │
│ 放置Token        │
│ ──────────────── │
│ 复制             │
│ 粘贴             │
│ ──────────────── │
│ 设置迷雾为可见   │
│ 设置迷雾为未知   │
│ 清除迷雾         │
│ ──────────────── │
│ 从此格计算视野   │
│ 显示Bresenham线  │
└──────────────────┘
```

### 6.6 编辑模式

#### 6.6.1 编辑模式
- 所有工具可用
- 网格显示
- 可修改所有属性
- 迷雾/光源预览

#### 6.6.2 预览模式
- 以玩家视角查看当前地图
- 根据选中Token显示可见范围
- 激活迷雾遮蔽
- 可移动Token测试视野

#### 6.6.3 运行模式
- 用于实际跑团时的地图展示
- 连接网络多人同步
- (后期集成)

---

## 7. 开发路线图

### Phase 0: 项目基础设施 (预计: 1-2周)

**目标**: 搭建项目骨架,建立基本编辑功能

- [x] 创建Godot 4.x项目
- [x] 配置项目结构(scenes/, scripts/, assets/, tests/)
- [x] 实现基础UI框架(菜单栏、工具栏、状态栏)
- [x] 实现地图数据模型(MapData, FloorData, TerrainLayerData)
- [x] 实现GridBase的基础绘制(可缩放、平移的网格视图)
- [x] 实现基础TileMap编辑(放置/擦除图块)
- [x] 实现图层管理(添加/删除/重排/显示隐藏)
- [x] 实现基础文件保存(.trpgmap格式 v1)
- [x] 实现基础文件打开
- [x] Windows/Linux/macOS导出测试
- [x] 建立单元测试框架(GUT)

### Phase 1: 核心地图编辑 (预计: 3-4周)

**目标**: 完善地图编辑功能,实现楼层系统

- [ ] 完善TileMap编辑(多种放置模式:单格/直线/矩形/填充)
- [ ] 物体放置系统(家具、道具)
- [ ] 墙壁编辑器(线段绘制、墙类型设置)
- [ ] 楼层管理系统
  - [ ] 添加/删除/复制楼层
  - [ ] 楼层切换(即时/淡入淡出)
  - [ ] 楼梯连接定义
  - [ ] 楼层预览缩略图生成
- [ ] 楼层间可视化(相邻楼层半透明叠加)
- [ ] 网格系统完善(方形/六角切换)
- [ ] 坐标系工具(网格坐标与世界坐标转换)
- [ ] 撤销/重做系统(基于Command模式)
- [ ] 剪贴板系统(复制/粘贴/剪切选定区域)
- [ ] 对齐网格功能

### Phase 2: 传送门与遮挡物 (预计: 2-3周)

**目标**: 实现传送系统和遮挡物标签

- [ ] 传送门系统
  - [ ] 传送门数据结构实现
  - [ ] 传送门放置编辑器
  - [ ] 传送门渲染(波纹动画)
  - [ ] 传送门配对管理
  - [ ] 跨楼层/跨地图传送
  - [ ] 传送门连接线可视(编辑器模式)
- [ ] 遮挡物系统
  - [ ] 墙壁段属性编辑器(位标志)
  - [ ] 不同类型墙壁的渲染差异
  - [ ] 阻挡标志可视化(编辑器叠加显示)
  - [ ] 抛物线轨迹预览工具
- [ ] 物件属性完善(碰撞形状)
- [ ] 区域选择工具改进

### Phase 3: 迷雾与视野 (预计: 3-4周)

**目标**: 实现动态迷雾和视野计算

- [ ] 递归阴影投射算法实现
- [ ] 迷雾系统
  - [ ] 3种迷雾模式实现
  - [ ] 迷雾网格存储
  - [ ] 实时迷雾渲染(Image动态生成)
  - [ ] 迷雾编辑器(手动揭示/隐藏区域)
  - [ ] 迷雾过渡动画
- [ ] 视野系统
  - [ ] 视野Token管理
  - [ ] 视野范围计算(结合遮挡)
  - [ ] 锥形视野(有向)
  - [ ] 暗视觉/微光视觉
  - [ ] 视野缓存优化
- [ ] 预览模式(玩家视角)
  - [ ] 选择Token预览其可见范围
  - [ ] 迷雾+视野综合渲染

### Phase 4: 光源系统 (预计: 2-3周)

**目标**: 实现光源模拟

- [ ] 光源数据结构实现
- [ ] 光源放置编辑器
- [ ] 光照计算(衰减、锥形)
- [ ] 光照Shader实现
- [ ] 静态光源烘焙
- [ ] 动态光源实时计算
- [ ] 光源与迷雾交互渲染
- [ ] 光源编辑器可视化(范围圈/锥形指示)
- [ ] 闪烁效果
- [ ] 光照颜色与地形颜色混合

### Phase 5: 导入导出 (预计: 2-3周)

**目标**: 实现多格式兼容

- [ ] 完善原生.trpgmap格式(含所有子系统数据)
- [ ] JSON纯数据导出
- [ ] PNG地图导出(截图)
  - [ ] 可选:按玩家视角(含迷雾)/GM视角(不含迷雾)
- [ ] DungeonDraft .dd2vtt导入
- [ ] Universal VTT .uvtt导入
- [ ] Tiled .tmx导入导出
- [ ] ASCII地图导入
- [ ] 图片地图导入(含半自动墙壁检测)
- [ ] 批量导入/导出
- [ ] 导入预览对话框

### Phase 6: 优化与完善 (预计: 2-3周)

**目标**: 性能优化,Android适配,打包

- [ ] 大型地图性能优化(>200x200格子)
  - [ ] Chunk分块加载
  - [ ] 视野计算优化
  - [ ] 迷雾渲染优化
- [ ] Android触屏适配
  - [ ] 双指缩放/平移
  - [ ] 长按替代右键
  - [ ] 触屏友好的UI尺寸
  - [ ] 虚拟摇杆/方向键
- [ ] UI/UX打磨
  - [ ] 图标设计
  - [ ] 动画过渡
  - [ ] 快捷键自定义
- [ ] 国际化支持(i18n)
  - [ ] 中文
  - [ ] 英文
- [ ] 打包配置
  - [ ] Windows (.exe)
  - [ ] Linux (.AppImage / .deb)
  - [ ] macOS (.app / .dmg)
  - [ ] Android (.apk)

### Phase 7: 测试与文档 (预计: 1-2周)

**目标**: 稳定性验证和用户文档

- [ ] 单元测试覆盖率 > 70%
  - [ ] 数据序列化测试
  - [ ] 视野算法测试
  - [ ] 光照计算测试
  - [ ] 导入导出格式测试
- [ ] 集成测试
  - [ ] 完整编辑工作流测试
  - [ ] 导入导出往返测试
- [ ] 性能基准测试
- [ ] 用户手册
- [ ] 开发者文档(API参考)
- [ ] 示例地图包

---

## 8. 技术实现要点

### 8.1 Godot项目结构

```
trpg-map-editor/
├── project.godot
├── assets/
│   ├── tilesets/          # 图块集资源
│   ├── sprites/           # 精灵/物件图片
│   ├── shaders/           # 自定义Shader
│   │   ├── fog.gdshader
│   │   ├── light.gdshader
│   │   └── portal.gdshader
│   ├── fonts/             # 字体
│   ├── icons/             # UI图标
│   └── themes/            # UI主题
├── scenes/
│   ├── editor/
│   │   ├── map_editor.tscn
│   │   ├── tool_bar.tscn
│   │   ├── layer_panel.tscn
│   │   ├── property_inspector.tscn
│   │   ├── tile_palette.tscn
│   │   └── floor_selector.tscn
│   ├── map/
│   │   ├── map_viewport.tscn
│   │   ├── terrain_layer.tscn
│   │   ├── wall_layer.tscn
│   │   └── portal_layer.tscn
│   └── dialogs/
│       ├── import_dialog.tscn
│       ├── export_dialog.tscn
│       ├── new_map_dialog.tscn
│       └── settings_dialog.tscn
├── scripts/
│   ├── autoload/
│   │   ├── event_bus.gd
│   │   ├── config_manager.gd
│   │   └── undo_redo_manager.gd
│   ├── core/
│   │   ├── map_core_manager.gd
│   │   ├── floor_manager.gd
│   │   ├── layer_manager.gd
│   │   ├── portal_manager.gd
│   │   ├── light_manager.gd
│   │   ├── fog_manager.gd
│   │   ├── vision_manager.gd
│   │   └── obstacle_manager.gd
│   ├── data/
│   │   ├── map_data.gd
│   │   ├── floor_data.gd
│   │   ├── terrain_layer_data.gd
│   │   ├── map_object_data.gd
│   │   ├── wall_segment_data.gd
│   │   ├── portal_data.gd
│   │   ├── light_data.gd
│   │   ├── fog_data.gd
│   │   ├── vision_token_data.gd
│   │   └── rulebook_reference.gd
│   ├── serialization/
│   │   ├── serialization_manager.gd
│   │   ├── importers/
│   │   │   ├── map_importer.gd          # 基类
│   │   │   ├── trpgmap_importer.gd
│   │   │   ├── dungeondraft_importer.gd
│   │   │   ├── uvtt_importer.gd
│   │   │   ├── tiled_importer.gd
│   │   │   ├── ascii_map_importer.gd
│   │   │   └── image_map_importer.gd
│   │   └── exporters/
│   │       ├── map_exporter.gd           # 基类
│   │       ├── trpgmap_exporter.gd
│   │       ├── json_exporter.gd
│   │       ├── png_exporter.gd
│   │       ├── uvtt_exporter.gd
│   │       ├── tiled_exporter.gd
│   │       └── pdf_exporter.gd
│   ├── rendering/
│   │   ├── grid_renderer.gd
│   │   ├── wall_renderer.gd
│   │   ├── portal_renderer.gd
│   │   ├── light_renderer.gd
│   │   ├── fog_renderer.gd
│   │   └── selection_renderer.gd
│   ├── tools/
│   │   ├── brush_tool.gd
│   │   ├── wall_tool.gd
│   │   ├── portal_tool.gd
│   │   ├── light_tool.gd
│   │   ├── fog_tool.gd
│   │   └── measurement_tool.gd
│   └── ui/
│       ├── tool_bar.gd
│       ├── layer_panel.gd
│       ├── property_inspector.gd
│       ├── tile_palette.gd
│       ├── floor_selector.gd
│       └── status_bar.gd
├── tests/
│   ├── unit/
│   │   ├── test_map_data.gd
│   │   ├── test_vision_manager.gd
│   │   ├── test_light_manager.gd
│   │   ├── test_fog_manager.gd
│   │   ├── test_portal_manager.gd
│   │   └── test_serialization.gd
│   └── integration/
│       ├── test_editor_workflow.gd
│       └── test_import_export.gd
├── example_maps/
│   ├── tutorial_cave.trpgmap
│   └── sample_dungeon.trpgmap
└── docs/
    ├── user_manual.md
    ├── dev_guide.md
    └── api_reference.md
```

### 8.2 关键性能优化策略

#### 8.2.1 Chunk分块

对于大型地图(>200x200),将地图分成固定大小的Chunk:

```gdscript
class_name MapChunk
extends RefCounted

const CHUNK_SIZE := 64

var chunk_position: Vector2i  # 块坐标
var cells: Dictionary          # 格子数据
var is_dirty: bool = true
var chunk_texture: ImageTexture  # 预渲染的地形贴图

func render_chunk() -> void:
    # 将CHUNK_SIZE x CHUNK_SIZE的格子预渲染到一个纹理上
    # 在每帧渲染时,只需要绘制可见的Chunk
    pass
```

#### 8.2.2 视野计算优化

```gdscript
# 仅重算发生变化的Token
func mark_token_dirty(token_id: String) -> void:
    _dirty_tokens.append(token_id)

# 当墙壁/光源/遮挡物改变时,找出受影响的Token
func find_affected_tokens(changed_cell: Vector2i, radius: float) -> Array[String]:
    var affected: Array[String] = []
    for token in _tokens.values():
        if token.position.distance_to(Vector2(changed_cell)) <= radius:
            affected.append(token.token_id)
    return affected
```

#### 8.2.3 GPU加速迷雾渲染

使用Shader直接在GPU上处理迷雾:

```gdscript
# 将迷雾网格数据传入Shader Uniform
var fog_data_image := Image.create_from_data(width, height, false, Image.FORMAT_R8, fog_data)
var fog_texture := ImageTexture.create_from_image(fog_data_image)
material.set_shader_parameter("fog_data", fog_texture)
material.set_shader_parameter("fog_color", fog_color)
material.set_shader_parameter("explored_color", explored_color)
material.set_shader_parameter("unexplored_color", unexplored_color)
```

### 8.3 跨平台UI适配

```gdscript
# responsive_ui.gd
class_name ResponsiveUI
extends RefCounted

# 检测平台并调整UI
static func is_mobile() -> bool:
    return OS.get_name() in ["Android", "iOS"]

static func is_desktop() -> bool:
    return OS.get_name() in ["Windows", "macOS", "Linux"]

static func adjust_for_platform(ui_root: Control) -> void:
    if is_mobile():
        # 增大触控目标(最小48px)
        # 调整字体大小
        # 隐藏鼠标悬停相关功能
        # 启用双指手势
        var theme := ui_root.theme
        theme.default_font_size = 16
        for button in ui_root.find_children("*", "Button"):
            (button as Button).custom_minimum_size = Vector2(48, 48)
    else:
        # 桌面端标准尺寸
        pass
```

### 8.4 实现Command模式(撤销/重做)

```gdscript
# undo_redo_manager.gd (Autoload)
extends Node

class Command:
    func execute() -> void: pass
    func undo() -> void: pass
    func get_description() -> String: return ""

var _undo_stack: Array[Command] = []
var _redo_stack: Array[Command] = []
const MAX_UNDO := 100

func execute_command(command: Command) -> void:
    command.execute()
    _undo_stack.push_back(command)
    _redo_stack.clear()
    if _undo_stack.size() > MAX_UNDO:
        _undo_stack.pop_front()

func undo() -> void:
    if _undo_stack.is_empty(): return
    var cmd := _undo_stack.pop_back()
    cmd.undo()
    _redo_stack.push_back(cmd)

func redo() -> void:
    if _redo_stack.is_empty(): return
    var cmd := _redo_stack.pop_back()
    cmd.execute()
    _undo_stack.push_back(cmd)

# ---------- 具体命令示例 ----------
class PlaceTileCommand extends Command:
    var _layer: TerrainLayerData
    var _cell: Vector2i
    var _old_tile: Variant
    var _new_tile: Variant

    func execute() -> void:
        _layer.tiles[_cell] = _new_tile

    func undo() -> void:
        if _old_tile == null:
            _layer.tiles.erase(_cell)
        else:
            _layer.tiles[_cell] = _old_tile

    func get_description() -> String:
        return "在 (%d, %d) 放置图块" % [_cell.x, _cell.y]
```

### 8.5 为多人联机预留的架构

虽然第一阶段不包含多人联机,但数据结构预留了扩展点:

```gdscript
# 多人同步预留字段
@export var sync_state: Dictionary = {}  # 用于网络同步的运行时状态

# 每个数据对象都有唯一ID,便于网络引用
# 所有状态变更通过EventBus信号传递,后续可接入网络层
# 地图文件支持增量更新(仅发送变化的格子)

# 网络层接口(后期实现)
class_name NetworkSyncInterface
extends Node

signal remote_tile_placed(cell: Vector2i, tile_id: int, layer: int)
signal remote_fog_updated(cells: Dictionary)
signal remote_token_moved(token_id: String, new_position: Vector2i)

func sync_tile_placement(cell: Vector2i, tile_id: int, layer: int) -> void:
    # 发送到其他客户端
    pass

func request_map_data() -> MapData:
    # 从主机获取完整地图
    pass
```

### 8.6 规则书适配架构

```gdscript
# rulebook_adapter.gd
# 规则书适配框架 - 第二阶段使用
class_name RulebookAdapter
extends RefCounted

var _active_rulebook: RulebookReference
var _rule_modules: Dictionary = {}

func load_rulebook(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.READ)
    var json := JSON.parse_string(file.get_as_text())

    # 解析规则书JSON
    # 注册规则模块:
    # - combat.gd      战斗规则
    # - movement.gd    移动规则
    # - vision.gd      视野规则(修改默认视野参数)
    # - light.gd       光源规则
    # - skills.gd      技能系统

    for module_name in json["modules"]:
        var module_script := load("res://scripts/rulebook/%s.gd" % module_name)
        _rule_modules[module_name] = module_script.new()

func get_vision_rules() -> Dictionary:
    # 返回当前规则书的视野参数
    if _rule_modules.has("vision"):
        return _rule_modules["vision"].get_vision_params()
    return {"default_range": 6, "darkvision_range": 0}

func get_movement_cost(cell: Vector2i) -> float:
    # 返回在给定格子的移动消耗
    if _rule_modules.has("movement"):
        return _rule_modules["movement"].calculate_cost(cell)
    return 1.0
```

### 8.7 关键Godot节点使用

| 子系统 | 主要Godot节点 | 用途 |
|--------|---------------|------|
| 地形编辑 | TileMapLayer | 管理地形图块网格 |
| 物件放置 | Node2D + Sprite2D | 自由放置的物件 |
| 墙壁渲染 | Line2D / draw_line() | 绘制墙壁线段 |
| 迷雾渲染 | Sprite2D + ImageTexture | 动态生成的迷雾覆盖 |
| 光源渲染 | 自定义Shader | GPU光照计算 |
| 传送门动画 | AnimationPlayer | 波纹效果 |
| UI系统 | Control系列节点 | 完整编辑器UI |
| 网格叠加 | draw_rect() | 编辑器网格线 |
| 选择框 | draw_rect() + Animation | 选择指示 |
| 视野预览 | Polygon2D | 可见区域高亮 |

---

## 附录

### A. 坐标系统说明

```
世界坐标 (World Coordinate): 像素坐标,原点在左上角
    例: Vector2(320, 480) = 第320像素,第480像素

网格坐标 (Grid Coordinate): 格子坐标,原点在左上角
    例: Vector2i(3, 5) = 第4列,第6行(0-indexed)

转换公式:
    世界坐标 = 网格坐标 × grid_size + grid_offset
    网格坐标 = floor((世界坐标 - grid_offset) / grid_size)

六角网格(尖顶Hex):
    使用轴向坐标(Axial q, r)

    偏移坐标(row, col):
        col = q + (r - (r & 1)) / 2
        row = r

六角网格(平顶Hex):
    使用轴向坐标(Axial q, r)

    偏移坐标(row, col):
        col = q
        row = r + (q - (q & 1)) / 2
```

### B. Unity/Unreal/Foundry对照

| 概念 | 本项目(Godot) | Foundry VTT | Roll20 |
|------|---------------|-------------|--------|
| 地图文件 | .trpgmap (JSON) | .json (Scene) | 在线存储 |
| 网格 | GridManager | Scene Grid | Page Grid |
| 墙壁 | WallSegmentData | Walls Layer | Dynamic Lighting |
| 迷雾 | FogManager | Fog of War | Fog of War |
| 光源 | LightManager | Lights Layer | Dynamic Lighting |
| 视野Token | VisionTokenData | Token Vision | Token Settings |
| 传送门 | PortalManager | 需要插件 | 需要API |

### C. 参考资源

- Godot 4.x 官方文档: https://docs.godotengine.org/
- 递归阴影投射算法: https://www.albertford.com/shadowcasting/
- DungeonDraft VTT格式: https://www.dungeondraft.net/
- Tiled Map Editor: https://www.mapeditor.org/
- FoundryVTT API: https://foundryvtt.com/api/
- Universal VTT格式规范: https://github.com/kakaroto/fvtt-export-uvtt

---

*文档版本: 1.0*
*创建日期: 2026-06-20*
*适用范围: Phase 0 - Phase 7 (独立2D地图编辑器项目)*
