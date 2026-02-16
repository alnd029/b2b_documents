local ox_inventory = exports.ox_inventory
local ESX, QBCore, Qbox = nil, nil, nil

MySQL.ready(function()
    local sqlQuery = [[
        CREATE TABLE IF NOT EXISTS `b2b_documents` (
            `id` varchar(50) NOT NULL,
            `content` longtext DEFAULT NULL,
            `title` varchar(100) DEFAULT 'Document',
            `locked` tinyint(1) DEFAULT 0,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
    
    MySQL.query(sqlQuery, {}, function(success)
    end)
end)

CreateThread(function()
    if Config.Framework == "auto" then
        if GetResourceState('es_extended') == 'started' then
            Config.Framework = 'esx'
        elseif GetResourceState('qb-core') == 'started' then
            Config.Framework = 'qbcore'
        elseif GetResourceState('qbx_core') == 'started' then
            Config.Framework = 'qbox'
        end
    end

    if Config.Framework == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
    elseif Config.Framework == 'qbcore' then
        QBCore = exports['qb-core']:GetCoreObject()
        elseif Config.Framework == 'qbox' then
        Qbox = true
    end
end)

RegisterNetEvent('b2b_documents:server:requestPaper', function()
    local src = source

    if ox_inventory:CanCarryItem(src, 'paper_blank', 1) then
        ox_inventory:AddItem(src, 'paper_blank', 1)
        
        if Config.Framework == 'esx' and ESX then
            TriggerClientEvent('esx:showNotification', src, "Vous avez pris une feuille vierge.")
        elseif Config.Framework == 'qbcore' and QBCore then
            TriggerClientEvent('QBCore:Notify', src, "Vous avez pris une feuille vierge.", "success")
        elseif Config.Framework == 'qbox' then
            exports.ox_lib:notify(src, { title = 'Succès', description = 'Vous avez pris une feuille vierge.', type = 'success' })
        end
    else
        if Config.Framework == 'esx' and ESX then
            TriggerClientEvent('esx:showNotification', src, "Vos poches sont pleines.")
        elseif Config.Framework == 'qbcore' and QBCore then
            TriggerClientEvent('QBCore:Notify', src, "Vos poches sont pleines.", "error")
        elseif Config.Framework == 'qbox' then
            exports.ox_lib:notify(src, { title = 'Erreur', description = 'Vos poches sont pleines.', type = 'error' })
        end
    end
end)

lib.callback.register('b2b_documents:handleAction', function(source, data, slot)
    local slotNum = tonumber(slot)
    local item = ox_inventory:GetSlot(source, slotNum)
    
    if not item then
        local items = ox_inventory:GetInventoryItems(source)
        for _, v in pairs(items) do
            if v.name == 'paper_blank' or v.name == 'document' then
                item = v
                slotNum = v.slot
                break
            end
        end
    end

    if not item then return false end
    local metadata = item.metadata or {}

    if not metadata.docId or metadata.docId == "nil" then
        metadata.docId = "DOC_" .. os.time() .. "_" .. math.random(100, 999)
    end

    if data.action == 'save' or data.action == 'lock' then
        local p = promise.new()
        local shouldLock = (data.action == 'lock' or metadata.locked)

        exports.oxmysql:insert('INSERT INTO b2b_documents (id, content, title, locked) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE content = VALUES(content), title = VALUES(title), locked = VALUES(locked)', 
        {metadata.docId, data.content, data.title or "Document", shouldLock and 1 or 0}, 
        function(id)
            p:resolve(true)
        end)

        local success = Citizen.Await(p)

        if success then
            metadata.title = data.title 
            metadata.locked = shouldLock 
            metadata.label = data.title 
            metadata.description = shouldLock and "Signé / Verrouillé" or "Document Éditable"
            
            ox_inventory:RemoveItem(source, item.name, 1, nil, slotNum)
            ox_inventory:AddItem(source, 'document', 1, metadata, slotNum)
            return true, metadata.docId
        end

    elseif data.action == 'duplicate' then
        local newDocId = "DOC_" .. os.time() .. "_" .. math.random(100, 999)
        local p = promise.new()

        exports.oxmysql:insert('INSERT INTO b2b_documents (id, content, title, locked) VALUES (?, ?, ?, ?)', 
        {newDocId, data.content, (data.title or "Document") .. " (Copie)", 0}, 
        function(id)
            p:resolve(true)
        end)

        if Citizen.Await(p) then
            local newMetadata = {
                docId = newDocId,
                title = (data.title or "Document") .. " (Copie)",
                label = (data.title or "Document") .. " (Copie)",
                description = "Copie de document",
                locked = false
            }
            ox_inventory:AddItem(source, 'document', 1, newMetadata)
            
            return true, newDocId
        end
    end

    return true
end)

lib.callback.register('b2b_documents:getContent', function(source, docId)
    if not docId or docId == "nil" or docId == "" then return "" end
    
    local p = promise.new()
    exports.oxmysql:query('SELECT content FROM b2b_documents WHERE id = ? LIMIT 1', {docId}, function(result)
        if result and result[1] then
            p:resolve(result[1].content)
        else
            p:resolve("")
        end
    end)

    return Citizen.Await(p)
end)

lib.callback.register('b2b_documents:getFreshMetadata', function(source, slot)
    local item = ox_inventory:GetSlot(source, slot)
    if item and item.metadata then
        return item.metadata
    end
    return {}
end)
