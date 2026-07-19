print("Loading Backrooms LOL")
_G.TpWorkspace = true
if not LPH_OBFUSCATED then
-- NEVER MENTION STUFF IN LPH_OBFUSCATED
_G.Debug = false

loadstring([[
    function LPH_NO_VIRTUALIZE(f) return f end;
]])();


end

if _G.Started or game.CoreGui:FindFirstChild("HastyLib") then
    return
end

_G.IsTasty=true
_G.Started = true
_G.Soccer = true

repeat task.wait(0.1) until game:IsLoaded()
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
repeat task.wait(0.1) until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
repeat
    task.wait(0.1)
until player:GetAttribute("__LOADED")

local SetLevelRemote = nil
local RebirthRemote = nil
local MoveRemote = nil
-- Tap Heroes transcend/rebirth aksiyon remote'u. Eski kalipla dinamik bulunamadigi
-- icin sabit yaziyoruz (dump'ta TX_Post olarak tespit edildi). Oyun guncellenip
-- remote adi degisirse SADECE burayi guncelle.
local TranscendRemote = "TX_Post"

local InstancingCmds2 = require(game:GetService("ReplicatedStorage").Library.Client.InstancingCmds)
local Message = require(game.ReplicatedStorage.Library.Client.Message)


if InstancingCmds2.GetInstanceID() ~= "TapHeroes" then
    InstancingCmds2.Enter("TapHeroes")
end

repeat
    task.wait(0.2)
until InstancingCmds2.GetInstanceID() == "TapHeroes"


repeat
    for _, obj in ipairs(getgc()) do
        if type(obj) == "function" then
            local source = debug.info(obj, "s")
        
            if source and source:find("ClientModule") then
                local consts = debug.getconstants(obj)
            
                if #consts == 2 then
                    if consts[2] == "FireCustom" then
                        SetLevelRemote = consts[1]
                    end
                end
                if debug.info(obj, "l") == 798 then
                    debug.setupvalue(require(workspace.__THINGS.__INSTANCE_CONTAINER.Active.TapHeroes.ClientModule).OnJoin,11,false)
                    task.wait(0.1)
                    obj()
                end
            end
        end
    end
    
    task.wait(2)
    
    -- (Transcend/rebirth butonuna basma kaldirildi: eskiden RebirthRemote'u
    --  kesfetmek icindi; artik aksiyonu asagida butonla atesledigimiz icin
    --  gereksiz ve baslangicta yanlislikla aksiyon attirabilir.)
    for _, obj in ipairs(getgc()) do
        if type(obj) == "function" then
            local source = debug.info(obj, "s")
        
            if source and source:find("ClientModule") then
                local consts = debug.getconstants(obj)
                
                if #consts == 6 and consts[6] == "FireCustom" then
                    RebirthRemote = consts[5]
                end
            
                if consts[4] == "FireCustom" and consts[6] == "InvokeCustom" then
                    MoveRemote = consts[5]
                end
            end
        end
    end
    print(SetLevelRemote,RebirthRemote,MoveRemote)
    task.wait(1)
until SetLevelRemote and MoveRemote


InstancingCmds2.Leave()

setthreadidentity(8)
task.wait(0.1)
local Character = player.Character or player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local random = Random.new()

if not LibLoaded then
    local data = nil
    script_key = "aNSJkYrsHKaMrbCNUCnFSOtHHOMcblSU";
    repeat
        local success, response = pcall(function()
            return request({
                Url = "https://api.luarmor.net/files/v4/loaders/9ea51616f5d249bc4c77a976aae4aa2c.lua",
                Method = "GET"
            })
        end)
        if success and response and response.Body then
            data = response.Body
        else
            warn("Request failed, retrying...")
        end
        print(type(data))
        task.wait(2)
    until type(data) == "string"
    print("[AutoRank] Library response loaded")
    task.spawn(function()
        loadstring(data)()
    end)
end


print("Waiting for library")
repeat wait() until LibLoaded
print("Library ready")

print("Making UI")
local Window = lib:CreateWindow("Tasty Tap Heroes", true)
print("UI Window Created")
local StatusStat = Window:AddStat("Status", "Idling")
print("Status Stat Created")
Window:AddSeperator()
local HugeStat = Window:AddStat("Session Huges", "0/0")
local TitanicStat = Window:AddStat("Session Titanics", "0/0")
Window:AddSeperator()
local TotalEggsOpened = Window:AddStat("Total Eggs Hatched", 0)
local ObsidianGiftStat = Window:AddStat("Total Obsidian Gift", "0 (+0/hr)")
local TimeEclapsedStat = Window:AddStat("Time Farmed", "00:00:00")
Window:AddSeperator()
local MarbleCoinStat = Window:AddStat("Current Marble Coins","0")
local RebirthsStat = Window:AddStat("Rebirths",0)
local TranscendStat = Window:AddStat("Transcends",0)
local LevelStat = Window:AddStat("Current Level","0/0")
local StageProgressStat = Window:AddStat("Current Stage Progress","0/10")

local function StatusUpdate(text)
    StatusStat:Update(tostring(text or ""))
end
local startTime = os.clock()
local StartEggs = DataInventory.EggsHatched or 0
local lastEquip = 0
local keys = {}

-- Envanter sayaci (PlazaPlus'taki GetItemAmount ile ayni yontem):
-- GetItem("Lootbox", ...) yanlis sinifa bakip 0 donebiliyordu. Bunun yerine
-- envanterin TAMAMINI gezip id'si eslesen her yiginin "_am" adedini topluyoruz.
local InventoryCmds
do
    pcall(function()
        if Library and Library.InventoryCmds and Library.InventoryCmds.State then
            InventoryCmds = Library.InventoryCmds
        end
    end)
    if not InventoryCmds then
        pcall(function()
            InventoryCmds = require(game:GetService("ReplicatedStorage").Library.Client.InventoryCmds)
        end)
    end
end

local function GetItemAmount(TargetId)
    local Total = 0
    local ok = pcall(function()
        local State = InventoryCmds.State().container._store._byType
        for _, Inventory in pairs(State) do
            if Inventory and Inventory._byUID then
                for _, ItemTable in pairs(Inventory._byUID) do
                    local ItemId = ItemTable.GetId and ItemTable:GetId()
                        or (ItemTable._data and ItemTable._data.id)
                    if ItemId == TargetId then
                        Total = Total + ((ItemTable._data and ItemTable._data["_am"]) or 1)
                    end
                end
            end
        end
    end)
    if not ok then return nil end
    return Total
end

-- Obsidian Gift: ana sayi = hesaptaki mevcut adet, yanindaki = saatlik farm hizi.
-- Hiz icin sadece ARTISLARI topluyoruz (acilinca dusen sayiyi farm sayma).
local LastGiftCount = GetItemAmount("Obsidian Gift") or 0
local TotalGiftsFarmed = 0

task.spawn(function()
    while task.wait() do
        local now = os.clock()

        TimeEclapsedStat:Update(tostring(utils:FormatTime(now - startTime)))
        TotalEggsOpened:Update(utils:FormatNumber((DataInventory.EggsHatched or 0) - StartEggs))

        -- Obsidian Gift: mevcut adedi oku, artislari da hiz icin biriktir
        local curGifts = GetItemAmount("Obsidian Gift")
        if curGifts then
            if curGifts > LastGiftCount then
                TotalGiftsFarmed = TotalGiftsFarmed + (curGifts - LastGiftCount)
            end
            LastGiftCount = curGifts
        end

        local elapsed = now - startTime
        local giftsPerHour = 0
        if elapsed >= 1 then
            giftsPerHour = TotalGiftsFarmed / (elapsed / 3600)
        end
        ObsidianGiftStat:Update(
            utils:FormatNumber(LastGiftCount)
            .. " (+" .. utils:FormatNumber(math.floor(giftsPerHour)) .. "/hr)"
        )

        HugeStat:Update(tostring(sessionHuges or 0))
        TitanicStat:Update(tostring(sessionTitans or 0))
        MarbleCoinStat:Update(utils:FormatNumber(GetItem("Currency", "MarbleCoins")))

        if Config["AutoOpenGifts"] then
            local currentGift = "Obsidian Gift"
    		local count = GetItem("Lootbox", currentGift)

    		if count and count > 0 then
    			pcall(function()
    				local amountToOpen = math.min(count, 8)
    				print(Network.Invoke(
    					"Lootbox: Open",
    					GetItem("Lootbox", currentGift, true),
    					amountToOpen,
    					ComputePositions(amountToOpen)
    				))
    			end)
    		end
        end

        
        if Config["AutoUseBoosts"] then
            local Boosts = {
                "Tap Damage Booster",
                "Pristine Marble Clover",
                "Polished Marble Clover",
                "Cracked Marble Clover"
            }
        
            for _, boost in ipairs(Boosts) do
                local item = GetItem("Consumable", boost, true)
            
                if item then
                    pcall(function()
                        Network.Invoke("Consumables_Consume", item, 1)
                    end)
                end
            end
        end

        if (os.clock() - lastEquip) > 2 then            
            for upgradeName, maxLevel in pairs(Config and Config["Upgrades"] or {}) do
                local owned = DataInventory
                    and DataInventory["EventUpgrades"]
                    and DataInventory["EventUpgrades"][upgradeName]
            
                local currentLevel = owned or 0
            
                if currentLevel < maxLevel then
                    task.spawn(function()
                        Network.Invoke("EventUpgrades: Purchase", upgradeName)                        
                    end)
                end
            end
            lastEquip = os.clock()
        end
    end
end)

local ratelimit = 30
local lastCall = 0
local cooldown = 60 / ratelimit

local function CalcEggPricePlayer(id,v10)
    local v11 = "Egg_" .. string.gsub(id, " ", "")

    
    local FFlags = require(game.ReplicatedStorage.Library.Client.FFlags)
    if FFlags.Keys[v11] and FFlags.Get(FFlags.Keys[v11]) then
        v10 = FFlags.Get(FFlags.Keys[v11])
    end

    if string.sub(id, 1, 14) == "Tap Heroes Egg" then
        local n1 = 0
        local n2 = 120
        local n3 = DataInventory.TapHeroes.Rebirths or 0


        local FFlags = require(game.ReplicatedStorage.Library.Client.FFlags)
        local ok, result = pcall(function() -- line: 103
            return FFlags.Get(FFlags.Keys.TapHeroes_EggRebirthSlope)
        end)
        if ok and type(result) == "number" and result == result and result >= 0 then
            n1 = result
        end
        local ok4, result4 = pcall(function()
            return FFlags.Get(FFlags.Keys.TapHeroes_RebirthScaleCap)
        end)
        if ok4 and type(result4) == "number" and result4 == result4 and result4 >= 0 then
            n2 = result4
        end

        if n3 > 0 and n1 > 0 then
            v10 = math.max(1, (math.floor(v10 * (n1 * math.min(n3, n2) + 1))))
        end

        local v33 = require(game.ReplicatedStorage.Library.Client.FFlags)
        local ok, result = pcall(function()
            return v33.Get(v33.Keys.TapHeroes_EggCostMult)
        end)

        if ok and type(result) == "number" and result == result and result > 0 then
            v10 = math.max(1, (math.floor(v10 * result)))
        end
    end

    return v10
end

local function HatchEgg(uid,pos,id)
    local now = os.clock()

    if (now - lastCall) < cooldown then
        return
    end

    lastCall = now
    local eggData
    local success, result = pcall(function()
        return Directory.Eggs[id]
    end)

    if success then
        eggData = result
    end

    local eggPrice = (eggData and eggData.overrideCost)

    eggPrice = CalcEggPricePlayer(id,eggPrice) 

    if not eggPrice then
        warn("No egg price for zone", bestZone)
        return
    end

    local amount = math.min(
        GetMaxHatch(),
        math.floor(GetItem("Currency", "MarbleCoins") / eggPrice)
    )
    if amount <= 0 then
        return
    end
    if pos then
        TeleportPlayer(pos)
        task.wait(0.05)
    end
    Network.Invoke("CustomEggs_Hatch", uid, amount)
end

local function HatchNearest()
	local nearestId = nil
	local nearestDistance = math.huge
    local nearestPos = nil
    local nearestData = nil

	for uid, data in pairs(CustomEggs) do
		if data and data.position then
			local distance = (HumanoidRootPartPosition - data.position).Magnitude
			if distance < nearestDistance and data.hatchable then
				nearestDistance = distance
				nearestId = uid
                nearestPos = data.position
                nearestData = data
			end
		end
	end
    task.spawn(function()
        if nearestId then
            HatchEgg(nearestId,nearestPos,nearestData.id)
        end
    end)
end

local function SetLevel(Level, asd)
    if DataInventory.TapHeroes.CurrentZone == Level then
        return
    end
    StatusUpdate("Setting Stage Level to: " .. tostring(Level) .. " With remote: " .. tostring(SetLevelRemote))
    Network.Invoke("Instancing_InvokeCustomFromClient", "TapHeroes", SetLevelRemote, Level)
end

-- hier ist auto rank teile

local Name,zoneData = GetMaxOwnedZone()
local NextName, nextData = GetNextZone()

local WORLD_TELEPORTS = {
    [1] = CFrame.new(533, 17, 315),
    [2] = CFrame.new(-9908, 18, -555),
    [3] = CFrame.new(-10180, 3, -7374)
}

local BlockedPotions = {
    "Walkspeed 3"
}

local function upgradePotions(amount, minTn)
	minTn = minTn or 0

	if not amount or amount <= 0 then
		return
	end

	if GetMaximumOverallZone().ZoneNumber < 13 then
		return
	end

	local function teleportIfNeeded()
		if (DataInventory.Rebirths or 0) < 9 then
			local world = DataInventory.RecentWorld
			local targetCFrame = WORLD_TELEPORTS[world]

			if targetCFrame then
				TeleportPlayer(targetCFrame)
				task.wait(1)
			end
		end
	end

	for potionId, potionData in pairs((DataInventory.Inventory and DataInventory.Inventory.Potion) or {}) do
		local potionName = potionData.id .. " " .. potionData.tn

		if table.find(BlockedPotions, potionName) then
			continue
		end

		if potionData.tn >= 1
			and potionData.tn <= 4
			and potionData.tn >= minTn then

			local requiredPerCraft = Balancing.CalcPotionsPerTierRequired(potionData.tn)
			local totalRequired = requiredPerCraft * amount
			local owned = potionData._am or 1

			if owned >= totalRequired then
				local price = Balancing.CalcPotionUpgradeCost(potionData.tn + 1) * amount
				local diamonds = GetItem("Currency", "Diamonds", false)

				if diamonds >= price then
					teleportIfNeeded()

					StatusStat:Update(
						"Making Potions: "
							.. potionName
							.. " x"
							.. amount
							.. " (Cost: "
							.. price
							.. "/"
							.. diamonds
							.. ")"
					)

					Network.Invoke(
						"UpgradePotionsMachine_Activate",
						potionId,
						amount
					)

					task.wait(0.1)
					return
				end
			end
		end
	end
end

local function usePotion(amount, tier)
    for uid, potionData in pairs((DataInventory.Inventory and DataInventory.Inventory.Potion) or {}) do
        local potionTier = potionData.tn
        local potionAmount = potionData._am or 1

        if tier <= potionTier and amount <= potionAmount then
            Network.Fire("Potions: Consume", tostring(uid), amount)
            break
        end
    end
end

local blockedEnchants = {
    "Magnet 3",
    "Tap Teamwork 1",
    "Large Taps 1",
    "Exotic Pet 1",
    "Midas Touch 1",
    "Fortune 1",
    "Explosive 1",
    "Lightning 1",
    "Super Lightning 1",
    "Shiny Hunter 1",
    "Huge Hunter 1",
    "Happy Pets 1",
    "Fireworks 1",
    "Blast 1"
}

local function teleportIfNeededEnchants()
	if (DataInventory.Rebirths or 0) < 9 then
		if DataInventory.RecentWorld == 1 then
			TeleportPlayer(CFrame.new(902, 17, 481))
		elseif DataInventory.RecentWorld == 2 then
			TeleportPlayer(CFrame.new(-9908, 18, -555))
		elseif DataInventory.RecentWorld == 3 then
			TeleportPlayer(CFrame.new(-10180, 3, -7374))
        else
            TeleportPlayer(CFrame.new(902, 17, 481))
        end
		task.wait(1)
	end
end

local function upgradeEnchants(amount, minTn)
	minTn = minTn or 0
	if not amount or amount <= 0 then
		return
	end

	if GetMaximumOverallZone().ZoneNumber < 16 then
		return
	end

	-- normal bulk upgrade
	for enchantId, enchantData in pairs((DataInventory.Inventory and DataInventory.Inventory.Enchant) or {}) do
		local enchantName = enchantData.id .. " " .. enchantData.tn

		if enchantData.tn
			and enchantData.tn >= 1
			and not table.find(blockedEnchants, enchantName)
			and enchantData.tn >= minTn then

			local requiredPerCraft = Balancing.CalcEnchantsPerTierRequired(enchantData.tn)
			local totalRequired = requiredPerCraft * amount
			local owned = enchantData._am or 1
            
			if owned >= totalRequired then
				local price = Balancing.CalcEnchantUpgradeCost(enchantData.tn + 1) * amount
				local diamonds = GetItem("Currency", "Diamonds", false)

				if diamonds >= price then
					teleportIfNeededEnchants()

					StatusStat:Update(
						"Making Enchants: "
							.. enchantName
							.. " x"
							.. amount
							.. " (Cost: "
							.. price
							.. "/"
							.. diamonds
							.. ")"
					)

					Network.Invoke("UpgradeEnchantsMachine_Activate", enchantId, amount)

					task.wait(0.1)
					return
				end
			end
		end
	end
end

local function teleportToGoldMachine()
    if DataInventory.Rebirths >= 9 then
        return
    end

    if DataInventory.RecentWorld == 1 then
        TeleportPlayer(Vector3.new(348, 17, 1307))
        task.wait(0.5)

    elseif DataInventory.RecentWorld == 2 then
        TeleportPlayer(CFrame.new(-9908, 18, -555))
        task.wait(0.5)

    elseif DataInventory.RecentWorld == 3 then
        TeleportPlayer(CFrame.new(-10180, 3, -7371))
        task.wait(0.5)
    end
end


local function PurchaseBestEgg()
    local now = os.clock()

    if (now - lastCall) < cooldown then
        return
    end

    lastCall = now

    task.spawn(function()
        local eggModule = getBestEggModule()
        if not eggModule or not eggModule.name then
            warn("[AutoEgg] No best egg found")
            return
        end

        if not DataInventory["UnlockedEggs"][eggModule.eggNumber] then
            Network.Invoke("Eggs_RequestUnlock", eggModule.name)
        end

        local price = Balancing.CalcEggPrice(eggModule)
        local currency = GetItem("Currency", eggModule.currency, false)
        local maxHatch = GetMaxHatch()

        local affordable = math.floor(currency / price)
        local hatchAmount = math.min(maxHatch, affordable)

        if hatchAmount <= 0 then
            return
        end

        local result = Network.Invoke(
            "Eggs_RequestPurchase",
            eggModule.name,
            hatchAmount
        )
    end)
end


local function teleportToRainbowdMachine()
    if DataInventory.Rebirths < 9 then
        if DataInventory.RecentWorld == 1 then
            TeleportPlayer(CFrame.new(672, 17, 1786))
            task.wait(1)

        elseif DataInventory.RecentWorld == 2 then
            TeleportPlayer(CFrame.new(-9908, 18, -555))
            task.wait(1)

        elseif DataInventory.RecentWorld == 3 then
            TeleportPlayer(CFrame.new(-10180, 3, -7371))
            task.wait(0.5)
        end
    end
end


local function goldPet(need)
    local pets = GetBestNormalPetsUID()
    local found, uid, amount, petName = findPetWithEnoughAmount(pets, need)

    if found and need > 0 then
        teleportToGoldMachine()

        StatusStat:Update(
            "Making Gold Pets: " .. tostring(petName) .. " x" .. tostring(need)
        )

        local success, err = Network.Invoke("GoldMachine_Activate", uid, need)
        if not success then
            StatusStat:Update("Failed to make Gold pets: " .. tostring(err))
            task.wait(0.2)
        end

        return success, err
    end

    found, uid, amount, petName = findPetWithEnoughAmount(pets, 20)

    if found then
        teleportToGoldMachine()

        StatusStat:Update(
            "Making Gold Pets For Rainbow Pets: " .. tostring(petName) .. " x20"
        )

        local success, err = Network.Invoke("GoldMachine_Activate", uid, 20)
        if not success then
            StatusStat:Update("Failed to make Gold pets: " .. tostring(err))
            task.wait(0.2)
        end

        return success, err
    end
end


local function rainbowPet(need)
    local goldenPets = GetBestGoldenPetsUID()
    local found, uid, amount, petName = findPetWithEnoughAmount(goldenPets, need)

    if found and need > 0 then
        local craftAmount = math.min(amount or 0, need or 0)

        teleportToRainbowdMachine()

        StatusStat:Update(
            "Making Rainbow Pets: " .. tostring(petName) .. " x" .. tostring(craftAmount)
        )

        local success, err = Network.Invoke("RainbowMachine_Activate", uid, craftAmount)
        if not success then
            StatusStat:Update("Failed to make Rainbow pets: " .. tostring(err))
            task.wait(0.2)
        end

        return success, err
    end

    for uid, petData in pairs(goldenPets) do
        if petData.Amount >= 10 then
            local craftAmount = math.min(math.floor(petData.Amount / 10), need or 0)

            if craftAmount >= 2 then
                teleportToRainbowdMachine()

                StatusStat:Update(
                    "Making Partial Rainbow Pets: " .. tostring(petData.id) .. " x" .. tostring(craftAmount)
                )

                Network.Invoke("RainbowMachine_Activate", uid, craftAmount)
                task.wait(0.5)

                need -= craftAmount
            end

            if need <= 0 then
                break
            end
        end
    end

    for uid, petData in pairs(GetBestNormalPetsUID()) do
        if petData.Amount >= 150 then
            local convertAmount = math.floor(petData.Amount / 10)

            teleportToGoldMachine()

            StatusStat:Update(
                "Making Gold Pets For Rainbow Pets: " .. tostring(petData.id) .. " x" .. tostring(convertAmount)
            )

            task.wait(0.5)

            local success, err = Network.Invoke("GoldMachine_Activate", uid, convertAmount)
            if not success then
                StatusStat:Update("Failed to make Gold pets: " .. tostring(err))
                task.wait(0.2)
            end
        end
    end
end


local function TryPurchaseNextZone(nextName, nextZoneData)
    if not nextName then
        return false
    end

    local success, err = Network.Invoke("Zones_RequestPurchase", nextName)

    if not success then
        err = tostring(err)

        local rebirthReq = err:match("Rebirth%s*(%d+)")
        if rebirthReq then
            print("You need Rebirth " .. rebirthReq .. " to unlock this zone!")
            Network.Invoke("Rebirth_Request",tostring(rebirthReq))
        else
            print("Purchase failed:", err)
        end

        return false, err
    end

    return success, err
end

local DoEasyQuest = nil
local Item_To_Event = {
    ["Mini Pinata"] = "Pinata",
    ["Basic Coin Jar"] = "CoinJar",
    ["Comet"] = "Comet",
    ["Mini Lucky Block"] = "LuckyBlock"
}

local function HandleMiscQuest(questIndex, questData, itemName, remoteName, needed, flags)
    Name,zoneData = GetMaxOwnedZone()
    local itemAmount = tonumber(GetItem("Misc", itemName)) or 0

    if itemAmount < needed and not Config["UsePartyBoxFallback"] then
        StatusUpdate("Not enough " .. tostring(itemName) .. " " .. tostring(itemAmount) .. "/" .. tostring(needed))
        return
    end

    local startUID = questData.UID

    while task.wait(0.1) do
        PurchaseBestEgg()
        TeleportToBestArea()
        DoEasyQuest()

        local currentQuest = DataInventory.Goals and DataInventory.Goals[questIndex]

        if not currentQuest then
            StatusUpdate("Done Spawning quest gone: " .. tostring(itemName))
            break
        end

        if currentQuest.UID ~= startUID then
            StatusUpdate("Done Spawning UID: " .. tostring(itemName))
            break
        end

        StatusUpdate(
            "Spawning "
            .. tostring(itemName)
            .. " ("
            .. tostring(currentQuest.Progress)
            .. "/"
            .. tostring(currentQuest.Amount)
            .. ")"
        )

        local itemRef = GetItem("Misc", itemName, true)
        local currentAmount = tonumber(GetItem("Misc", itemName)) or 0

        local eventName = Item_To_Event[itemName]
        if itemRef and currentAmount > 0 then
            TeleportToBestArea()
            task.wait(0.1)

            TeleportToBestArea()
            Network.Invoke(remoteName, itemRef)
            task.wait(1)
        elseif Config["UsePartyBoxFallback"] then
            local partyRef = GetItem("Misc", "Party Box", true)
            local partyAmount = tonumber(GetItem("Misc", "Party Box")) or 0

            if partyRef and partyAmount > 0 then
                StatusUpdate(
                    "Using Party Box Fallback ("
                    .. tostring(partyAmount)
                    .. " left)"
                )

                Network.Invoke("PartyBox_Consume", partyRef)
            else
                StatusUpdate("No more Party Boxes")
                break
            end
        else
            StatusUpdate("Item gone mid-quest: " .. tostring(itemName))
            break
        end

        task.wait(0.1)
    end

    task.wait(0.1)
end

DoEasyQuest = function(ignoreTp)
    for questIndex, questData in pairs(DataInventory.Goals or {}) do
        local Needed = questData.Amount - questData.Progress

        if questData.Type == 14 or questData.Type == 12 then
            upgradePotions(Needed, math.max(tonumber(tonumber(questData.PotionTier) or 0) - 1, 1))
            continue
        end

        if questData.Type == 15 or questData.Type == 13 then
            upgradeEnchants(Needed, math.max(tonumber(tonumber(questData.EnchantTier) or 0) - 1, 0))
            continue
        end

        if questData.Type == 40 or questData.Type == 4 then
            task.spawn(function()
                if DataInventory.RecentWorld == 2 then
                    return
                end
                PurchaseBestEgg()
            end)
            goldPet(Needed)
            continue
        end

        if questData.Type == 41 then
            task.spawn(function()
                if DataInventory.RecentWorld == 2 then
                    return
                end
                PurchaseBestEgg()
            end)
            rainbowPet(Needed)
            continue
        end
        if questData.Type == 34 then
            print("Use potions", Needed,questData.PotionTier or 1)
            usePotion(Needed, questData.PotionTier or 1)
            continue
        end

        if questData.Type == 6 then
            local NextName, nextData = GetNextZone()
            local currencyAmount = tonumber(GetItem("Currency", WorldsUtil.GetWorldCurrencyId())) or 0
            local gatePrice = nextData and (tonumber(CalcGatePrice(nextData)) or math.huge) or math.huge
            if NextName and currencyAmount > gatePrice then
                TryPurchaseNextZone(NextName, nextData)
            end
            continue
        end

        if questData.Type == 33 then
            local coinsFlagAmount = tonumber(GetItem("Misc", "Coins Flag")) or 0
            local magnetFlagAmount = tonumber(GetItem("Misc", "Magnet Flag")) or 0
        
            if coinsFlagAmount and coinsFlagAmount > 0 then
                Network.Invoke("FlexibleFlags_Consume", "Coins Flag", GetItem("Misc", "Coins Flag", true), 1)
            elseif magnetFlagAmount and magnetFlagAmount > 0 then
                Network.Invoke("FlexibleFlags_Consume", "Magnet Flag", GetItem("Misc", "Magnet Flag", true), 1)
            end
        
            continue
        end

        if questData.Type == 3 or questData.Type == 20 or questData.Type == 42 then
            PurchaseBestEgg()
            continue
        end
    end
    if ignoreTp then
        return
    end
    TeleportToBestArea()
end


local function CurrentRankNumber()
    return tonumber(DataInventory and DataInventory.Rank) or 1
end

local function DoQuest(flags)
    flags = flags or {}

    DoEasyQuest()
    TeleportToBestArea()
    for questIndex, questData in pairs(DataInventory.Goals or {}) do

        local Needed = questData.Amount - questData.Progress
        if questData.Type == 37 or questData.Type == 31 then
            HandleMiscQuest(questIndex, questData, "Basic Coin Jar", "CoinJar_Spawn", Needed, flags)
            continue
        end

        if questData.Type == 43 then
            HandleMiscQuest(questIndex, questData, "Mini Pinata", "MiniPinata_Consume", Needed, flags)
            continue
        end

        if questData.Type == 44 then
            HandleMiscQuest(questIndex, questData, "Mini Lucky Block", "MiniLuckyBlock_Consume", Needed, flags)
            continue
        end

        if questData.Type == 38 or questData.Type == 32 then
            HandleMiscQuest(questIndex, questData, "Comet", "Comet_Spawn", Needed, flags)
            continue
        end

        if questData.Type == 42 then
            if GetBestEggNumber() >= 256 then
                local startUID = questData.UID
                while true do
                    local currentQuest = DataInventory.Goals and DataInventory.Goals[questIndex]
                    if not currentQuest then break end
                    if currentQuest.UID ~= startUID then break end
                    TeleportToArea(244)
                    Network.Invoke("Eggs_RequestPurchase", "Fairy Mushroom Egg", GetMaxHatch())
                    task.wait(0.1)
                    DoEasyQuest(true)
                end
                TeleportToBestArea()
            end
            continue
        end

        if questData.Type == 1 then
            if questData.BreakableType == "Safe" and GetMaximumOverallZone().ZoneNumber >= 18
                and DataInventory.RecentWorld == 1
            then
                local startUID = questData.UID
                while true do
                    DoEasyQuest(true)
                    StatusUpdate("Farming Safes in Zone 18. " .. tostring(questData.Progress) .. "/" .. tostring(questData.Amount))
                    TeleportToArea(18)
                    questData = DataInventory.Goals and DataInventory.Goals[questIndex]
                    if not questData then break end
                    if questData.UID ~= startUID then break end
                    task.wait(0.1)
                end
                TeleportToBestArea()
                continue
            end

            if questData.BreakableType == "Present" and GetMaximumOverallZone().ZoneNumber >= 10 
                and DataInventory.RecentWorld == 1
            then
                local startUID = questData.UID
            
                while true do
                    DoEasyQuest(true)
                StatusUpdate("Farming Presents in Zone 6. " .. tostring(questData.Progress) .. "/" .. tostring(questData.Amount))
                    TeleportToArea(6)
                
                    questData = DataInventory.Goals and DataInventory.Goals[questIndex]
                    if not questData then break end
                    if questData.UID ~= startUID then break end
                
                    task.wait(0.1)
                end
            
                TeleportToBestArea()
                continue
            end
        end
    end
end

local function CurrentAreaNumber()
    if zoneData and zoneData.ZoneNumber then
        return tonumber(zoneData.ZoneNumber) or 1
    end

    local ok, _, currentZoneData = pcall(GetMaxOwnedZone)
    if ok and currentZoneData and currentZoneData.ZoneNumber then
        return tonumber(currentZoneData.ZoneNumber) or 1
    end

    return 1
end

local RankCmds = require(Library.Client.RankCmds)

local ProcessedBundles = {}

local RankIDFromNumber = LPH_NO_VIRTUALIZE(function(Rank)
	for RankName, RankData in Directory.Ranks do
		if Rank == RankData.RankNumber then
			return RankName
		end
	end

	return nil
end)

local GetMaxPurchasableEggSlots = LPH_NO_VIRTUALIZE(function()
    local total = 0

    for i = 1, (DataInventory.Rank or 1) do
        local rankId = RankIDFromNumber(i)
        if rankId then
            total += Directory.Ranks[rankId].UnlockableEggSlots
        end
    end

    return total
end)


local GetStatus = LPH_NO_VIRTUALIZE(function(bundleEnd)
    local bundleEndSlot, _, previousBundleEnd = RankCmds.GetEggBundle(bundleEnd)
    local maxPurchasableSlots = GetMaxPurchasableEggSlots()
    local purchasedSlots = DataInventory.EggSlotsPurchased

    if bundleEndSlot <= purchasedSlots then
        return "PURCHASED"
    end

    if bundleEndSlot == 1 or (purchasedSlots == previousBundleEnd and bundleEndSlot <= maxPurchasableSlots) then
        return "NEXT"
    end

    if bundleEndSlot <= maxPurchasableSlots then
        return "UNLOCKED"
    end

    return "LOCKED"
end)

local function GenerateBundles(rankData)
    local slotsBeforeRank = RankCmds.GetEggSlotsBeforeRank(rankData.RankNumber)
    local bundles = {}

    for slotOffset = 1, rankData.UnlockableEggSlots do
        local overallSlot = slotsBeforeRank + slotOffset

        local bundleEnd, bundleSize, previousBundleEnd =
            RankCmds.GetEggBundle(overallSlot)

        local bundleData = {
            BundleEnd = bundleEnd,
            BundleSize = bundleSize,
            PreviousBundleEnd = previousBundleEnd,
            OverallSlot = overallSlot
        }

        local alreadyAdded = false

        for _, existingBundle in ipairs(bundles) do
            if existingBundle.BundleEnd == bundleEnd then
                alreadyAdded = true
                break
            end
        end

        if not alreadyAdded then
            table.insert(bundles, bundleData)
        end
    end

    return bundles
end

local function teleportIfNeeded()
	if (DataInventory.Rebirths or 0) < 9 then
		if DataInventory.RecentWorld == 1 then
			TeleportPlayer(CFrame.new(538, 17, 79))
		elseif DataInventory.RecentWorld == 2 then
			TeleportPlayer(CFrame.new(-9908, 18, -555))
		elseif DataInventory.RecentWorld == 3 then
			TeleportPlayer(CFrame.new(-10180, 3, -7374))
		end

		task.wait(0.4)
	end
end

local function EggUpgrades()
    if GetMaximumOverallZone().ZoneNumber < 8 then
		return
	end

    local highestBundleEnd = 0

    for _, rankData in Directory.Ranks do
        local bundles = GenerateBundles(rankData)

        for _, bundle in ipairs(bundles) do
            highestBundleEnd = math.max(highestBundleEnd, bundle.BundleEnd)

            if not ProcessedBundles[bundle.BundleEnd] then
                local status = GetStatus(bundle.BundleEnd)

				if status == "NEXT" then
					local price = 0
					local idk = bundle.BundleEnd - bundle.BundleSize

					for i = 1, bundle.BundleSize do
						price += Balancing.CalcEggSlotPrice(idk + i)
					end
					
                    if GetItem("Currency", "Diamonds") < price then
                        return
                    end

                    teleportIfNeeded()
                    task.wait(0.2)

                    print("Egg slot",Network.Invoke("EggHatchSlotsMachine_RequestPurchase", bundle.BundleEnd))
				end
            end
        end
    end
end

local FreeStuff = {
    [1] = {
        ["DailyDiamonds1"] = {
            type = "DailyRewards_Redeem",
            zone = 3
        },
        ["Upgrades_Purchase1"] = {
            type = "Upgrades_Purchase",
            zone = 4,
            zoneName = "Green Forest",
            upgradeType = "Diamonds",
            tier = 1,
            price = 200,
            position = CFrame.new(755, 17, -243)
        },
        ["PotionVendingMachine1"] = {
            type = "VendingMachines_Purchase",
            zone = 6
        },
        ["Tap Damage1"] = {
            type = "Upgrades_Purchase",
            zone = 8,
            zoneName = "Backyard",
            upgradeType = "Tap Damage",
            tier = 1,
            price = 300,
            position = CFrame.new(472, 17, 63)
        },
        ["EnchantVendingMachine1"] = {
            type = "VendingMachines_Purchase",
            zone = 9
        },
        ["Upgrades_Purchase2"] = {
            type = "Upgrades_Purchase",
            zone = 10,
            zoneName = "Mine",
            upgradeType = "Diamonds",
            tier = 2,
            price = 400,
            position = CFrame.new(250, 17, 133)
        },
        ["PetSpeed1"] = {
            type = "Upgrades_Purchase",
            zone = 12,
            zoneName = "Dead Forest",
            upgradeType = "Pet Speed",
            tier = 1,
            price = 500,
            position = CFrame.new(438, 17, 239)
        },
        ["FruitVendingMachine1"] = {
            type = "VendingMachines_Purchase",
            zone = 14
        },
        ["Drops1"] = {
            type = "Upgrades_Purchase",
            zone = 16,
            zoneName = "Crimson Forest",
            upgradeType = "Drops",
            tier = 1,
            price = 650,
            position = CFrame.new(796, 17, 526)
        },
        ["DailyPotions1"] = {
            type = "DailyRewards_Redeem",
            zone = 17
        },
        ["Pet Damage1"] = {
            type = "Upgrades_Purchase",
            zone = 18,
            zoneName = "Jungle Temple",
            upgradeType = "Pet Damage",
            tier = 1,
            price = 700,
            position = CFrame.new(467, 17, 535)
        },
        ["Diamonds3"] = {
            type = "Upgrades_Purchase",
            zone = 20,
            zoneName = "Beach",
            upgradeType = "Diamonds",
            tier = 3,
            price = 900,
            position = CFrame.new(242, 16, 554)
        },
        ["DailyEnchants1"] = {
            type = "DailyRewards_Redeem",
            zone = 21
        },
        ["Luck1"] = {
            type = "Upgrades_Purchase",
            zone = 22,
            zoneName = "Shipwreck",
            upgradeType = "Diamonds",
            tier = 1,
            price = 1000,
            position = CFrame.new(439, -31, 747)
        },
        ["DailyItems1"] = {
            type = "DailyRewards_Redeem",
            zone = 24
        },
        ["FruitVendingMachine2"] = {
            type = "VendingMachines_Purchase",
            zone = 26
        },
        ["Coins1"] = {
            type = "Upgrades_Purchase",
            zone = 26,
            zoneName = "Pirate Cove",
            upgradeType = "Coins",
            tier = 1,
            price = 1250,
            position = CFrame.new(913, 17, 1042)
        },
        ["Tap Damage2"] = {
            type = "Upgrades_Purchase",
            zone = 28,
            zoneName = "Shanty Town",
            upgradeType = "Tap Damage",
            tier = 2,
            price = 1500,
            position = CFrame.new(615, 17, 1058)
        },
        ["Pet Speed2"] = {
            type = "Upgrades_Purchase",
            zone = 30,
            zoneName = "Fossil Digsite",
            upgradeType = "Pet Speed",
            tier = 2,
            price = 1250,
            position = CFrame.new(397, 17, 1125)
        },
        ["DailyDiamonds2"] = {
            type = "DailyRewards_Redeem",
            zone = 32
        },
        ["Diamonds4"] = {
            type = "Upgrades_Purchase",
            zone = 33,
            zoneName = "Wild West",
            upgradeType = "Diamonds",
            tier = 4,
            price = 3000,
            position = CFrame.new(732, 16, 1234)
        },
        ["PotionVendingMachine2"] = {
            type = "VendingMachines_Purchase",
            zone = 35
        },
        ["Pet Damage2"] = {
            type = "Upgrades_Purchase",
            zone = 36,
            zoneName = "Mountains",
            upgradeType = "Pet Damage",
            tier = 2,
            price = 2500,
            position = CFrame.new(1142, 16, 1365)
        },
        ["Coins2"] = {
            type = "Upgrades_Purchase",
            zone = 40,
            zoneName = "Ski Town",
            upgradeType = "Coins",
            tier = 2,
            price = 2750,
            position = CFrame.new(688, 17, 1599)
        },
        ["EnchantVendingMachine2"] = {
            type = "VendingMachines_Purchase",
            zone = 42
        },
        ["Drops2"] = {
            type = "Upgrades_Purchase",
            zone = 44,
            zoneName = "Obsidian Cave",
            upgradeType = "Drops",
            tier = 2,
            price = 3000,
            position = CFrame.new(1181, 16, 1711)
        },
        ["Luck2"] = {
            type = "Upgrades_Purchase",
            zone = 49,
            zoneName = "Metal Dojo",
            upgradeType = "Diamonds",
            tier = 2,
            price = 4500,
            position = CFrame.new(1194, 17, 2144)
        },
        ["Luck3"] = {
            type = "Upgrades_Purchase",
            zone = 58,
            zoneName = "Fairy Castle",
            upgradeType = "Diamonds",
            tier = 3,
            price = 7500,
            position = CFrame.new(475, 17, 2626)
        },
        ["Coins Damage2"] = {
            type = "Upgrades_Purchase",
            zone = 60,
            zoneName = "Rainbow River",
            upgradeType = "Coins",
            tier = 3,
            price = 7500,
            position = CFrame.new(798, 17, 2629)
        },
        ["Diamonds5"] = {
            type = "Upgrades_Purchase",
            zone = 66,
            zoneName = "Ice Castle",
            upgradeType = "Diamonds",
            tier = 5,
            price = 12000,
            position = CFrame.new(1152, 16, 3239)
        },
        ["Drops3"] = {
            type = "Upgrades_Purchase",
            zone = 68,
            zoneName = "Firefly Cold Forest",
            upgradeType = "Diamonds",
            tier = 3,
            price = 15000,
            position = CFrame.new(825, 17, 3255)
        },
        ["Luck4"] = {
            type = "Upgrades_Purchase",
            zone = 77,
            zoneName = "Haunted Mansion",
            upgradeType = "Diamonds",
            tier = 4,
            price = 25000,
            position = CFrame.new(475, 17, 2626)
        },
        ["DailyDiamonds3"] = {
            type = "DailyRewards_Redeem",
            zone = 78
        },
        ["DailyPotions2"] = {
            type = "DailyRewards_Redeem",
            zone = 83
        },
        ["DailyEnchants2"] = {
            type = "DailyRewards_Redeem",
            zone = 88
        },
        ["DailyItems2"] = {
            type = "DailyRewards_Redeem",
            zone = 90
        },

        -- new
    
    ["Pet Damage4"] = {
        type = "Upgrades_Purchase",
        zone = "Cloud Houses",
        zoneName = "Cloud Houses",
        upgradeType = "Pet Damage",
        tier = 4,
        price = 75000,
        position = CFrame.new(-36, 123, 5394)
    },

    ["Luck1"] = {
        type = "Upgrades_Purchase",
        zone = "Shipwreck",
        zoneName = "Shipwreck",
        upgradeType = "Luck",
        tier = 1,
        price = 1000,
        position = CFrame.new(440, -28, 752)
    },

    ["Coins1"] = {
        type = "Upgrades_Purchase",
        zone = "Pirate Cove",
        zoneName = "Pirate Cove",
        upgradeType = "Coins",
        tier = 1,
        price = 1250,
        position = CFrame.new(914, 22, 1050)
    },

    ["Diamonds4"] = {
        type = "Upgrades_Purchase",
        zone = "Wild West",
        zoneName = "Wild West",
        upgradeType = "Diamonds",
        tier = 4,
        price = 2000,
        position = CFrame.new(730, 22, 1225)
    },

    ["Drops2"] = {
        type = "Upgrades_Purchase",
        zone = "Obsidian Cave",
        zoneName = "Obsidian Cave",
        upgradeType = "Drops",
        tier = 2,
        price = 3000,
        position = CFrame.new(1181, 22, 1702)
    },

    ["Diamonds6"] = {
        type = "Upgrades_Purchase",
        zone = "Colorful Clouds",
        zoneName = "Colorful Clouds",
        upgradeType = "Diamonds",
        tier = 6,
        price = 100000,
        position = CFrame.new(-36, 123, 6186)
    },

    ["Pet Speed5"] = {
        type = "Upgrades_Purchase",
        zone = "Carnival",
        zoneName = "Carnival",
        upgradeType = "Pet Speed",
        tier = 5,
        price = 60000,
        position = CFrame.new(-35, 23, 4397)
    },

    ["Coins4"] = {
        type = "Upgrades_Purchase",
        zone = "Gummy Forest",
        zoneName = "Gummy Forest",
        upgradeType = "Coins",
        tier = 4,
        price = 45000,
        position = CFrame.new(510, 23, 4320)
    },

    ["Tap Damage4"] = {
        type = "Upgrades_Purchase",
        zone = "Witch Marsh",
        zoneName = "Witch Marsh",
        upgradeType = "Tap Damage",
        tier = 4,
        price = 17500,
        position = CFrame.new(289, 23, 3634)
    },

    ["Luck4"] = {
        type = "Upgrades_Purchase",
        zone = "Haunted Mansion",
        zoneName = "Haunted Mansion",
        upgradeType = "Luck",
        tier = 4,
        price = 25000,
        position = CFrame.new(640, 23, 3711)
    },

    ["Pet Damage1"] = {
        type = "Upgrades_Purchase",
        zone = "Jungle Temple",
        zoneName = "Jungle Temple",
        upgradeType = "Pet Damage",
        tier = 1,
        price = 700,
        position = CFrame.new(467, 22, 529)
    },

    ["Tap Damage2"] = {
        type = "Upgrades_Purchase",
        zone = "Shanty Town",
        zoneName = "Shanty Town",
        upgradeType = "Tap Damage",
        tier = 2,
        price = 1500,
        position = CFrame.new(600, 22, 1050)
    },

    ["Pet Speed3"] = {
        type = "Upgrades_Purchase",
        zone = "Fairytale Castle",
        zoneName = "Fairytale Castle",
        upgradeType = "Pet Speed",
        tier = 3,
        price = 5500,
        position = CFrame.new(288, 22, 2539)
    },

    ["Pet Damage2"] = {
        type = "Upgrades_Purchase",
        zone = "Mountains",
        zoneName = "Mountains",
        upgradeType = "Pet Damage",
        tier = 2,
        price = 2500,
        position = CFrame.new(1152, 22, 1363)
    },

    ["Diamonds1"] = {
        type = "Upgrades_Purchase",
        zone = "Green Forest",
        zoneName = "Green Forest",
        upgradeType = "Diamonds",
        tier = 1,
        price = 200,
        position = CFrame.new(757, 22, -237)
    },

    ["Coins3"] = {
        type = "Upgrades_Purchase",
        zone = "Rainbow River",
        zoneName = "Rainbow River",
        upgradeType = "Coins",
        tier = 3,
        price = 7500,
        position = CFrame.new(802, 22, 2633)
    },

    ["Luck3"] = {
        type = "Upgrades_Purchase",
        zone = "Fairy Castle",
        zoneName = "Fairy Castle",
        upgradeType = "Luck",
        tier = 3,
        price = 7500,
        position = CFrame.new(483, 22, 2633)
    },

    ["Drops1"] = {
        type = "Upgrades_Purchase",
        zone = "Crimson Forest",
        zoneName = "Crimson Forest",
        upgradeType = "Drops",
        tier = 1,
        price = 650,
        position = CFrame.new(794, 22, 530)
    },

    ["Diamonds2"] = {
        type = "Upgrades_Purchase",
        zone = "Mine",
        zoneName = "Mine",
        upgradeType = "Diamonds",
        tier = 2,
        price = 400,
        position = CFrame.new(246, 22, 137)
    },

    ["Coins2"] = {
        type = "Upgrades_Purchase",
        zone = "Ski Town",
        zoneName = "Ski Town",
        upgradeType = "Coins",
        tier = 2,
        price = 2750,
        position = CFrame.new(695, 22, 1602)
    },

    ["Diamonds5"] = {
        type = "Upgrades_Purchase",
        zone = "Ice Castle",
        zoneName = "Ice Castle",
        upgradeType = "Diamonds",
        tier = 5,
        price = 12000,
        position = CFrame.new(1153, 23, 3248)
    },

    ["Tap Damage3"] = {
        type = "Upgrades_Purchase",
        zone = "Zen Garden",
        zoneName = "Zen Garden",
        upgradeType = "Tap Damage",
        tier = 3,
        price = 8000,
        position = CFrame.new(348, 22, 2151)
    },

    ["Luck2"] = {
        type = "Upgrades_Purchase",
        zone = "Metal Dojo",
        zoneName = "Metal Dojo",
        upgradeType = "Luck",
        tier = 2,
        price = 4500,
        position = CFrame.new(1191, 22, 2151)
    },

    ["Pet Damage3"] = {
        type = "Upgrades_Purchase",
        zone = "Samurai Village",
        zoneName = "Samurai Village",
        upgradeType = "Pet Damage",
        tier = 3,
        price = 7500,
        position = CFrame.new(666, 22, 2151)
    },

    ["Pet Speed1"] = {
        type = "Upgrades_Purchase",
        zone = "Dead Forest",
        zoneName = "Dead Forest",
        upgradeType = "Pet Speed",
        tier = 1,
        price = 500,
        position = CFrame.new(442, 22, 233)
    },

    ["Diamonds3"] = {
        type = "Upgrades_Purchase",
        zone = "Beach",
        zoneName = "Beach",
        upgradeType = "Diamonds",
        tier = 3,
        price = 900,
        position = CFrame.new(251, 22, 555)
    },

    ["Pet Speed2"] = {
        type = "Upgrades_Purchase",
        zone = "Fossil Digsite",
        zoneName = "Fossil Digsite",
        upgradeType = "Pet Speed",
        tier = 2,
        price = 1250,
        position = CFrame.new(389, 22, 1125)
    },

    ["Tap Damage1"] = {
        type = "Upgrades_Purchase",
        zone = "Backyard",
        zoneName = "Backyard",
        upgradeType = "Tap Damage",
        tier = 1,
        price = 300,
        position = CFrame.new(466, 22, 59)
    },

    ["Drops3"] = {
        type = "Upgrades_Purchase",
        zone = "Firefly Cold Forest",
        zoneName = "Firefly Cold Forest",
        upgradeType = "Drops",
        tier = 3,
        price = 15000,
        position = CFrame.new(823, 23, 3248)
    },

    },
    [2] = {
        ["DailyDiamonds4"] = {
            type = "DailyRewards_Redeem",
            zone = 101
        },
        ["PotionVendingMachine3"] = {
            type = "VendingMachines_Purchase",
            zone = 108
        },
        ["DailyPotions3"] = {
            type = "DailyRewards_Redeem",
            zone = 113
        },
        ["EnchantVendingMachine3"] = {
            type = "VendingMachines_Purchase",
            zone = 115
        },
        ["DailyEnchants3"] = {
            type = "DailyRewards_Redeem",
            zone = 122
        },
        ["PotionVendingMachine4"] = {
            type = "VendingMachines_Purchase",
            zone = 126
        },
        ["DailyItems3"] = {
            type = "DailyRewards_Redeem",
            zone = 130
        },
        ["DailyDiamonds5"] = {
            type = "DailyRewards_Redeem",
            zone = 135
        },
        ["EnchantVendingMachine4"] = {
            type = "VendingMachines_Purchase",
            zone = 138
        },
        ["BundleVendingMachine"] = {
            type = "VendingMachines_Purchase",
            zone = 142,
        },
        ["DailyPotions4"] = {
            type = "DailyRewards_Redeem",
            zone = 146
        },
        ["EnchantVendingMachine5"] = {
            type = "VendingMachines_Purchase",
            zone = 155
        },
        ["PotionVendingMachine5"] = {
            type = "VendingMachines_Purchase",
            zone = 165
        },
        ["DailyEnchants4"] = {
            type = "DailyRewards_Redeem",
            zone = 172
        },
        ["BundleVendingMachine2"] = {
            type = "VendingMachines_Purchase",
            zone = 180
        },
        ["DailyPotions5"] = {
            type = "DailyRewards_Redeem",
            zone = 185
        },
        ["FruitVendingMachine3"] = {
            type = "VendingMachines_Purchase",
            zone = 190
        },
        ["DailyDiamonds6"] = {
            type = "DailyRewards_Redeem",
            zone = 195
        },
    },
    [3] = {
        ["DailyEnchants5"] = {
            type = "DailyRewards_Redeem",
            zone = 202
        },
        ["DailyDiamonds7"] = {
            type = "DailyRewards_Redeem",
            zone = 205
        },
        ["DailyItems5"] = {
            type = "DailyRewards_Redeem",
            zone = 206
        },
        ["DailyItems6"] = {
            type = "DailyRewards_Redeem",
            zone = 231
        },
        ["BundleVendingMachine4"] = {
            type = "VendingMachines_Purchase",
            zone = 236
        },
    },
    [4] = {
        ["PotionVendingMachine7"] = {
            type = "VendingMachines_Purchase",
            zone = 242,
            position = Vector3.new(-15391, 16, -338)
        },
        ["DailyPotions7"] = {
            type = "DailyRewards_Redeem",
            zone = 243
        },
        ["DailyEnchants7"] = {
            type = "DailyRewards_Redeem",
            zone = 247
        },
        ["DailyDiamonds9"] = {
            type = "DailyRewards_Redeem",
            zone = 253
        },
        ["DailyItems7"] = {
            type = "DailyRewards_Redeem",
            zone = 263
        },
        ["BundleVendingMachine5"] = {
            type = "VendingMachines_Purchase",
            zone = 273
        },
    }
}

local function DoUpgrades()
    EggUpgrades()

    for name, data in pairs(FreeStuff[tonumber(DataInventory.RecentWorld)] or {}) do
        if type(data.zone) == "string" then
            local zoneId, zoneData = ZoneUtils.GetZoneFromId(data.zoneName)
            data.zone = zoneData and zoneData.ZoneNumber or math.huge
        end

        if zoneData.ZoneNumber >= data.zone then

            -- DAILY REWARDS
            if data.type == "DailyRewards_Redeem" then
                local timestamps = DataInventory.TimedRewardTimestamps or {}
                local cooldown = Directory.TimedRewards[name] and Directory.TimedRewards[name].Cooldown or 0
                local nextClaim = (timestamps[name] or 0) + cooldown

                if nextClaim <= workspace:GetServerTimeNow() then
                    StatusUpdate("Auto-rank: daily reward ready " .. tostring(name))
                    StatusUpdate("Claiming Daily reward: " .. tostring(name))

                    if data.position then
                        TeleportPlayer(data.position)
                    else
                        TeleportToArea(data.zone)
                    end

                    task.wait(0.1)

                    Network.Fire("Machines: Mark Approached", name)

                    local success, err

                    for attempt = 1, 15 do
                        success, err = Network.Invoke("DailyRewards_Redeem", name)

                        if success then
                            break
                        end

                        task.wait(0.1)
                    end

                    if success then
                        StatusUpdate("Claimed Daily reward: " .. tostring(name))

                        local timestampsCopy = {}

                        for k, v in pairs(DataInventory.TimedRewardTimestamps or {}) do
                            timestampsCopy[k] = v
                        end

                        timestampsCopy[name] = workspace:GetServerTimeNow()

                        UpdatePlayerData("TimedRewardTimestamps", timestampsCopy)
                    else
                        StatusUpdate(
                            "Failed Daily reward: "
                                .. tostring(name)
                                .. " Error: "
                                .. tostring(err)
                        )
                    end
                end

                continue
            end

            if data.type == "VendingMachines_Purchase" then
                local stocks = DataInventory.VendingStocks or {}
                local currentStock = stocks[name] or 4
                if currentStock <= 0 then
                    continue
                end

                if data.position then
                    TeleportPlayer(data.position)
                else
                    TeleportToArea(data.zone)
                end
                task.wait(0.2)

                Network.Fire("Machines: Mark Approached", name)

                local machineData = Directory.VendingMachines[name]

                if not machineData then
                    continue
                end

                repeat
                    stocks = DataInventory.VendingStocks or {}
                    currentStock = stocks[name] or 4

                    if currentStock <= 0 then
                        break
                    end

                    StatusUpdate("Auto-rank: vending machine purchase attempt " .. tostring(name) .. " stock=" .. tostring(currentStock))


                    local amount = 1
                    local price = machineData.CurrencyCost
                    local currentCoins = GetItem(
                        "Currency",
                        machineData.CurrencyType,
                        false
                    )

                    if currentCoins < price then
                        break
                    end

                    StatusUpdate(
                        "Buying Vending machine: "
                            .. tostring(name)
                            .. " | Stock: "
                            .. tostring(currentStock)
                            .. " | Buying: "
                            .. tostring(amount)
                    )

                    local success, err = Network.Invoke(
                        "VendingMachines_Purchase",
                        name,
                        amount
                    )

                    if success then
                        local stocksCopy = {}

                        for k, v in pairs(stocks) do
                            stocksCopy[k] = v
                        end

                        stocksCopy[name] = math.max(currentStock - amount, 0)

                        UpdatePlayerData("VendingStocks", stocksCopy)

                        StatusUpdate(
                            "Bought Vending machine: "
                                .. tostring(name)
                                .. " | Stock: "
                                .. tostring(stocksCopy[name])
                        )
                    else
                        StatusUpdate(
                            "Failed purchase Vending machine: "
                                .. tostring(name)
                                .. " Error: "
                                .. tostring(err)
                        )

                        break
                    end

                    task.wait(0.25)

                until false

                continue
            end

            if data.type == "Upgrades_Purchase" then
                local UpgradesOwned = DataInventory.UpgradesOwned or {}
                local UpgradeOwnedList = UpgradesOwned[data.upgradeType] or {}
                local hasTier = false

                for _, idk in pairs(UpgradeOwnedList) do
                    if tonumber(idk) == tonumber(data.tier) then
                        hasTier = true
                    end
                end

                if not hasTier then
                    local diamonds = GetItem("Currency", "Diamonds", false)

                    if Config["MaxUpgradeCost"] then
                        if Config["MaxUpgradeCost"] < data.price then
                            continue
                        end
                    end

                    if diamonds > data.price then
                        StatusUpdate("Auto-rank: upgrade ready " .. tostring(name) .. " cost=" .. tostring(data.price) .. " diamonds=" .. tostring(diamonds))
                        local success, err = nil, nil

                        repeat
                            StatusUpdate(
                                "Buying Upgrade: " ..
                                name .. " [" ..
                                utils:FormatNumber(diamonds) ..
                                "/" ..
                                utils:FormatNumber(data.price) ..
                                "]"
                            )

                            TeleportPlayer(data.position)

                            success, err = Network.Invoke(
                                "Upgrades_Purchase",
                                data.upgradeType,
                                data.zoneName
                            )

                            if success then
                                StatusUpdate("Purchased Upgrade: " .. tostring(name))

                                local upgradesCopy = {}

                                for k, v in pairs(DataInventory.UpgradesOwned or {}) do
                                    upgradesCopy[k] = v
                                end

                                local listCopy = {}

                                for _, v in pairs(upgradesCopy[data.upgradeType] or {}) do
                                    table.insert(listCopy, v)
                                end

                                if not table.find(listCopy, data.tier) then
                                    table.insert(listCopy, data.tier)
                                end

                                upgradesCopy[data.upgradeType] = listCopy

                                UpdatePlayerData("UpgradesOwned", upgradesCopy)
                            end

                            UpgradesOwned = DataInventory.UpgradesOwned or {}
                            UpgradeOwnedList = UpgradesOwned[data.upgradeType] or {}

                            task.wait(0.05)

                            for _, idk in pairs(UpgradeOwnedList) do
                                if tonumber(idk) == tonumber(data.tier) then
                                    hasTier = true
                                end
                            end

                        until hasTier
                        task.wait(1)
                    end
                end
            end
        end
    end
end

if Config["Rank Before"] then
if CurrentAreaNumber() < 11 then
    StatusUpdate("Auto-rank: preparing area progression to 11, current area " .. tostring(CurrentAreaNumber()))
    repeat
        Name,zoneData = GetMaxOwnedZone()
        NextName, nextData = GetNextZone()
        TeleportToBestArea()
        task.wait(0.1)

        local coins = tonumber(GetItem("Currency", WorldsUtil.GetWorldCurrencyId())) or 0
        local price = nextData and (tonumber(CalcGatePrice(nextData)) or math.huge) or math.huge
        
        if coins > price then
            StatusUpdate("Buying Zone " .. tostring(NextName))
            local success, err = TryPurchaseNextZone(NextName, nextData)
            if success then
                StatusUpdate("Purchased Zone " .. tostring(NextName))
            end
        else
            StatusUpdate("Earning Coins for " .. tostring(NextName) .. " " .. utils:FormatNumber(coins) .. "/" .. utils:FormatNumber(price))
        end
        DoUpgrades()
        PurchaseBestEgg()
    until CurrentAreaNumber() >= 11
end

if CurrentRankNumber() < 3 then
    StatusUpdate("Auto-rank: preparing rank progression to 3, current rank " .. tostring(CurrentRankNumber()))
    TeleportToBestArea()
    repeat
        DoEasyQuest()
        DoQuest()
        DoUpgrades()
        task.wait(0.1)
        PurchaseBestEgg()
        StatusUpdate("Auto-rank: preparing rank progression to 3, current rank " .. tostring(CurrentRankNumber()))
    until CurrentRankNumber() >= 3
end

if (DataInventory.Rebirths or 0) < 1 and CurrentAreaNumber() < 25 then
    StatusUpdate("Auto-rank: area progress toward 25 before rebirth 1, current area " .. tostring(CurrentAreaNumber()))
    repeat
        task.wait(0.25)
        Name,zoneData = GetMaxOwnedZone()
        NextName, nextData = GetNextZone()

        TeleportToBestArea()

        local coins = tonumber(GetItem("Currency", WorldsUtil.GetWorldCurrencyId())) or 0
        local price = nextData and (tonumber(CalcGatePrice(nextData)) or math.huge) or math.huge
        
        if coins > price then
            StatusUpdate("Buying Zone " .. tostring(NextName))
            local success, err = TryPurchaseNextZone(NextName, nextData)
            if success then
                StatusUpdate("Purchased Zone " .. tostring(NextName))
            end
        else
            StatusUpdate("Earning Coins for " .. tostring(NextName) .. " " .. utils:FormatNumber(coins) .. "/" .. utils:FormatNumber(price))
        end
        DoQuest()
        PurchaseBestEgg()
        DoUpgrades()
    until CurrentAreaNumber() >= 25

    repeat
        Network.Invoke("Rebirth_Request","1")
        task.wait(0.5)
    until (DataInventory.Rebirths or 0) >= 1
end

if CurrentRankNumber() < 5 then
    StatusUpdate("Auto-rank: progressing rank to 5, current rank " .. tostring(CurrentRankNumber()))
    TeleportToBestArea()
    repeat
        DoEasyQuest()
        DoQuest()
        DoUpgrades()
        PurchaseBestEgg()
        task.wait(0.1)
        StatusUpdate("Auto-rank: progressing rank to 5, current rank " .. tostring(CurrentRankNumber()))
    until CurrentRankNumber() >= 5
end

if (DataInventory.Rebirths or 0) < 2 and CurrentAreaNumber() < 50 then
    StatusUpdate("Auto-rank: area progress toward 50 before rebirth 2, current area " .. tostring(CurrentAreaNumber()))
    repeat
        task.wait(0.25)
        Name,zoneData = GetMaxOwnedZone()
        NextName, nextData = GetNextZone()

        TeleportToBestArea()

        local coins = tonumber(GetItem("Currency", WorldsUtil.GetWorldCurrencyId())) or 0
        local price = nextData and (tonumber(CalcGatePrice(nextData)) or math.huge) or math.huge
        
        if coins > price then
            StatusUpdate("Buying Zone " .. tostring(NextName))
            local success, err = TryPurchaseNextZone(NextName, nextData)
            if success then
                StatusUpdate("Purchased Zone " .. tostring(NextName))
            end
        else
            StatusUpdate("Earning Coins for " .. tostring(NextName) .. " " .. utils:FormatNumber(coins) .. "/" .. utils:FormatNumber(price))
        end
        DoQuest()
        PurchaseBestEgg()
        DoUpgrades()
    until CurrentAreaNumber() >= 50

    repeat
        Network.Invoke("Rebirth_Request","2")
        task.wait(0.5)
    until (DataInventory.Rebirths or 0) >= 2
end

if (DataInventory.Rebirths or 0) < 3 and CurrentAreaNumber() < 75 then
    StatusUpdate("Auto-rank: area progress toward 75 before rebirth 3, current area " .. tostring(CurrentAreaNumber()))
    repeat
        task.wait(0.25)
        Name,zoneData = GetMaxOwnedZone()
        NextName, nextData = GetNextZone()

        TeleportToBestArea()

        local coins = tonumber(GetItem("Currency", WorldsUtil.GetWorldCurrencyId())) or 0
        local price = nextData and (tonumber(CalcGatePrice(nextData)) or math.huge) or math.huge
        
        if coins > price then
            StatusUpdate("Buying Zone " .. tostring(NextName))
            local success, err = TryPurchaseNextZone(NextName, nextData)
            if success then
                StatusUpdate("Purchased Zone " .. tostring(NextName))
            end
        else
            StatusUpdate("Earning Coins for " .. tostring(NextName) .. " " .. utils:FormatNumber(coins) .. "/" .. utils:FormatNumber(price))
        end
        DoQuest()
        PurchaseBestEgg()
        DoUpgrades()
    until CurrentAreaNumber() >= 75

    repeat
        Network.Invoke("Rebirth_Request","3")
        task.wait(0.5)
    until (DataInventory.Rebirths or 0) >= 3
end

if CurrentAreaNumber() < 90 then
    StatusUpdate("Auto-rank: area progression toward 90, current area " .. tostring(CurrentAreaNumber()))
    repeat
        task.wait(0.25)
        Name,zoneData = GetMaxOwnedZone()
        NextName, nextData = GetNextZone()

        TeleportToBestArea()

        local coins = tonumber(GetItem("Currency", WorldsUtil.GetWorldCurrencyId())) or 0
        local price = nextData and (tonumber(CalcGatePrice(nextData)) or math.huge) or math.huge
        
        if coins > price then
            StatusUpdate("Buying Zone " .. tostring(NextName))
            local success, err = TryPurchaseNextZone(NextName, nextData)
            if success then
                StatusUpdate("Purchased Zone " .. tostring(NextName))
            end
        else
            StatusUpdate("Earning Coins for " .. tostring(NextName) .. " " .. utils:FormatNumber(coins) .. "/" .. utils:FormatNumber(price))
        end
        DoQuest()
        PurchaseBestEgg()
        DoUpgrades()
    until CurrentAreaNumber() >= 90
end

if CurrentRankNumber() < 8 then
    StatusUpdate("Auto-rank: progressing rank to 8, current rank " .. tostring(CurrentRankNumber()))
    TeleportToBestArea()
    StatusUpdate("Auto-rank: starting rank 8 grind")
    repeat
        DoEasyQuest()
        DoQuest()
        DoUpgrades()
        PurchaseBestEgg()
        task.wait(0.1)
        StatusUpdate("Auto-rank: progressing rank to 8, current rank " .. tostring(CurrentRankNumber()))
    until CurrentRankNumber() >= 8
end

if (DataInventory.Rebirths or 0) < 4 and CurrentAreaNumber() < 99 then
    StatusUpdate("Auto-rank: area progress toward 99 before rebirth 4, current area " .. tostring(CurrentAreaNumber()))
    repeat
        task.wait(0.25)
        Name,zoneData = GetMaxOwnedZone()
        NextName, nextData = GetNextZone()

        TeleportToBestArea()

        local coins = tonumber(GetItem("Currency", WorldsUtil.GetWorldCurrencyId())) or 0
        local price = nextData and (tonumber(CalcGatePrice(nextData)) or math.huge) or math.huge
        
        if coins > price then
            StatusUpdate("Buying Zone " .. tostring(NextName))
            local success, err = TryPurchaseNextZone(NextName, nextData)
            if success then
                StatusUpdate("Purchased Zone " .. tostring(NextName))
            end
        else
            StatusUpdate("Earning Coins for " .. tostring(NextName) .. " " .. utils:FormatNumber(coins) .. "/" .. utils:FormatNumber(price))
        end
        DoQuest()
        PurchaseBestEgg()
        DoUpgrades()
    until CurrentAreaNumber() >= 99 or NextName == nil

    repeat
        Network.Invoke("Rebirth_Request","4")
        task.wait(0.5)
    until (DataInventory.Rebirths or 0) >= 4
    task.wait(30)
end
end
-- hier auto rankl ende

if InstancingCmds.instanceId ~= "TapHeroes" or not InstancingCmds.instanceObj then
    repeat
        Network.Invoke("Instancing_PlayerEnterInstance", "TapHeroes")
        Network.Fire("Instances: Mark Entered", "TapHeroes")
        TeleportPlayer(Vector3.new(-4694, 1611, -1595))
        task.wait(0.05)
    until InstancingCmds.instanceId == "TapHeroes" and InstancingCmds.instanceObj
end

local LastBossChange = 0
local LastBossTimer = 0
local LastLevel = DataInventory.TapHeroes.MaxZone or 1
local BossLevel = LastLevel
local OldMax = DataInventory.TapHeroes.MaxZone or 1

local BossActive = false
local BossDespawnTime = 0

-- Transcend sayaci: state paketinin [13]. arg'indan DOGRUDAN okunur.
-- Bilerek DataInventory'ye guvenmiyoruz (UpdatePlayerData bilinmeyen anahtari
-- kaydetmeyebiliyor -> nil okunup dongu hic durmuyordu).
local CurrentTranscends = 0

Network.Fired("Instancing_FireCustomFromServer"):Connect(function(
    instanceID,
    action,
    CurrentLevel,
    Rebirths,
    CurrentKills,
    OutOfTen,
    BossTimerSeconds,
    MaxLevel,
    idk,
    KillsRequired,
    canRebirth,
    unused12,
    Transcends,
    unused14
)
    if instanceID ~= "TapHeroes" then
        return
    end

    if action == "TapHeroes_State" then
        if BossTimerSeconds > 0 and LastBossTimer == 0 then
            BossActive = true
            LastLevel = CurrentLevel
            LastBossChange = os.clock()
            BossDespawnTime = os.clock() + BossTimerSeconds
        end
        if BossActive and BossTimerSeconds == 0 then
            if os.clock() < BossDespawnTime then
                BossActive = false
            end
        end
        LastBossTimer = BossTimerSeconds

        local copy = table.clone(DataInventory.TapHeroes)
        setreadonly(copy, false)

        copy.MaxZone = MaxLevel
        copy.CurrentZone = CurrentLevel
        copy.Rebirths = Rebirths
        copy.Transcends = Transcends
        if type(Transcends) == "number" then
            if Transcends ~= CurrentTranscends then
                print("[TRANSCEND] " .. tostring(CurrentTranscends) .. " -> " .. tostring(Transcends)
                    .. " | hedef: " .. tostring(Config["Max Rebirths"] or 0))
            end
            CurrentTranscends = Transcends
        end
        if canRebirth then
            print("you can now rebirth")
            copy.canRebirth = canRebirth
        end
        UpdatePlayerData("TapHeroes",copy)
        print(copy.MaxZone,copy.CurrentZone,copy.Rebirths,copy.canRebirth,canRebirth)

        RebirthsStat:Update(tostring(Rebirths or 0))
        TranscendStat:Update(tostring(Transcends or 0))
        LevelStat:Update(tostring(CurrentLevel or 0) .. "/" .. tostring(MaxLevel or 0))
        StageProgressStat:Update(tostring(OutOfTen or 0) .. "/" .. tostring(KillsRequired or 0))
    end
end)


Network.Invoke("Instancing_InvokeCustomFromClient","TapHeroes",MoveRemote)
Network.Invoke("AutoTapper_Toggle")
task.wait(1)
Network.Invoke("Instancing_InvokeCustomFromClient","TapHeroes",MoveRemote)

SetLevel()
TeleportPlayer(Vector3.new(59988, 1007, 60601))


-- === TRANSCEND KILIDI + IZLEYICI ===
-- Hedefe ulasildiysa TranscendRemote giden HER istegi bloklar (kim cagirirsa cagirsin),
-- ayrica cagrildigi her seferde kimin cagirdigini (traceback) yazar.
-- Eger transcend olurken hicbir [TX-*] logu cikmiyorsa -> tetikleyen client degil,
-- sunucu tarafi otomatik (o zaman Max Area'yi dusurmek gerekir).
do
    pcall(function() if setreadonly then setreadonly(Network, false) end end)

    local function hasTranscendArg(...)
        for i = 1, select("#", ...) do
            if (select(i, ...)) == TranscendRemote then return true end
        end
        return false
    end

    local function wrap(name)
        local orig = Network[name]
        if type(orig) ~= "function" then return end
        pcall(function()
            Network[name] = function(...)
                if hasTranscendArg(...) then
                    print("[TX-" .. name .. "] cagrildi | transcend=" .. tostring(CurrentTranscends)
                        .. " hedef=" .. tostring(Config["Max Rebirths"] or 0))
                    print(debug.traceback())
                    if (CurrentTranscends or 0) >= (Config["Max Rebirths"] or 0) then
                        print("[TX-" .. name .. "] >>> BLOKLANDI <<<")
                        return
                    end
                end
                return orig(...)
            end
        end)
    end

    wrap("Fire")
    wrap("Invoke")
end

if (CurrentTranscends or 0) < (Config["Max Rebirths"] or 0) then
    while (CurrentTranscends or 0) < (Config["Max Rebirths"] or 0) do

        repeat
            SetLevel(DataInventory.TapHeroes.MaxZone or 1)
            local currentZone = DataInventory.TapHeroes.CurrentZone or 1
            if currentZone % 5 == 0 then
                
                local LastHealth = nil
                local LastTime = os.clock()
                local CurrentDPS = 0

                local BossDespawnTime2 = BossDespawnTime 
                while BossActive and os.clock() < BossDespawnTime2 do
                    HatchNearest()
                    SetLevel(DataInventory.TapHeroes.MaxZone or 1)
                    task.wait()
                
                    local data_source = instanceBreakables[InstancingCmds.instanceId] or {}
                    for _, breakdata in pairs(data_source) do
                        local pos = breakdata.Position or breakdata.position or breakdata.pos
                    
                        if pos then
                            local dist = (HumanoidRootPartPosition - pos).Magnitude
                            if dist <= 100 then
                                local health = breakdata.health or 0
                                local maxHealth = breakdata.maxHealth or health
                            
                                if LastHealth and health < LastHealth then
                                    local deltaHealth = LastHealth - health
                                    local deltaTime = os.clock() - LastTime
                                    if deltaTime > 0 then
                                        CurrentDPS = deltaHealth / deltaTime
                                    end
                                end
                            
                                LastHealth = health
                                LastTime = os.clock()
                            
                                local timeLeft = BossDespawnTime2 - os.clock()
                                local timeNeeded = CurrentDPS > 0 and (health / CurrentDPS) or math.huge
                                local canKill = timeNeeded <= timeLeft
                            
                                StatusUpdate(
                                    "Boss Chest: " .. utils:FormatNumber(health) .. "/" .. utils:FormatNumber(maxHealth) ..
                                    " | DPS: " .. utils:FormatNumber(CurrentDPS) ..
                                    " | Need: " .. (timeNeeded == math.huge and "∞" or math.floor(timeNeeded) .. "s") ..
                                    " | " .. (canKill and "CAN DESTROY" or "TOO SLOW")
                                )
                            end
                        end
                    end
                end

                if os.clock() >= BossDespawnTime2 then
                    BossActive = false
                    
                    local maxZone = DataInventory.TapHeroes.MaxZone or 10

                    Network.Invoke("Instancing_InvokeCustomFromClient", "TapHeroes", SetLevelRemote, math.max(1, maxZone - 5))
                    local StartTimer = os.clock()

                    repeat
                        task.wait(0.1)
                        HatchNearest()
                    
                        local remaining = math.max(0, 30 - math.floor(os.clock() - StartTimer))
                        StatusUpdate("Failed Defeating the boss retrying in: " .. remaining .. "s")
                    until os.clock() - StartTimer > 30

                    SetLevel(DataInventory.TapHeroes.MaxZone or 1)
                else
                    SetLevel(DataInventory.TapHeroes.MaxZone or 1)
                end
            end
            
            task.wait(0.1)
            HatchNearest()
            
            if (DataInventory.TapHeroes.MaxZone or 1) >= 120 then
                print(tostring(DataInventory.TapHeroes.canRebirth))
            end
        until ((DataInventory.TapHeroes.MaxZone or 1) >= 120 and DataInventory.TapHeroes.canRebirth)
            or (CurrentTranscends or 0) >= (Config["Max Rebirths"] or 0)

        -- Hedefe grind sirasinda ulastiysak hic ateslemeden cik
        if (CurrentTranscends or 0) >= (Config["Max Rebirths"] or 0) then
            break
        end

        local TargetRebirth = (DataInventory.TapHeroes.Rebirths or 0) + 1
        StatusUpdate("Transcend/Rebirth aksiyonu -> hedef rebirth: " .. tostring(TargetRebirth)
            .. " | Transcend: " .. tostring(CurrentTranscends or 0)
            .. "/" .. tostring(Config["Max Rebirths"] or 0))
        repeat
            -- Hedefe ulastiysak fazladan atma
            if (CurrentTranscends or 0) >= (Config["Max Rebirths"] or 0) then
                break
            end
            -- Eski rebirth stilinde direkt remote (dump'ta TX_Post olarak tespit edildi).
            Network.Fire("Instancing_FireCustomFromClient","TapHeroes",TranscendRemote)
            task.wait(0.5)
        until (DataInventory.TapHeroes.Rebirths or 0) >= TargetRebirth
    end
end

print(DataInventory.TapHeroes.MaxZone or 1,Config["Max Area"])
if (DataInventory.TapHeroes.MaxZone or 1) <  (Config["Max Area"] or 0) then
    while (DataInventory.TapHeroes.MaxZone or 1) <  (Config["Max Area"] or 0) do
        SetLevel(DataInventory.TapHeroes.MaxZone or 1, false)
        local currentZone = DataInventory.TapHeroes.CurrentZone or 1
        if currentZone % 5 == 0 then
            local LastHealth = nil
            local LastTime = os.clock()
            local CurrentDPS = 0

            local BossDespawnTime2 = BossDespawnTime 
            while BossActive and os.clock() < BossDespawnTime2 do
                HatchNearest()
                task.wait()
                SetLevel(DataInventory.TapHeroes.MaxZone or 1)
                local data_source = instanceBreakables[InstancingCmds.instanceId] or {}
                for _, breakdata in pairs(data_source) do
                    local pos = breakdata.Position or breakdata.position or breakdata.pos
                
                    if pos then
                        local dist = (HumanoidRootPartPosition - pos).Magnitude
                        if dist <= 100 then
                            local health = breakdata.health or 0
                            local maxHealth = breakdata.maxHealth or health
                        
                            if LastHealth and health < LastHealth then
                                local deltaHealth = LastHealth - health
                                local deltaTime = os.clock() - LastTime
                                if deltaTime > 0 then
                                    CurrentDPS = deltaHealth / deltaTime
                                end
                            end
                        
                            LastHealth = health
                            LastTime = os.clock()
                        
                            local timeLeft = BossDespawnTime2 - os.clock()
                            local timeNeeded = CurrentDPS > 0 and (health / CurrentDPS) or math.huge
                            local canKill = timeNeeded <= timeLeft
                        
                            StatusUpdate(
                                "Boss Chest: " .. utils:FormatNumber(health) .. "/" .. utils:FormatNumber(maxHealth) ..
                                " | DPS: " .. utils:FormatNumber(CurrentDPS) ..
                                " | Need: " .. (timeNeeded == math.huge and "∞" or math.floor(timeNeeded) .. "s") ..
                                " | " .. (canKill and "CAN DESTROY" or "TOO SLOW")
                            )
                        end
                    end
                end
            end
                
            if os.clock() >= BossDespawnTime2 then
                BossActive = false
                
                local maxZone = DataInventory.TapHeroes.MaxZone or 10
                Network.Invoke("Instancing_InvokeCustomFromClient", "TapHeroes", SetLevelRemote, math.max(1, maxZone - 5))
                local StartTimer = os.clock()
                repeat
                    task.wait(0.1)
                    HatchNearest()
                
                    local remaining = math.max(0, 30 - math.floor(os.clock() - StartTimer))
                    StatusUpdate("Failed Defeating the boss retrying in: " .. remaining .. "s")
                until os.clock() - StartTimer > 30

                SetLevel(DataInventory.TapHeroes.MaxZone or 1, false)
            else
                SetLevel(DataInventory.TapHeroes.MaxZone or 1, false)
            end
        end
        
        task.wait(0.1)
        HatchNearest()
    end
end

StatusUpdate("Reached Target")

if Config["FarmChests"] then
    while task.wait(0.1) do
        HatchNearest()
        for i,level in ipairs(Config["FarmChests"]) do
            SetLevel(level)
            task.wait(0.1)
        end
    end
end

while task.wait(0.1) do
    HatchNearest()
    local currentZone = DataInventory.TapHeroes.CurrentZone or 1
    if currentZone % 5 == 0 then
        local LastHealth = nil
        local LastTime = os.clock()
        local CurrentDPS = 0

        local BossDespawnTime2 = BossDespawnTime 
        while BossActive and os.clock() < BossDespawnTime2 do
            HatchNearest()
            task.wait()
        
            local data_source = instanceBreakables[InstancingCmds.instanceId] or {}
            for _, breakdata in pairs(data_source) do
                local pos = breakdata.Position or breakdata.position or breakdata.pos
            
                if pos then
                    local dist = (HumanoidRootPartPosition - pos).Magnitude
                    if dist <= 100 then
                        local health = breakdata.health or 0
                        local maxHealth = breakdata.maxHealth or health
                    
                        if LastHealth and health < LastHealth then
                            local deltaHealth = LastHealth - health
                            local deltaTime = os.clock() - LastTime
                            if deltaTime > 0 then
                                CurrentDPS = deltaHealth / deltaTime
                            end
                        end
                    
                        LastHealth = health
                        LastTime = os.clock()
                    
                        local timeLeft = BossDespawnTime - os.clock()
                        local timeNeeded = CurrentDPS > 0 and (health / CurrentDPS) or math.huge
                        local canKill = timeNeeded <= timeLeft
                    
                        StatusUpdate("Boss Chest: " .. utils:FormatNumber(health) .. "/" .. utils:FormatNumber(maxHealth))
                    end
                end
            end
        end
            
        if os.clock() >= BossDespawnTime2 then
            BossActive = false
            
            local maxZone = currentZone or 10
            Network.Invoke("Instancing_InvokeCustomFromClient", "TapHeroes", SetLevelRemote, math.max(1, maxZone - 5))
            local StartTimer = os.clock()
            repeat
                task.wait(0.1)
                HatchNearest()
            
                local remaining = math.max(0, 30 - math.floor(os.clock() - StartTimer))
                StatusUpdate("Failed Defeating the boss retrying in: " .. remaining .. "s")
            until os.clock() - StartTimer > 30
            SetLevel(currentZone or 1, false)
        else
            SetLevel(currentZone or 1, false)
        end
    end
    SetLevel(Config["Max Area"])
    StatusUpdate("Reached Target Hatching now")
end
