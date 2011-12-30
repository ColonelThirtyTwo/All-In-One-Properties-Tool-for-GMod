TOOL.Category = "Construction"
TOOL.Name = "#Tool_allinoneproperties_name"

-- TODO: AddGameFlag(FVPHYSICS_WAS_THROWN) Doesn't activate explosives for some reason.
-- TODO: Dupe support

TOOL.ClientConVar = {
	surface = "default",
	mass = 0,
	buoyancy = -1,
	grav = 0,
	dragenabled = 0,
	posdrag = -1,
	angdrag = -1,
	posdamp = 0,
	angdamp = 0,
	nopickup = 1,
	--wasthrown = 0,
	noimpactdmg = 0,
}

Sound("buttons/button3.wav")

--[[local ValidMaterials = {
	-- http://developer.valvesoftware.com/wiki/Material_surface_properties

	-- TODO: Any of them unsafe?
	
	default = true,
	default_silent = true,
	floatingstandable = true,
	item = true,
	ladder = true,
	no_decal = true,
	player = true,
	player_control_clip = true,
	
	baserock = true,
	boulder = true,
	brick = true,
	concrete = true,
	concrete_block = true,
	gravel = true,
	rock = true,
	
	canister = true,
	chain = true,
	chainlink = true,
	combine_metal = true,
	crowbar = true,
	floating_metal_barrel = true,
	grenade = true,
	gunship = true,
	metal = true,
	metal_barrel = true,
	metal_bouncy = true,
	metal_seafloorcar = true,
	metalgrate = true,
	metalpanel = true,
	metalvent = true,
	metalvehicle = true,
	paintcan = true,
	popcan = true,
	roller = true,
	slipperymetal = true,
	solidmetal = true,
	strider = true,
	weapon = true,
	
	wood = true,
	Wood_Box = true,
	Wood_Crate = true,
	Wood_Furniture = true,
	Wood_lowdensity = true,
	Wood_Plank = true,
	Wood_Panel = true,
	Wood_Solid = true,
	
	dirt = true,
	grass = true,
	gravel = true,
	mud = true,
}]]

local ValidMaterials = {
	["metal_bouncy"] = true,
	["metal"] = true,
	["default"] = true,
	["dirt"] = true,
	["slipperyslime"] = true,
	["wood"] = true,
	["glass"] = true,
	["concrete_block"] = true,
	["ice"] = true,
	["rubber"] = true,
	["paper"] = true,
	["zombieflesh"] = true,
	["gmod_ice"] = true,
	["gmod_bouncy"] = true,
	["gmod_silent"] = true, 
}

if CLIENT then
	-- Currently selected entity
	local selected = nil
	
	-- Language and stuff
	language.Add( "Tool_allinoneproperties_name", "All-In-One Properties Tool" )
	language.Add( "Tool_allinoneproperties_desc", "Sets the physical properties of an entity." )
	language.Add( "Tool_allinoneproperties_0", "Left click to select an entity to modify. Left click on the selected entity to apply changes." )

	-- ------------------------------------------------------ --
	-- Client Functions
	-- ------------------------------------------------------ --
	
	-- Convert the valid materials lookup to a table compatible with a combo box
	local MaterialsComboBox = {}
	do
		for k,_ in pairs(ValidMaterials) do
			MaterialsComboBox[k] = {allinoneproperties_surface=k}
		end
	end
	
	local function BuildCPanel(panel)
		panel:ClearControls()
		panel:SetSpacing(5)
		
		if selected and not selected:IsValid() then selected = nil end
		
		panel:AddControl( "Header", { Text = "All-In-One Properties Tool", Description = "Modify entity properties such as mass, buoyancy, etc." }  )
		
		if not selected then
			panel:AddControl( "Label", { Text = "No entity selected." }  )
		else
			panel:AddControl( "Label", { Text = "Type: "..selected:GetClass() } )
			panel:AddControl( "Label", { Text = "Model: "..selected:GetModel() } )
			
			panel:Button("Apply Properties", "allinoneproperties_apply")
			panel:Button("Reset Properties", "allinoneproperties_reset")
			
			panel:AddControl( "Label", { Text = "Values of -1 mean an unknown value." } )
			panel:AddControl( "DVerticalDivider", {} )
			
			panel:AddControl( "Label", { Text = "Surface Type:" } )
			panel:AddControl("ComboBox", {
				Label = "Surface Type:",
				MenuButton = "0",
				Options = MaterialsComboBox,
			})
			panel:NumSlider("Mass","allinoneproperties_mass",1,50000)
			panel:NumSlider("Buoyancy","allinoneproperties_buoyancy",0,1,3)
			panel:CheckBox("Enable Drag","allinoneproperties_dragenable")
			panel:NumSlider("Linear Drag","allinoneproperties_posdrag",0,100,0)
			panel:NumSlider("Angular Drag","allinoneproperties_angdrag",0,100,0)
			panel:NumSlider("Linear Dampening","allinoneproperties_posdamp",0,100,0)
			panel:NumSlider("Angular Dampening","allinoneproperties_angdamp",0,100,0)
			panel:CheckBox("Enable Gravity","allinoneproperties_grav")
			panel:CheckBox("Disable Player Pickup","allinoneproperties_nopickup")
			--panel:CheckBox("Was Thrown (Activates Explosives)","allinoneproperties_wasthrown")
			panel:CheckBox("Disable Impact Damage","allinoneproperties_noimpactdmg")
		end
	end
	
	-- Usermessage to update selected entity
	local function umsg_cbk(msg)
		selected = msg:ReadEntity()
		BuildCPanel(GetControlPanel( "allinoneproperties" ))
	end
	usermessage.Hook("allinoneproperties_select",umsg_cbk)
	
	-- ------------------------------------------------------ --
	-- Client Tool Hooks
	-- ------------------------------------------------------ --
	
	function TOOL:LeftClick(trace)
		return true
	end
	function TOOL:RightClick(trace) return false end
	
	function TOOL.BuildCPanel( panel )
		BuildCPanel(panel)
	end
	
else
	-- player : selected entity table
	local selected = {}

	-- ------------------------------------------------------ --
	-- Server Functions
	-- ------------------------------------------------------ --
	
	-- Sets/unsets game flag based on a true/false value
	local function SetGameFlag(phys, flag, value)
		if value then
			phys:AddGameFlag(flag)
		else
			phys:ClearGameFlag(flag)
		end
	end
	
	-- Loads the currently selected entity's properties to the client's convars
	local function LoadProperties(ply)
		local ent = selected[ply]
		
		if ent and not ent:IsValid() then
			selected[ply] = nil
			ent = nil
			umsg.Start("allinoneproperties_select",ply)
				umsg.Entity(nil)
			umsg.End()
		end
		
		if ent then
			local phys = ent:GetPhysicsObject()
			ply:ConCommand("allinoneproperties_mass "..tostring(phys:GetMass()))
			ply:ConCommand("allinoneproperties_buoyancy "..tostring(ent.BuoyancyRatio or "-1"))
			local grav = phys:IsGravityEnabled()
			if grav then
				ply:ConCommand("allinoneproperties_grav 1")
			else
				ply:ConCommand("allinoneproperties_grav 0")
			end
			ply:ConCommand("allinoneproperties_surface "..phys:GetMaterial())
			
			ply:ConCommand("allinoneproperties_dragenabled "..tostring(ent.DragEnabled or "1"))
			ply:ConCommand("allinoneproperties_posdrag "..tostring(ent.DragCoefficient or "-1"))
			ply:ConCommand("allinoneproperties_angdrag "..tostring(ent.AngDragCoefficient or "-1"))
			
			local lindamp, angdamp = phys:GetDamping()
			ply:ConCommand("allinoneproperties_posdamp "..tostring(lindamp))
			ply:ConCommand("allinoneproperties_angdamp "..tostring(angdamp))
			
			ply:ConCommand("allinoneproperties_nopickup "..tostring(phys:HasGameFlag(FVPHYSICS_NO_PLAYER_PICKUP) and "1" or "0"))
			--ply:ConCommand("allinoneproperties_wasthrown "..tostring(phys:HasGameFlag(FVPHYSICS_WAS_THROWN) and "1" or "0"))
			ply:ConCommand("allinoneproperties_noimpactdmg "..tostring(phys:HasGameFlag(FVPHYSICS_NO_IMPACT_DMG) and "1" or "0"))
		end
	end
	
	-- ------------------------------------------------------ --
	-- Server Console Commands
	-- ------------------------------------------------------ --
	
	-- Button command to apply changes
	concommand.Add("allinoneproperties_apply", function(ply, cmd, args)
		local ent = selected[ply]
		if not ent or not ent:IsValid() then LoadProperties(ply) return end
		
		local phys = ent:GetPhysicsObject()
		
		-- Material
		local material = ply:GetInfo("allinoneproperties_surface"):lower():Trim()
		if ValidMaterials[material] then phys:SetMaterial(material) end
		
		-- Mass
		phys:SetMass(ply:GetInfoNum("allinoneproperties_mass"))
		
		-- Buoyancy
		local buoyancy = ply:GetInfoNum("allinoneproperties_buoyancy")
		if buoyancy >= 0 then
			phys:SetBuoyancyRatio(buoyancy)
			ent.BuoyancyRatio = buoyancy
		end
		
		-- Gravity
		phys:EnableGravity(ply:GetInfoNum("allinoneproperties_grav") ~= 0)
		
		ply:PrintMessage(HUD_PRINTTALK,"Settings applied.")
		ply:EmitSound("buttons/button3.wav",75,100)
		
		-- Drag
		local dragenabled = ply:GetInfoNum("allinoneproperties_dragenabled") ~= 0
		local lindrag = ply:GetInfoNum("allinoneproperties_posdrag")
		local angdrag = ply:GetInfoNum("allinoneproperties_angdrag")
		
		phys:EnableDrag(dragenabled)
		if lindrag > 0 then phys:SetDragCoefficient(lindrag) end
		if angdrag > 0 then phys:SetAngleDragCoefficient(angdrag) end
		ent.DragEnabled = dragenabled
		ent.DragCoefficient = lindrag
		ent.AngDragCoefficient = angdrag
		
		-- Dampening
		phys:SetDamping(ply:GetInfoNum("allinoneproperties_posdamp"), ply:GetInfoNum("allinoneproperties_angdamp"))
		
		-- Flags
		SetGameFlag(phys,FVPHYSICS_NO_PLAYER_PICKUP,ply:GetInfoNum("allinoneproperties_nopickup") ~= 0)
		--SetGameFlag(phys,FVPHYSICS_WAS_THROWN,ply:GetInfoNum("allinoneproperties_wasthrown") ~= 0)
		SetGameFlag(phys,FVPHYSICS_NO_IMPACT_DMG,ply:GetInfoNum("allinoneproperties_noimpactdmg") ~= 0)
	end)
	
	-- Button command to discard changes
	concommand.Add("allinoneproperties_reset",function(ply,cmd,args)
		LoadProperties(ply)
	end)
	
	-- ------------------------------------------------------ --
	-- Server Tool Hooks
	-- ------------------------------------------------------ --
	
	function TOOL:LeftClick( trace )
		local ent = trace.Entity
		local ply = self:GetOwner()
		
		if ent and not ent:IsValid() then
			ent = nil
		end
		
		if ent == selected[ply] then
			ply:ConCommand("allinoneproperties_apply")
		else
			selected[ply] = ent
			umsg.Start("allinoneproperties_select",ply)
				umsg.Entity(ent)
			umsg.End()
			LoadProperties(ply)
		end
		
		return true
	end
	
	function TOOL:RightClick(trace) return false end
end

-- ------------------------------------------------------ --
-- Duplicator Information
-- ------------------------------------------------------ --
-- TODO: Write this

local function SetBuoyancy( ply, ent, data )
	if CLIENT then return end
	
	local ratio = data.Ratio
	
	local phys = ent:GetPhysicsObject()
	if ( phys:IsValid() ) then
		local ratio = math.Clamp( data.Ratio, -1000, 1000 ) / 100
		ent.BuoyancyRatio = ratio
		phys:SetBuoyancyRatio( ratio )
		phys:Wake()
		
		duplicator.StoreEntityModifier( ent, "buoyancy", data ) 
	end
	
	return true
end
--duplicator.RegisterEntityModifier( "buoyancy", SetBuoyancy )