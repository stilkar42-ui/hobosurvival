class_name FirstPlayableLoopLayoutController
extends RefCounted


func build_location_pages(page) -> void:
	var action_root: VBoxContainer = page.get_node("Root/MainRow/ActionsPanel/ActionScroll/ActionRoot")
	var main_row: HBoxContainer = page.get_node("Root/MainRow")
	page._camp_nav_panel = PanelContainer.new()
	page._camp_nav_panel.name = "CampSubsystemNav"
	page._camp_nav_panel.custom_minimum_size = Vector2(250.0, 0.0)
	page._camp_nav_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	page._camp_nav_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page._camp_nav_panel.visible = false
	page._camp_nav_root = VBoxContainer.new()
	page._camp_nav_root.name = "CampSubsystemRoot"
	page._camp_nav_root.add_theme_constant_override("separation", 8)
	page._camp_nav_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page._camp_nav_panel.add_child(page._camp_nav_root)
	main_row.add_child(page._camp_nav_panel)
	main_row.move_child(page._camp_nav_panel, 0)
	var camp_nav_title = Label.new()
	camp_nav_title.text = "Camp Routine"
	camp_nav_title.add_theme_font_size_override("font_size", 20)
	page._camp_nav_root.add_child(camp_nav_title)
	page._camp_nav_status_label = Label.new()
	page._camp_nav_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page._camp_nav_root.add_child(page._camp_nav_status_label)
	page._page_nav_row = HBoxContainer.new()
	page._page_nav_row.name = "LocationNav"
	page._page_nav_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page._page_nav_row.add_theme_constant_override("separation", 8)
	action_root.add_child(page._page_nav_row)
	action_root.move_child(page._page_nav_row, page.status_label.get_index() + 1)

	page._open_jobs_board_button = page._make_nav_button("Jobs Board")
	page._open_send_money_page_button = page._make_nav_button("Send Money")
	page._open_grocery_page_button = page._make_nav_button("Grocery Store")
	page._open_hardware_page_button = page._make_nav_button("Hardware Store")
	page._go_to_camp_button = page._make_nav_button("Go to Camp")
	page._return_to_town_button = page._make_nav_button("Return to Town")
	page._open_getting_ready_page_button = page._make_nav_button("Getting Ready")
	page._open_hobocraft_page_button = page._make_nav_button("Hobocraft")
	page._open_cooking_page_button = page._make_nav_button("Cooking")
	page._back_to_town_from_grocery_button = page._make_nav_button("Back to Town")
	page._back_to_town_from_hardware_button = page._make_nav_button("Back to Town")
	page._back_to_town_from_jobs_button = page._make_nav_button("Back to Town")
	page._back_to_town_from_send_money_button = page._make_nav_button("Back to Town")
	page._back_to_camp_from_ready_button = page._make_nav_button("Close")
	page._back_to_camp_from_hobocraft_button = page._make_nav_button("Back to Camp")
	page._back_to_camp_from_cooking_button = page._make_nav_button("Back to Camp")
	page._page_nav_row.add_child(page._open_jobs_board_button)
	page._page_nav_row.add_child(page._open_send_money_page_button)
	page._page_nav_row.add_child(page._open_grocery_page_button)
	page._page_nav_row.add_child(page._open_hardware_page_button)
	page._page_nav_row.add_child(page._go_to_camp_button)
	page._page_nav_row.visible = false

	page._town_page_panel = page._make_page_panel("TownPage")
	page._jobs_board_page_panel = page._make_page_panel("JobsBoardPage")
	page._send_money_page_panel = page._make_page_panel("SendMoneyPage")
	page._camp_page_panel = page._make_page_panel("CampPage")
	page._grocery_page_panel = page._make_page_panel("GroceryStorePage")
	page._hardware_page_panel = page._make_page_panel("HardwareStorePage")
	page._getting_ready_page_panel = page._make_page_panel("GettingReadyPage")
	page._hobocraft_page_panel = page._make_page_panel("HobocraftPage")
	page._cooking_page_panel = page._make_page_panel("CookingPage")
	for panel in [page._town_page_panel, page._jobs_board_page_panel, page._send_money_page_panel, page._camp_page_panel, page._grocery_page_panel, page._hardware_page_panel, page._getting_ready_page_panel, page._hobocraft_page_panel, page._cooking_page_panel]:
		action_root.add_child(panel)

	page._town_page_root = page._town_page_panel.get_child(0)
	page._jobs_board_page_root = page._jobs_board_page_panel.get_child(0)
	page._send_money_page_root = page._send_money_page_panel.get_child(0)
	page._camp_page_root = page._camp_page_panel.get_child(0)
	page._grocery_page_root = page._grocery_page_panel.get_child(0)
	page._hardware_page_root = page._hardware_page_panel.get_child(0)
	page._getting_ready_page_root = page._getting_ready_page_panel.get_child(0)
	page._hobocraft_page_root = page._hobocraft_page_panel.get_child(0)
	page._cooking_page_root = page._cooking_page_panel.get_child(0)

	page._add_page_title(page._town_page_root, "Town", "Work, public errands, and the road back out of town.")
	page._open_jobs_board_button.reparent(page._town_page_root)
	page._open_send_money_page_button.reparent(page._town_page_root)
	page._open_grocery_page_button.reparent(page._town_page_root)
	page._open_hardware_page_button.reparent(page._town_page_root)
	page._go_to_camp_button.reparent(page._town_page_root)
	for node in [page.time_summary_label, page.wait_button, page.sell_scrap_button]:
		node.reparent(page._town_page_root)

	page._add_page_title(page._jobs_board_page_root, "Jobs Board", "Posted work is public, limited by the hour, and never promised twice.")
	page._jobs_board_page_root.add_child(page._back_to_town_from_jobs_button)
	page.work_summary_label.reparent(page._jobs_board_page_root)
	var jobs_scroll = page._make_panel_scroll("JobsBoardScroll")
	page._jobs_board_page_root.add_child(jobs_scroll)
	page.jobs_list.queue_free()
	page.jobs_list = GridContainer.new()
	page.jobs_list.name = "JobsBoardPostings"
	page.jobs_list.columns = 2
	page.jobs_list.add_theme_constant_override("h_separation", 10)
	page.jobs_list.add_theme_constant_override("v_separation", 10)
	page._configure_scroll_content(page.jobs_list)
	jobs_scroll.add_child(page.jobs_list)

	page._add_page_title(page._send_money_page_root, "Send Money", "A money order is not progress. It is proof the day was turned into help at home.")
	page._send_money_page_root.add_child(page._back_to_town_from_send_money_button)
	page._send_money_summary_label = Label.new()
	page._send_money_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page._send_money_page_root.add_child(page._send_money_summary_label)
	page._pending_support_label = Label.new()
	page._pending_support_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page._send_money_page_root.add_child(page._pending_support_label)
	for node in [page.family_summary_label, page.send_small_button, page.send_large_button]:
		node.reparent(page._send_money_page_root)
	page._send_custom_amount_label = Label.new()
	page._send_custom_amount_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page._send_custom_amount_label.text = "Choose an exact amount to send home."
	page._send_money_page_root.add_child(page._send_custom_amount_label)
	page._send_amount_spinbox = SpinBox.new()
	page._send_amount_spinbox.name = "SendAmountSpinBox"
	page._send_amount_spinbox.min_value = 0.01
	page._send_amount_spinbox.max_value = 9999.99
	page._send_amount_spinbox.step = 0.01
	page._send_amount_spinbox.custom_minimum_size = Vector2(220.0, 0.0)
	page._send_money_page_root.add_child(page._send_amount_spinbox)
	var send_custom_row = HBoxContainer.new()
	send_custom_row.name = "SendCustomRow"
	send_custom_row.add_theme_constant_override("separation", 8)
	page._send_money_page_root.add_child(send_custom_row)
	page._send_mail_custom_button = page._make_nav_button("Mail Exact Amount")
	page._send_telegraph_custom_button = page._make_nav_button("Telegraph Exact Amount")
	send_custom_row.add_child(page._send_mail_custom_button)
	send_custom_row.add_child(page._send_telegraph_custom_button)

	page._add_page_title(page._grocery_page_root, "Grocery Store", "Food, coffee, and small comforts bought out of the stake.")
	page._grocery_page_root.add_child(page._back_to_town_from_grocery_button)
	for node in [page.supplies_summary_label, page.buy_bread_button, page.buy_coffee_button, page.buy_stew_button, page.buy_tobacco_button, page.buy_grocery_beans_button, page.buy_grocery_potted_meat_button, page.buy_coffee_grounds_button]:
		node.reparent(page._grocery_page_root)
		node.visible = node == page.supplies_summary_label
	page._grocery_stock_list = VBoxContainer.new()
	page._grocery_stock_list.name = "GroceryStockList"
	page._grocery_stock_list.add_theme_constant_override("separation", 8)
	page._grocery_page_root.add_child(page._grocery_stock_list)

	page._hardware_summary_label = Label.new()
	page._hardware_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page._add_page_title(page._hardware_page_root, "Hardware Store", "Small practical gear for camp, fire, repair, and boiling water.")
	page._hardware_page_root.add_child(page._back_to_town_from_hardware_button)
	page._hardware_page_root.add_child(page._hardware_summary_label)
	for node in [page.buy_hardware_matches_button, page.buy_hardware_empty_can_button, page.buy_hardware_cordage_button]:
		node.reparent(page._hardware_page_root)
		node.visible = false
	page._hardware_stock_list = VBoxContainer.new()
	page._hardware_stock_list.name = "HardwareStockList"
	page._hardware_stock_list.add_theme_constant_override("separation", 8)
	page._hardware_page_root.add_child(page._hardware_stock_list)

	page._camp_nav_root.add_child(page._return_to_town_button)
	page._camp_nav_root.add_child(page._open_getting_ready_page_button)
	page._camp_nav_root.add_child(page._open_hobocraft_page_button)
	page._camp_nav_root.add_child(page._open_cooking_page_button)
	for node in [page.camp_summary_label, page.sleep_button, page.use_selected_button]:
		node.reparent(page._camp_nav_root)
		node.visible = false

	page._add_page_title(page._hobocraft_page_root, "Hobocraft", "Small camp makes: practical, material-bound, and fed by store goods or salvage.")
	page._hobocraft_page_root.add_child(page._back_to_camp_from_hobocraft_button)
	var hobocraft_layout = HBoxContainer.new()
	hobocraft_layout.name = "HobocraftLayout"
	hobocraft_layout.add_theme_constant_override("separation", 14)
	hobocraft_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hobocraft_layout.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page._hobocraft_page_root.add_child(hobocraft_layout)
	var hobocraft_list_panel = PanelContainer.new()
	hobocraft_list_panel.name = "HobocraftListPanel"
	hobocraft_list_panel.custom_minimum_size = Vector2(280.0, 0.0)
	hobocraft_list_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hobocraft_layout.add_child(hobocraft_list_panel)
	page._hobocraft_recipe_list = VBoxContainer.new()
	page._hobocraft_recipe_list.name = "HobocraftRecipeList"
	page._hobocraft_recipe_list.add_theme_constant_override("separation", 8)
	page._hobocraft_recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page._hobocraft_recipe_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hobocraft_list_panel.add_child(page._hobocraft_recipe_list)
	var hobocraft_detail_panel = PanelContainer.new()
	hobocraft_detail_panel.name = "HobocraftDetailPanel"
	hobocraft_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hobocraft_layout.add_child(hobocraft_detail_panel)
	page._hobocraft_detail_root = VBoxContainer.new()
	page._hobocraft_detail_root.name = "HobocraftDetail"
	page._hobocraft_detail_root.add_theme_constant_override("separation", 8)
	page._hobocraft_detail_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page._hobocraft_detail_root.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hobocraft_detail_panel.add_child(page._hobocraft_detail_root)

	page._add_page_title(page._cooking_page_root, "Cooking", "Camp food and coffee trade time and setup for a steadier stake.")
	page._cooking_page_root.add_child(page._back_to_camp_from_cooking_button)
	var cooking_prep_summary = Label.new()
	cooking_prep_summary.name = "CookingPrepSummary"
	cooking_prep_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cooking_prep_summary.text = "Fire and kindling are the first step in camp cooking."
	page._cooking_page_root.add_child(cooking_prep_summary)
	for node in [page.build_fire_button, page.tend_fire_button, page.gather_kindling_button]:
		node.reparent(page._cooking_page_root)
		node.visible = true
	page._cooking_filter_button = page._make_nav_button("Show Makeable Now")
	page._cooking_filter_button.toggle_mode = true
	page._cooking_filter_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	page._cooking_page_root.add_child(page._cooking_filter_button)
	var cooking_layout = HBoxContainer.new()
	cooking_layout.name = "CookingLayout"
	cooking_layout.add_theme_constant_override("separation", 14)
	cooking_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cooking_layout.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	page._cooking_page_root.add_child(cooking_layout)
	var cooking_list_panel = PanelContainer.new()
	cooking_list_panel.name = "CookingListPanel"
	cooking_list_panel.custom_minimum_size = Vector2(280.0, 0.0)
	cooking_list_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cooking_layout.add_child(cooking_list_panel)
	page._cooking_recipe_list = VBoxContainer.new()
	page._cooking_recipe_list.name = "CookingRecipeList"
	page._cooking_recipe_list.add_theme_constant_override("separation", 8)
	page._cooking_recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page._cooking_recipe_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cooking_list_panel.add_child(page._cooking_recipe_list)
	var cooking_detail_panel = PanelContainer.new()
	cooking_detail_panel.name = "CookingDetailPanel"
	cooking_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cooking_layout.add_child(cooking_detail_panel)
	page._cooking_detail_root = VBoxContainer.new()
	page._cooking_detail_root.name = "CookingDetail"
	page._cooking_detail_root.add_theme_constant_override("separation", 8)
	page._cooking_detail_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page._cooking_detail_root.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cooking_detail_panel.add_child(page._cooking_detail_root)
	page.brew_camp_coffee_button.reparent(page._cooking_page_root)
	page.brew_camp_coffee_button.visible = false

	page._add_page_title(page._getting_ready_page_root, "Getting Ready", "Water first, then the work of becoming fit to be seen.")
	page._getting_ready_page_root.add_child(page._back_to_camp_from_ready_button)
	page.getting_ready_status_label.reparent(page._getting_ready_page_root)
	page.getting_ready_stats_label.reparent(page._getting_ready_page_root)
	page.ready_fetch_water_button.reparent(page._getting_ready_page_root)
	page.ready_fetch_water_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ready_actions_grid = page.ready_wash_body_button.get_parent()
	ready_actions_grid.reparent(page._getting_ready_page_root)
	ready_actions_grid.columns = 2

	page._set_active_loop_page(page.PAGE_TOWN)


func connect_buttons(page) -> void:
	page._open_grocery_page_button.pressed.connect(Callable(page, "_set_active_loop_page").bind(page.PAGE_GROCERY))
	page._open_hardware_page_button.pressed.connect(Callable(page, "_set_active_loop_page").bind(page.PAGE_HARDWARE))
	page._open_jobs_board_button.pressed.connect(Callable(page, "_set_active_loop_page").bind(page.PAGE_JOBS_BOARD))
	page._open_send_money_page_button.pressed.connect(Callable(page, "_set_active_loop_page").bind(page.PAGE_SEND_MONEY))
	page._back_to_town_from_grocery_button.pressed.connect(Callable(page, "_set_active_loop_page").bind(page.PAGE_TOWN))
	page._back_to_town_from_hardware_button.pressed.connect(Callable(page, "_set_active_loop_page").bind(page.PAGE_TOWN))
	page._back_to_town_from_jobs_button.pressed.connect(Callable(page, "_set_active_loop_page").bind(page.PAGE_TOWN))
	page._back_to_town_from_send_money_button.pressed.connect(Callable(page, "_set_active_loop_page").bind(page.PAGE_TOWN))
	page._back_to_camp_from_ready_button.pressed.connect(Callable(page, "_on_close_getting_ready_page_pressed"))
	page._open_hobocraft_page_button.pressed.connect(Callable(page, "_set_active_loop_page").bind(page.PAGE_HOBOCRAFT))
	page._open_cooking_page_button.pressed.connect(Callable(page, "_set_active_loop_page").bind(page.PAGE_COOKING))
	page._back_to_camp_from_hobocraft_button.pressed.connect(Callable(page, "_set_active_loop_page").bind(page.PAGE_CAMP))
	page._back_to_camp_from_cooking_button.pressed.connect(Callable(page, "_set_active_loop_page").bind(page.PAGE_CAMP))
	page._cooking_filter_button.pressed.connect(Callable(page, "_on_cooking_filter_pressed"))
	page._go_to_camp_button.pressed.connect(Callable(page, "_on_location_travel_pressed").bind(page.SurvivalLoopRulesScript.ACTION_GO_TO_CAMP, page.PAGE_CAMP))
	page._return_to_town_button.pressed.connect(Callable(page, "_on_location_travel_pressed").bind(page.SurvivalLoopRulesScript.ACTION_RETURN_TO_TOWN, page.PAGE_TOWN))
	page._open_getting_ready_page_button.pressed.connect(Callable(page, "_set_active_loop_page").bind(page.PAGE_GETTING_READY))
	page.buy_bread_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_BUY_BREAD))
	page.buy_coffee_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_BUY_COFFEE))
	page.buy_stew_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_BUY_STEW))
	page.buy_tobacco_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_BUY_TOBACCO))
	page.buy_grocery_beans_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_BUY_GROCERY_BEANS))
	page.buy_grocery_potted_meat_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_BUY_GROCERY_POTTED_MEAT))
	page.buy_coffee_grounds_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_BUY_COFFEE_GROUNDS))
	page.buy_hardware_matches_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_BUY_HARDWARE_MATCHES))
	page.buy_hardware_empty_can_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_BUY_HARDWARE_EMPTY_CAN))
	page.buy_hardware_cordage_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_BUY_HARDWARE_CORDAGE))
	page.use_selected_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_USE_SELECTED))
	page.send_small_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_SEND_SMALL))
	page.send_large_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_SEND_LARGE))
	page._send_amount_spinbox.value_changed.connect(Callable(page, "_on_send_amount_changed"))
	page._send_mail_custom_button.pressed.connect(Callable(page, "_on_send_support_pressed").bind(&"mail"))
	page._send_telegraph_custom_button.pressed.connect(Callable(page, "_on_send_support_pressed").bind(&"telegraph"))
	page.build_fire_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_BUILD_FIRE))
	page.tend_fire_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_TEND_FIRE))
	page.gather_kindling_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_GATHER_KINDLING))
	page.brew_camp_coffee_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_BREW_CAMP_COFFEE))
	page.wait_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_WAIT))
	page.sell_scrap_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_SELL_SCRAP))
	page.sleep_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_SLEEP_ROUGH))
	page.reset_run_button.pressed.connect(Callable(page, "_on_reset_run_pressed"))
	page.go_debug_button.pressed.connect(Callable(page, "_on_go_debug_pressed"))
	page.open_inventory_button.pressed.connect(Callable(page, "_on_open_inventory_pressed"))
	page.open_passport_button.pressed.connect(Callable(page, "_on_open_passport_pressed"))
	page.open_getting_ready_button.pressed.connect(Callable(page, "_on_open_getting_ready_pressed"))
	page.return_to_menu_button.pressed.connect(Callable(page, "_on_return_to_menu_pressed"))
	page.quit_game_button.pressed.connect(Callable(page, "_on_quit_game_pressed"))
	page.close_inventory_button.pressed.connect(Callable(page, "_on_close_inventory_pressed"))
	page.inventory_move_cancel_button.pressed.connect(Callable(page, "_on_inventory_move_cancel_pressed"))
	page.use_selected_in_inventory_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_USE_SELECTED))
	page.inventory_transfer_button.pressed.connect(Callable(page, "_on_inventory_transfer_pressed"))
	page.inventory_drop_button.pressed.connect(Callable(page, "_on_inventory_drop_pressed"))
	page.inventory_equip_button.pressed.connect(Callable(page, "_on_inventory_equip_pressed"))
	page.inventory_unequip_button.pressed.connect(Callable(page, "_on_inventory_unequip_pressed"))
	page.close_passport_button.pressed.connect(Callable(page, "_on_close_passport_pressed"))
	page.close_getting_ready_button.pressed.connect(Callable(page, "_on_close_getting_ready_pressed"))
	page.ready_fetch_water_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_READY_FETCH_WATER))
	page.ready_wash_body_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_READY_WASH_BODY))
	page.ready_wash_face_hands_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_READY_WASH_FACE_HANDS))
	page.ready_shave_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_READY_SHAVE))
	page.ready_comb_groom_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_READY_COMB_GROOM))
	page.ready_air_out_clothes_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_READY_AIR_OUT_CLOTHES))
	page.ready_brush_clothes_button.pressed.connect(Callable(page, "_on_action_pressed").bind(page.SurvivalLoopRulesScript.ACTION_READY_BRUSH_CLOTHES))


func apply_styles(page) -> void:
	page._apply_panel_style(page.get_node("Root/SummaryPanel"), Color("2a241d"), Color("8e6c42"))
	page._apply_panel_style(page.get_node("Root/MainRow/ActionsPanel"), Color("191714"), Color("6c5131"))
	page._apply_panel_style(page.inventory_summary_panel, Color("171a1e"), Color("4e6470"))
	page._apply_panel_style(page.fade_debug_panel, Color("181512"), Color("725638"))
	page._apply_panel_style(page.get_node("InventoryOverlay/InventoryMargin/InventoryWindow"), Color("131416"), Color("6a5847"))
	page._apply_panel_style(page.inventory_actions_panel, Color("1a1714"), Color("735a43"))
	page._apply_panel_style(page.get_node("PassportOverlay/PassportMargin/PassportWindow"), Color("151310"), Color("8f7348"))
	page._apply_panel_style(page.get_node("GettingReadyOverlay/GettingReadyMargin/GettingReadyWindow"), Color("171512"), Color("7a6448"))
	page._apply_panel_style(page.result_panel, Color("2c241a"), Color("9a7241"))
	page._apply_panel_style(page._town_page_panel, Color("1d1d19"), Color("6d6650"))
	page._apply_panel_style(page._jobs_board_page_panel, Color("1c1d19"), Color("6d6650"))
	page._apply_panel_style(page._send_money_page_panel, Color("211c18"), Color("7a6552"))
	page._apply_panel_style(page._camp_page_panel, Color("1d2018"), Color("627048"))
	page._apply_panel_style(page._grocery_page_panel, Color("242015"), Color("8b7448"))
	page._apply_panel_style(page._hardware_page_panel, Color("182024"), Color("52707a"))
	page._apply_panel_style(page._getting_ready_page_panel, Color("1e1b1a"), Color("7a665f"))
	page._apply_panel_style(page._hobocraft_page_panel, Color("1b1f18"), Color("66734c"))
	page._apply_panel_style(page._cooking_page_panel, Color("211d16"), Color("806943"))
	page._apply_panel_style(page._camp_nav_panel, Color("171b13"), Color("66734c"))
	page.inventory_hint_label.modulate = Color("c6d3d9")
	page.status_label.modulate = Color("e2d5bc")
	page.selected_item_label.modulate = Color("d9e2e6")
	page.inventory_modal_status_label.modulate = Color("d7cab6")
	page.inventory_action_summary_label.modulate = Color("e4d7c3")
	page.inventory_destination_label.modulate = Color("c7b39a")
	page._apply_inventory_modal_button_style(page.inventory_move_cancel_button, Color("3a2d24"), Color("8f6d49"))
	page._apply_inventory_modal_button_style(page.inventory_transfer_button, Color("3d3226"), Color("97764c"))
	page._apply_inventory_modal_button_style(page.inventory_drop_button, Color("3a2722"), Color("9d6c55"))
	page._apply_inventory_modal_button_style(page.inventory_equip_button, Color("2f3329"), Color("7f8a5c"))
	page._apply_inventory_modal_button_style(page.inventory_unequip_button, Color("332c24"), Color("8a6f50"))
	page._apply_inventory_modal_button_style(page.use_selected_in_inventory_button, Color("2e3538"), Color("6f9097"))
	page.return_to_menu_button.visible = true
	page.return_to_menu_button.text = "Exit to Menu"
	page.quit_game_button.visible = false
	page.quit_game_button.text = "Quit Game"
	page._apply_inventory_modal_button_style(page.return_to_menu_button, Color("2d2a26"), Color("76634c"))
	page._apply_inventory_modal_button_style(page.quit_game_button, Color("2d2a26"), Color("76634c"))
	page._apply_inventory_modal_button_style(page.close_inventory_button, Color("272829"), Color("636a6f"))
	page._apply_inventory_modal_button_style(page.close_getting_ready_button, Color("272829"), Color("636a6f"))
	for button in [page._send_mail_custom_button, page._send_telegraph_custom_button]:
		page._apply_inventory_modal_button_style(button, Color("3a2f22"), Color("8d704d"))
	if page._send_amount_spinbox != null:
		page._send_amount_spinbox.add_theme_color_override("font_color", Color("eadcc6"))
	for button in [page._open_grocery_page_button, page._open_hardware_page_button, page._go_to_camp_button, page._return_to_town_button, page._open_getting_ready_page_button, page._open_hobocraft_page_button, page._open_cooking_page_button, page._back_to_town_from_grocery_button, page._back_to_town_from_hardware_button, page._back_to_camp_from_ready_button, page._back_to_camp_from_hobocraft_button, page._back_to_camp_from_cooking_button]:
		page._apply_inventory_modal_button_style(button, Color("2d2a24"), Color("74674e"))
	for button in page._get_getting_ready_buttons():
		page._apply_inventory_modal_button_style(button, Color("30291f"), Color("8d704d"))
