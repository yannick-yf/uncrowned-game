extends Node3D
## Isolated inspection scene: the saved prefabs can be dragged into any workshop sector.
var catalog: Array=[]
var by_id: Dictionary={}
var camera: Camera3D
var stage: Node3D
var canvas: CanvasLayer
var title_label: Label
var info_label: Label
var details: Label
var search: LineEdit
var family_filter: OptionButton
var entries: Array[Button]=[]
var groups: Array[String]=[""]
var selected: int=0
var demonstration: bool=true
var focus: Vector3=Vector3.ZERO
var yaw: float=24
var tilt: float=42
var zoom: float=62
func _ready() -> void:
	DisplayServer.window_set_title("Uncrowned — Catalogue du village fermier")
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/farming/catalog.json")).assets
	for a: Dictionary in catalog:by_id[a.id]=a
	stage=Node3D.new();stage.name="Presentation";add_child(stage)
	var environment: WorldEnvironment=WorldEnvironment.new();environment.environment=Environment.new();add_child(environment)
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("d7dfd9")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("c8d2da");environment.environment.ambient_light_energy=.58
	environment.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.environment.ssao_enabled=true;environment.environment.ssao_radius=1.1;environment.environment.ssao_intensity=1.3
	var sun: DirectionalLight3D=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-28,0);sun.light_energy=1.65;sun.light_color=Color("fff0d8");sun.shadow_enabled=true;sun.directional_shadow_max_distance=180;add_child(sun)
	camera=Camera3D.new();camera.name="Camera";camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true;camera.far=500;add_child(camera)
	_build_ui();show_demo()
	print("FARMING_CATALOG_READY assets=",catalog.size())
func _build_ui() -> void:
	canvas=CanvasLayer.new();canvas.name="CatalogUI";add_child(canvas)
	var panel: PanelContainer=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE);panel.offset_right=318;canvas.add_child(panel)
	var style: StyleBoxFlat=StyleBoxFlat.new();style.bg_color=Color("26352df5");style.content_margin_left=17;style.content_margin_right=17;style.content_margin_top=17;style.content_margin_bottom=17;panel.add_theme_stylebox_override("panel",style)
	var column: VBoxContainer=VBoxContainer.new();column.add_theme_constant_override("separation",10);panel.add_child(column)
	var heading: Label=Label.new();heading.text="VILLAGE FERMIER";heading.add_theme_font_size_override("font_size",22);column.add_child(heading)
	var sub: Label=Label.new();sub.text="%d pièces modulaires · échelle en mètres"%catalog.size();sub.add_theme_font_size_override("font_size",13);column.add_child(sub)
	var demo: Button=Button.new();demo.text="Voir l’assemblage de présentation";demo.pressed.connect(show_demo);column.add_child(demo)
	search=LineEdit.new();search.placeholder_text="Rechercher une pièce…";search.text_changed.connect(func(_s: String):_filter());column.add_child(search)
	family_filter=OptionButton.new();family_filter.add_item("Toutes les familles")
	for a: Dictionary in catalog:
		if not groups.has(str(a.family)):groups.append(str(a.family));family_filter.add_item(str(a.family).capitalize())
	family_filter.item_selected.connect(func(_i: int):_filter());column.add_child(family_filter)
	var scroll: ScrollContainer=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	var list: VBoxContainer=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
	for i: int in catalog.size():
		var button: Button=Button.new();button.text="%02d  %s"%[i+1,catalog[i].label];button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;button.custom_minimum_size=Vector2(270,34);button.tooltip_text=catalog[i].purpose;button.pressed.connect(select_asset.bind(i));list.add_child(button);entries.append(button)
	var help: Label=Label.new();help.text="Molette : zoom · clic central : tourner\n← / → : pièce précédente / suivante\nD : assemblage · R : recadrer";help.add_theme_font_size_override("font_size",12);column.add_child(help)
	var card: PanelContainer=PanelContainer.new();card.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);card.offset_left=338;card.offset_right=-20;card.offset_top=18;card.add_theme_stylebox_override("panel",style);canvas.add_child(card)
	var text_box: VBoxContainer=VBoxContainer.new();card.add_child(text_box)
	title_label=Label.new();title_label.add_theme_font_size_override("font_size",22);text_box.add_child(title_label)
	info_label=Label.new();info_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;info_label.custom_minimum_size.x=450;info_label.add_theme_font_size_override("font_size",14);text_box.add_child(info_label)
	details=Label.new();details.add_theme_font_size_override("font_size",12);text_box.add_child(details)
func _filter() -> void:
	for i: int in catalog.size():entries[i].visible=(family_filter.selected==0 or catalog[i].family==groups[family_filter.selected]) and (search.text.is_empty() or str(catalog[i].label).to_lower().contains(search.text.to_lower()))
func _clear() -> void:
	for node: Node in stage.get_children():stage.remove_child(node);node.queue_free()
func _floor(size: Vector2,color: Color) -> void:
	var node: MeshInstance3D=MeshInstance3D.new();var plane: PlaneMesh=PlaneMesh.new();plane.size=size;node.mesh=plane;node.position.y=-.04
	var mat: StandardMaterial3D=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=1;node.material_override=mat;stage.add_child(node)
func place(id: String,at: Vector3=Vector3.ZERO,angle: float=0) -> Node3D:
	if not by_id.has(id):push_error("Missing preview asset "+id);return null
	var obj: Node3D=(load(by_id[id].scene) as PackedScene).instantiate();obj.name=id.to_pascal_case();obj.position=at;obj.rotation_degrees.y=angle;stage.add_child(obj);return obj
func select_asset(index: int) -> void:
	_clear();selected=wrapi(index,0,catalog.size());demonstration=false
	var a: Dictionary=catalog[selected];place(a.id);_floor(Vector2(100,100),Color("abae94"))
	focus=Vector3(a.bounds_center_m[0],a.bounds_center_m[1],a.bounds_center_m[2]);yaw=-35 if str(a.id).contains("moulin") else 28;tilt=30
	var extent: Vector3=Vector3(a.size_m[0],a.size_m[1],a.size_m[2]);var view: Basis=Basis.from_euler(Vector3(deg_to_rad(-tilt),deg_to_rad(yaw),0))
	var vp: Vector2=get_viewport().get_visible_rect().size;var aspect: float=maxf(1,(vp.x-335)/vp.y)
	zoom=maxf(2,maxf(view.y.abs().dot(extent)*1.7,view.x.abs().dot(extent)/aspect*1.35))
	title_label.text=a.label;info_label.text=a.purpose+"\n"+a.placement;details.text="%.2f × %.2f × %.2f m · %s"%[a.size_m[0],a.size_m[1],a.size_m[2],str(a.scene).get_file()]
	_update_camera()
func show_demo() -> void:
	_clear();demonstration=true;_floor(Vector2(80,70),Color("81915c"))
	for p: Array in [["chaumiere_du_potager",-17,-3,12],["ferme_en_l",-13,-17,-12],["longere_des_moissons",2,-18,0],["moulin_a_grain_hydraulique",20,-14,0],["grenier_sur_piliers",1,-4,0],["reserve_a_grain_octogonale",10,-8,0],["champ_ble_rive_concave",-14,11,0],["champ_ble_rive_concave",-3,13,-12],["champ_legumes_boucle",8,11,0],["champ_laboure_lisiere",-25,10,0],["verger_aligne_6arbres",23,9,0],["bosquet_fruitier_4arbres",-27,-16,0]]:place(p[0],Vector3(p[1],0,p[2]),p[3])
	# Supported mill watercourse, independent of the game's hydrology.
	for z: float in [-22.1,-27.1,-5.9,-.9]:place("canal_de_moulin_5m",Vector3(15.17,0,z))
	for id: String in by_id:
		if id.contains("grange"):
			place(id,Vector3(-28,0,-4));break
	var small: Array=[]
	for a: Dictionary in catalog:
		if a.family=="accessoires" and not str(a.id).contains("echelle"):small.append(a.id)
	for i: int in mini(small.size(),7):place(small[i],Vector3(-7+(i%4)*3,0,2+(i/4)*3),15)
	focus=Vector3(0,1,-4);yaw=24;tilt=45;zoom=62
	title_label.text="Un village de plaine, de chaume et de vergers";info_label.text="Assemblage de présentation du pack. Choisis une pièce à gauche pour l’inspecter.\nLes champs et les vergers peuvent être recomposés avec leurs modules.";details.text="Maisons · agriculture · eau · cultures · vergers · accessoires";_update_camera()
func _update_camera() -> void:
	camera.size=zoom;camera.rotation_degrees=Vector3(-tilt,yaw,0);camera.position=focus+camera.basis.z*maxf(45,zoom*1.7)
	camera.h_offset=-zoom*.19 if canvas.visible else 0;camera.v_offset=zoom*.06 if canvas.visible else 0
func _process(delta: float) -> void:
	for wheel: Node3D in stage.find_children("Wheel","Node3D",true,false):wheel.rotate_x(-delta*.22)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom=maxf(1.2,zoom*.88)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom=minf(130,zoom/.88)
		_update_camera()
	elif event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_MIDDLE:
		yaw-=event.relative.x*.3;tilt=clampf(tilt+event.relative.y*.2,12,80);_update_camera()
	elif event is InputEventKey and event.pressed:
		if event.keycode==KEY_RIGHT:select_asset(selected+1)
		elif event.keycode==KEY_LEFT:select_asset(selected-1)
		elif event.keycode==KEY_D:show_demo()
		elif event.keycode==KEY_R:
			if demonstration:show_demo()
			else:select_asset(selected)
