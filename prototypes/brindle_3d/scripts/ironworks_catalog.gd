extends Node3D
## Inspection UI for the ironworks kit. It does not modify the world map or assets.
var catalog: Array = []
var selected: int = 1
var demo_mode: bool = true
var focus: Vector3 = Vector3.ZERO
var yaw: float = 26.0
var tilt: float = 36.0
var zoom: float = 42.0
var canvas: CanvasLayer
var title_label: Label
var description: Label
var dimension_label: Label
var buttons: VBoxContainer
var search: LineEdit
var filter: OptionButton
var list_buttons: Array[Button] = []
@onready var camera: Camera3D = $Camera
@onready var assets: Node3D = $Assets
@onready var demonstration: Node3D = $Demonstration

func _ready() -> void:
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ironworks/catalog.json")).assets
	_build_ui()
	show_demo()

func _build_ui() -> void:
	canvas=CanvasLayer.new();canvas.name="CatalogUI";add_child(canvas)
	var panel: PanelContainer=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_right=336;panel.mouse_filter=Control.MOUSE_FILTER_STOP
	var background: StyleBoxFlat=StyleBoxFlat.new();background.bg_color=Color(.075,.095,.11,.97)
	background.content_margin_left=18;background.content_margin_right=18;background.content_margin_top=18;background.content_margin_bottom=16
	panel.add_theme_stylebox_override("panel",background);canvas.add_child(panel)
	var column: VBoxContainer=VBoxContainer.new();column.add_theme_constant_override("separation",11);panel.add_child(column)
	var heading: Label=Label.new();heading.text="ACIÉRIE  /  BIBLIOTHÈQUE";heading.add_theme_font_size_override("font_size",19);column.add_child(heading)
	var count: Label=Label.new();count.text=str(catalog.size())+" assets · pierre, ardoise et fer · échelle en mètres";count.add_theme_font_size_override("font_size",12);column.add_child(count)
	var show_button: Button=Button.new();show_button.text="Voir l’assemblage de démonstration";show_button.pressed.connect(show_demo);column.add_child(show_button)
	search=LineEdit.new();search.placeholder_text="Rechercher un asset…";search.text_changed.connect(_filter_changed);column.add_child(search)
	filter=OptionButton.new()
	for label: String in ["Toutes les familles","Production","Stockage et transport","Vie du village","Accessoires","Modules"]:filter.add_item(label)
	filter.item_selected.connect(_family_changed);column.add_child(filter)
	var scroll: ScrollContainer=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	buttons=VBoxContainer.new();buttons.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(buttons)
	for i: int in catalog.size():
		var button: Button=Button.new();button.text="%02d  %s"%[i+1,str(catalog[i].label)]
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.custom_minimum_size=Vector2(290,34);button.tooltip_text=str(catalog[i].purpose)
		button.pressed.connect(select_asset.bind(i));buttons.add_child(button);list_buttons.append(button)
	var help: Label=Label.new();help.text="Molette : zoom · clic central : tourner\nFlèches : asset suivant / précédent\nR : recadrer · D : démonstration"
	help.add_theme_font_size_override("font_size",12);column.add_child(help)
	var info: PanelContainer=PanelContainer.new();info.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	info.offset_left=358;info.offset_right=-22;info.offset_top=20
	var info_style: StyleBoxFlat=background.duplicate();info_style.bg_color=Color(.075,.095,.11,.92);info.add_theme_stylebox_override("panel",info_style);canvas.add_child(info)
	var text: VBoxContainer=VBoxContainer.new();info.add_child(text)
	title_label=Label.new();title_label.add_theme_font_size_override("font_size",22);text.add_child(title_label)
	description=Label.new();description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.custom_minimum_size.x=600;description.add_theme_font_size_override("font_size",14);text.add_child(description)
	dimension_label=Label.new();dimension_label.add_theme_font_size_override("font_size",12);text.add_child(dimension_label)

func _filter_changed(_text: String) -> void: _apply_filter()
func _family_changed(_index: int) -> void: _apply_filter()
func _apply_filter() -> void:
	var groups: Array[String]=["","production","stockage","village","accessoires","modules"]
	for i: int in catalog.size():
		list_buttons[i].visible=(filter.selected==0 or catalog[i].family==groups[filter.selected]) and (search.text.is_empty() or str(catalog[i].label).to_lower().contains(search.text.to_lower()))

func select_asset(index: int) -> void:
	selected=wrapi(index,0,catalog.size());demo_mode=false;demonstration.visible=false;assets.visible=true
	for i: int in assets.get_child_count():assets.get_child(i).visible=i==selected
	var obj: Node3D=assets.get_child(selected)
	var dimensions: Array=catalog[selected].size_m
	var center: Array=catalog[selected].bounds_center_m
	focus=obj.position+Vector3(float(center[0]),float(center[1]),float(center[2]))
	yaw=26;tilt=32
	var basis_view: Basis=Basis.from_euler(Vector3(deg_to_rad(-tilt),deg_to_rad(yaw),0))
	var extent: Vector3=Vector3(float(dimensions[0]),float(dimensions[1]),float(dimensions[2]))
	var projected_width: float=basis_view.x.abs().dot(extent)
	var projected_height: float=basis_view.y.abs().dot(extent)
	var viewport_size: Vector2=get_viewport().get_visible_rect().size
	var aspect: float=viewport_size.x/viewport_size.y
	zoom=maxf(1.4,maxf(projected_height*1.38,projected_width/aspect*1.55))
	title_label.text=str(catalog[selected].label)
	description.text=str(catalog[selected].purpose)+"\n"+str(catalog[selected].placement)
	dimension_label.text="%.2f × %.2f × %.2f m  ·  %s"%[float(dimensions[0]),float(dimensions[1]),float(dimensions[2]),str(catalog[selected].scene).get_file()]
	_update_camera()

func show_demo() -> void:
	demo_mode=true;assets.visible=false;demonstration.visible=true
	focus=Vector3(0,1.2,2);yaw=24;tilt=43;zoom=42
	title_label.text="Une chaîne de production complète"
	description.text="Mine et tri → préparation → charbon → bas fourneaux → martelage → forge → dépôt.\nAssemblage de démonstration du kit ; les emplacements de la ville restent à composer."
	dimension_label.text="Sélectionne un asset à gauche pour l’examiner seul."
	_update_camera()

func _update_camera() -> void:
	camera.size=zoom;camera.rotation_degrees=Vector3(-tilt,yaw,0)
	camera.position=focus+camera.basis.z*maxf(50,zoom*2.0)
	# Keep the asset in the free area to the right of the browser panel.
	camera.h_offset=-zoom*.23 if canvas.visible else 0.0
	camera.v_offset=zoom*.06 if canvas.visible else 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom=maxf(1.5,zoom*.88)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom=minf(110,zoom/.88)
		_update_camera()
	elif event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_MIDDLE:
		yaw-=event.relative.x*.3;tilt=clampf(tilt+event.relative.y*.2,12,80);_update_camera()
	elif event is InputEventKey and event.pressed:
		if event.keycode==KEY_RIGHT:select_asset(selected+1)
		elif event.keycode==KEY_LEFT:select_asset(selected-1)
		elif event.keycode==KEY_D:show_demo()
		elif event.keycode==KEY_R:
			if demo_mode:show_demo()
			else:select_asset(selected)
