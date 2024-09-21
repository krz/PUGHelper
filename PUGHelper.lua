-- Create a frame to register events
local frame = CreateFrame("Frame")

-- Register for the event when the player's target changes
frame:RegisterEvent("PLAYER_TARGET_CHANGED")

-- Create a table that maps NPC IDs to specific messages
local npcMessages = {
   [222619] = "This is NPC 222619, proceed with caution!", -- Message for NPC ID 222619
   [222618]  = "NPC 12345 detected! Watch out for special abilities.", -- Message for NPC ID 12345
   [67890]  = "NPC 67890 is friendly, no need to attack.", -- Message for NPC ID 67890
}

-- Default message if the NPC ID is not in the table
local defaultMessage = "You have targeted an unknown NPC."

-- Create a function to display the small editable text box with buttons
local function ShowEditableTextBox(defaultText)
   -- Create a new frame for the text box
   local editFrame = CreateFrame("Frame", "TargetNotifierEditFrame", UIParent, "BasicFrameTemplateWithInset")
   editFrame:SetSize(300, 240) -- Width, Height (increased height for two buttons)
   editFrame:SetPoint("CENTER", UIParent, "CENTER") -- Position in the center of the screen
   
   -- Add a title to the frame
   editFrame.title = editFrame:CreateFontString(nil, "OVERLAY")
   editFrame.title:SetFontObject("GameFontHighlight")
   editFrame.title:SetPoint("TOP", editFrame, "TOP", 0, -10)
   editFrame.title:SetText("Editable Text Box")
   
   -- Create the scrolling edit box inside the frame
   local scrollFrame = CreateFrame("ScrollFrame", nil, editFrame, "UIPanelScrollFrameTemplate")
   scrollFrame:SetSize(260, 100)
   scrollFrame:SetPoint("TOP", editFrame, "TOP", 0, -40)
   
   -- Create the actual editable text box (EditBox) inside the scroll frame
   local editBox = CreateFrame("EditBox", nil, scrollFrame)
   editBox:SetMultiLine(true)
   editBox:SetFontObject("ChatFontNormal")
   editBox:SetWidth(260)
   editBox:SetHeight(100)
   editBox:SetAutoFocus(false) -- Don't automatically focus when shown
   editBox:SetText(defaultText or "Enter your text here...") -- Default text
   editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end) -- Allow ESC to unfocus the box
   
   -- Attach the edit box to the scroll frame
   scrollFrame:SetScrollChild(editBox)
   
   -- Allow the user to copy and paste text (Highlight all text with CTRL+A, and use CTRL+C to copy)
   editBox:EnableMouse(true)
   
   -- Create a button to post the content to the /say chat
   local postSayButton = CreateFrame("Button", nil, editFrame, "GameMenuButtonTemplate")
   postSayButton:SetSize(120, 30) -- Button size (Width, Height)
   postSayButton:SetPoint("BOTTOM", editFrame, "BOTTOM", 0, 50) -- Position above the second button
   postSayButton:SetText("Post to /say") -- Button text
   postSayButton:SetNormalFontObject("GameFontNormalLarge")
   postSayButton:SetHighlightFontObject("GameFontHighlightLarge")
   
   -- Button functionality: Send text to /say chat
   postSayButton:SetScript("OnClick", function()
         local textToSay = editBox:GetText() -- Get the current text in the edit box
         if textToSay ~= "" then
            SendChatMessage(textToSay, "SAY") -- Post the text to the /s chat
         else
            print("The text box is empty.") -- Optional: Message in chat if the box is empty
         end
   end)
   
   -- Create a button to post the content to /raid or /party chat
   local postGroupButton = CreateFrame("Button", nil, editFrame, "GameMenuButtonTemplate")
   postGroupButton:SetSize(120, 30) -- Button size (Width, Height)
   postGroupButton:SetPoint("BOTTOM", editFrame, "BOTTOM", 0, 10) -- Position below the first button
   postGroupButton:SetText("Post to Group") -- Button text
   postGroupButton:SetNormalFontObject("GameFontNormalLarge")
   postGroupButton:SetHighlightFontObject("GameFontHighlightLarge")
   
   -- Button functionality: Send text to /raid or /party chat
   postGroupButton:SetScript("OnClick", function()
         local textToPost = editBox:GetText() -- Get the current text in the edit box
         if textToPost ~= "" then
            if IsInRaid() then
               SendChatMessage(textToPost, "RAID") -- Post the text to the raid chat
            elseif IsInGroup() then
               SendChatMessage(textToPost, "PARTY") -- Post the text to the party chat
            else
               print("You are not in a raid or party.") -- Message if not in group
            end
         else
            print("The text box is empty.") -- Optional: Message in chat if the box is empty
         end
      end)
      
      -- Make the frame draggable
      editFrame:SetMovable(true)
      editFrame:EnableMouse(true)
      editFrame:RegisterForDrag("LeftButton")
      editFrame:SetScript("OnDragStart", editFrame.StartMoving)
      editFrame:SetScript("OnDragStop", editFrame.StopMovingOrSizing)
      
      -- Show the frame
      editFrame:Show()
      
      -- Hide the frame after 30 seconds (optional, remove if you want it to stay open)
      C_Timer.After(10, function()
            editFrame:Hide()
      end)
   end
   
   -- Helper function to get the NPC ID from the target's GUID
   local function GetNPCIDFromGUID(guid)
      if guid then
         local unitType, _, _, _, _, npcID = strsplit("-", guid)
         if unitType == "Creature" or unitType == "Vehicle" or unitType == "Pet" then
            return tonumber(npcID)
         end
      end
      return nil
   end
   
   -- Event handler function
   local function OnEvent(self, event, ...)
      if event == "PLAYER_TARGET_CHANGED" then
         -- Get the GUID of the current target
         local targetGUID = UnitGUID("target")
         
         -- Get the NPC ID from the GUID
         local npcID = GetNPCIDFromGUID(targetGUID)
         
         -- Check if the targeted NPC ID is in the npcMessages table
         local message = npcMessages[npcID] or defaultMessage -- Use defaultMessage if npcID not in table
         
         -- Show the editable text box with the message
         ShowEditableTextBox(message)
      end
   end
   
   -- Set the script to run when the event is triggered
   frame:SetScript("OnEvent", OnEvent)
   
