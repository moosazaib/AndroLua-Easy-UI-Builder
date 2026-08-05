require "import"
import "android.widget.*"
import "android.view.*"
import "java.io.File"
import "com.androlua.*"
import "android.content.DialogInterface"
import "android.graphics.Color"
import "android.content.ClipData"
import "android.content.ClipboardManager"
import "android.text.InputType"
import "android.os.Environment"
import "android.content.Intent"
import "android.net.Uri"

local aboutModule = require("about")
local updater = require("updater")

local oldDataFile = tostring(service.getFilesDir()) .. "/csr_multiproject_data.lua"
local storageDir = Environment.getExternalStorageDirectory().getAbsolutePath() .. "/AndroLua Easy UI Builder"
local dataFile = storageDir .. "/csr_multiproject_data.lua"

pcall(function()
  local folder = File(storageDir)
  if not folder.exists() then
    folder.mkdirs()
  end
  local oldFile = File(oldDataFile)
  local newFile = File(dataFile)
  if oldFile.exists() and not newFile.exists() then
    local fIn = io.open(oldDataFile, "r")
    if fIn then
      local data = fIn:read("*a")
      fIn:close()
      local fOut = io.open(dataFile, "w")
      if fOut then
        fOut:write(data)
        fOut:close()
        os.remove(oldDataFile)
      end
    end
  end
end)

local appData = {
  projects = {},
  nextProjectId = 1
}

local loadData = function()
  pcall(function()
    local f = io.open(dataFile, "r")
    if f then
      local content = f:read("*a")
      f:close()
      local chunk, err = load(content)
      if chunk then
        local res = chunk()
        if type(res) == "table" then
          appData = res
        end
      end
    end
  end)
end

local saveData = function()
  pcall(function()
    local f = io.open(dataFile, "w")
    if f then
      local serialize
      serialize = function(tbl)
        local result = "{\n"
        for k, v in pairs(tbl) do
          result = result .. "  [" .. (type(k) == "string" and ('"' .. k .. '"') or tostring(k)) .. "] = "
          if type(v) == "table" then
            result = result .. serialize(v)
          elseif type(v) == "string" then
            result = result .. '"' .. v:gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
          else
            result = result .. tostring(v)
          end
          result = result .. ",\n"
        end
        return result .. "}"
      end
      f:write("return " .. serialize(appData))
      f:close()
    end
  end)
end

loadData()

local historyStack = {}
local dlg = nil

local showToast = function(msg)
  pcall(function()
    local messageStr = tostring(msg)
    Toast.makeText(service, messageStr, Toast.LENGTH_SHORT).show()
    service.speak(messageStr)
  end)
end

local copyToClipboard = function(text)
  pcall(function()
    local context = service
    local clipboard = context.getSystemService(context.CLIPBOARD_SERVICE)
    local clip = ClipData.newPlainText("GeneratedCode", text)
    clipboard.setPrimaryClip(clip)
    showToast("Code copied!")
  end)
end

local generateLuaCode = function(project)
  if not project or #project.windows == 0 then
    return ""
  end
  local code = 'require "import"\nimport "android.widget.*"\nimport "android.view.*"\nimport "android.graphics.Color"\nimport "android.content.DialogInterface"\nimport "android.content.Intent"\nimport "android.net.Uri"\n\n'
  code = code .. 'local windows = {}\nlocal dlg = nil\nlocal navStack = {}\n\n'
  for _, win in ipairs(project.windows) do
    code = code .. 'windows[' .. tostring(win.id) .. '] = {\n'
    code = code .. '  title = "' .. tostring(win.title) .. '",\n'
    code = code .. '  elements = {\n'
    for _, elem in ipairs(win.elements) do
      if elem.type == "title" then
        code = code .. '    { type = "title" },\n'
      elseif elem.type == "button" then
        code = code .. '    { type = "button", label = "' .. tostring(elem.label) .. '", targetId = ' .. tostring(elem.targetId or "nil") .. ' },\n'
      elseif elem.type == "clickable" then
        code = code .. '    { type = "clickable", label = "' .. tostring(elem.label) .. '", targetId = ' .. tostring(elem.targetId or "nil") .. ' },\n'
      elseif elem.type == "edittext" then
        code = code .. '    { type = "edittext", hint = "' .. tostring(elem.hint) .. '" },\n'
      elseif elem.type == "checkbox" then
        code = code .. '    { type = "checkbox", label = "' .. tostring(elem.label) .. '" },\n'
      elseif elem.type == "textview" then
        code = code .. '    { type = "textview", text = "' .. tostring(elem.text) .. '" },\n'
      elseif elem.type == "slider" then
        code = code .. '    { type = "slider", label = "' .. tostring(elem.label or "") .. '" },\n'
      elseif elem.type == "linkbutton" then
        code = code .. '    { type = "linkbutton", label = "' .. tostring(elem.label) .. '", url = "' .. tostring(elem.url) .. '" },\n'
      elseif elem.type == "combobox" then
        code = code .. '    { type = "combobox", label = "' .. tostring(elem.label or "") .. '", options = "' .. tostring(elem.options or "") .. '" },\n'
      elseif elem.type == "togglebutton" then
        code = code .. '    { type = "togglebutton", options = "' .. tostring(elem.options or "") .. '" },\n'
      end
    end
    code = code .. '  }\n}\n\n'
  end
  code = code .. 'local showScreen\nshowScreen = function(id, isBack)\n'
  code = code .. '  local winData = windows[id]\n'
  code = code .. '  if not winData then return end\n'
  code = code .. '  if not isBack then\n'
  code = code .. '    table.insert(navStack, id)\n'
  code = code .. '  end\n'
  code = code .. '  local layout = {\n'
  code = code .. '    LinearLayout,\n'
  code = code .. '    orientation = "vertical",\n'
  code = code .. '    layout_width = "fill",\n'
  code = code .. '    layout_height = "fill",\n'
  code = code .. '    backgroundColor = Color.parseColor("#121212"),\n'
  code = code .. '    padding = "16dp",\n'
  code = code .. '    {\n'
  code = code .. '      ScrollView,\n'
  code = code .. '      layout_width = "fill",\n'
  code = code .. '      layout_height = "fill",\n'
  code = code .. '      fillViewport = true,\n'
  code = code .. '      {\n'
  code = code .. '        LinearLayout,\n'
  code = code .. '        id = "container",\n'
  code = code .. '        orientation = "vertical",\n'
  code = code .. '        layout_width = "fill",\n'
  code = code .. '        layout_height = "wrap",\n'
  code = code .. '      }\n'
  code = code .. '    }\n'
  code = code .. '  }\n'
  code = code .. '  if dlg then dlg.dismiss() end\n'
  code = code .. '  dlg = LuaDialog(service)\n'
  code = code .. '  dlg.View = loadlayout(layout)\n'
  code = code .. '  for _, elem in ipairs(winData.elements) do\n'
  code = code .. '    if elem.type == "title" then\n'
  code = code .. '      local t = TextView(service)\n'
  code = code .. '      t.setText(winData.title)\n'
  code = code .. '      t.setTextSize(20)\n'
  code = code .. '      t.setTextColor(Color.WHITE)\n'
  code = code .. '      t.setPadding(10, 10, 10, 10)\n'
  code = code .. '      container.addView(t)\n'
  code = code .. '    elseif elem.type == "button" then\n'
  code = code .. '      local b = Button(service)\n'
  code = code .. '      b.setText(elem.label)\n'
  code = code .. '      b.setOnClickListener(function()\n'
  code = code .. '        if elem.targetId == 0 then\n'
  code = code .. '          if #navStack > 1 then\n'
  code = code .. '            table.remove(navStack)\n'
  code = code .. '            local prevId = navStack[#navStack]\n'
  code = code .. '            table.remove(navStack)\n'
  code = code .. '            showScreen(prevId, false)\n'
  code = code .. '          else\n'
  code = code .. '            if dlg then dlg.dismiss() end\n'
  code = code .. '          end\n'
  code = code .. '        elseif elem.targetId and windows[elem.targetId] then\n'
  code = code .. '          showScreen(elem.targetId, false)\n'
  code = code .. '        end\n'
  code = code .. '      end)\n'
  code = code .. '      container.addView(b)\n'
  code = code .. '    elseif elem.type == "clickable" then\n'
  code = code .. '      local l = LinearLayout(service)\n'
  code = code .. '      l.setOrientation(LinearLayout.VERTICAL)\n'
  code = code .. '      l.setPadding(20, 20, 20, 20)\n'
  code = code .. '      l.setClickable(true)\n'
  code = code .. '      l.setFocusable(true)\n'
  code = code .. '      local t = TextView(service)\n'
  code = code .. '      t.setText(elem.label)\n'
  code = code .. '      t.setTextColor(Color.WHITE)\n'
  code = code .. '      l.addView(t)\n'
  code = code .. '      l.setOnClickListener(function()\n'
  code = code .. '        if elem.targetId == 0 then\n'
  code = code .. '          if #navStack > 1 then\n'
  code = code .. '            table.remove(navStack)\n'
  code = code .. '            local prevId = navStack[#navStack]\n'
  code = code .. '            table.remove(navStack)\n'
  code = code .. '            showScreen(prevId, false)\n'
  code = code .. '          else\n'
  code = code .. '            if dlg then dlg.dismiss() end\n'
  code = code .. '          end\n'
  code = code .. '        elseif elem.targetId and windows[elem.targetId] then\n'
  code = code .. '          showScreen(elem.targetId, false)\n'
  code = code .. '        end\n'
  code = code .. '      end)\n'
  code = code .. '      container.addView(l)\n'
  code = code .. '    elseif elem.type == "edittext" then\n'
  code = code .. '      local e = EditText(service)\n'
  code = code .. '      if elem.hint and elem.hint ~= "" then\n'
  code = code .. '        e.setHint(elem.hint)\n'
  code = code .. '      end\n'
  code = code .. '      e.setTextColor(Color.WHITE)\n'
  code = code .. '      container.addView(e)\n'
  code = code .. '    elseif elem.type == "checkbox" then\n'
  code = code .. '      local c = CheckBox(service)\n'
  code = code .. '      c.setText(elem.label)\n'
  code = code .. '      c.setTextColor(Color.WHITE)\n'
  code = code .. '      container.addView(c)\n'
  code = code .. '    elseif elem.type == "textview" then\n'
  code = code .. '      local t = TextView(service)\n'
  code = code .. '      t.setText(elem.text)\n'
  code = code .. '      t.setTextColor(Color.WHITE)\n'
  code = code .. '      container.addView(t)\n'
  code = code .. '    elseif elem.type == "slider" then\n'
  code = code .. '      if elem.label and elem.label ~= "" then\n'
  code = code .. '        local t = TextView(service)\n'
  code = code .. '        t.setText(elem.label)\n'
  code = code .. '        t.setTextColor(Color.WHITE)\n'
  code = code .. '        container.addView(t)\n'
  code = code .. '      end\n'
  code = code .. '      local s = SeekBar(service)\n'
  code = code .. '      s.setMax(100)\n'
  code = code .. '      container.addView(s)\n'
  code = code .. '    elseif elem.type == "linkbutton" then\n'
  code = code .. '      local b = Button(service)\n'
  code = code .. '      b.setText(elem.label)\n'
  code = code .. '      b.setOnClickListener(function()\n'
  code = code .. '        if dlg then dlg.dismiss() end\n'
  code = code .. '        pcall(function()\n'
  code = code .. '          local intent = Intent(Intent.ACTION_VIEW, Uri.parse(elem.url))\n'
  code = code .. '          intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)\n'
  code = code .. '          service.startActivity(intent)\n'
  code = code .. '        end)\n'
  code = code .. '      end)\n'
  code = code .. '      container.addView(b)\n'
  code = code .. '    elseif elem.type == "combobox" then\n'
  code = code .. '      if elem.label and elem.label ~= "" then\n'
  code = code .. '        local t = TextView(service)\n'
  code = code .. '        t.setText(elem.label)\n'
  code = code .. '        t.setTextColor(Color.WHITE)\n'
  code = code .. '        container.addView(t)\n'
  code = code .. '      end\n'
  code = code .. '      local s = Spinner(service)\n'
  code = code .. '      local opts = {}\n'
  code = code .. '      for opt in string.gmatch(elem.options or "", "[^,]+") do\n'
  code = code .. '        local trimmed = opt:match("^%s*(.-)%s*$")\n'
  code = code .. '        if trimmed ~= "" then table.insert(opts, trimmed) end\n'
  code = code .. '      end\n'
  code = code .. '      if #opts == 0 then table.insert(opts, "Option 1") end\n'
  code = code .. '      local adapter = ArrayAdapter(service, android.R.layout.simple_spinner_item, opts)\n'
  code = code .. '      adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)\n'
  code = code .. '      s.setAdapter(adapter)\n'
  code = code .. '      container.addView(s)\n'
  code = code .. '    elseif elem.type == "togglebutton" then\n'
  code = code .. '      local b = Button(service)\n'
  code = code .. '      local opts = {}\n'
  code = code .. '      for opt in string.gmatch(elem.options or "", "[^,]+") do\n'
  code = code .. '        local trimmed = opt:match("^%s*(.-)%s*$")\n'
  code = code .. '        if trimmed ~= "" then table.insert(opts, trimmed) end\n'
  code = code .. '      end\n'
  code = code .. '      if #opts == 0 then table.insert(opts, "Option 1") end\n'
  code = code .. '      local idx = 1\n'
  code = code .. '      b.setText(opts[idx])\n'
  code = code .. '      b.setOnClickListener(function()\n'
  code = code .. '        idx = (idx % #opts) + 1\n'
  code = code .. '        b.setText(opts[idx])\n'
  code = code .. '      end)\n'
  code = code .. '      container.addView(b)\n'
  code = code .. '    end\n'
  code = code .. '  end\n'
  code = code .. '  dlg.setOnKeyListener(DialogInterface.OnKeyListener{\n'
  code = code .. '    onKey = function(dialog, keyCode, event)\n'
  code = code .. '      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then\n'
  code = code .. '        if #navStack > 1 then\n'
  code = code .. '          table.remove(navStack)\n'
  code = code .. '          local prevId = navStack[#navStack]\n'
  code = code .. '          table.remove(navStack)\n'
  code = code .. '          showScreen(prevId, false)\n'
  code = code .. '        else\n'
  code = code .. '          if dlg then dlg.dismiss() end\n'
  code = code .. '        end\n'
  code = code .. '        return true\n'
  code = code .. '      end\n'
  code = code .. '      return false\n'
  code = code .. '    end\n'
  code = code .. '  })\n'
  code = code .. '  dlg.show()\n'
  code = code .. 'end\n\n'
  code = code .. 'showScreen(' .. tostring(project.windows[1].id) .. ', false)\n'
  return code
end

local renderMainMenu, renderSavedProjectsList, renderProjectDashboard, renderCreateWindow, renderAddButton, renderAddClickable, renderAddEditText, renderAddCheckBox, renderAddTextView, renderAddTitle, renderAddSlider, renderAddLinkButton, renderAddComboBox, renderAddToggleButton, renderEditElement, renderManageWindows, renderEditWindow, renderExportCode, renderLiveTest, renderCreateProjectDialog, renderAddElementMenu, renderChangeElementTypeMenu

renderLiveTest = function(project, param)
  local activeWin = nil
  if type(param) == "table" then
    activeWin = param
  else
    for _, win in ipairs(project.windows) do
      if win.id == param then
        activeWin = win
        break
      end
    end
  end

  if not activeWin then
    if #project.windows > 0 then
      activeWin = project.windows[1]
    else
      showToast("No windows in project!")
      return
    end
  end

  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#0F0F14"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        id = "test_container",
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  for _, elem in ipairs(activeWin.elements) do
    if elem.type == "title" then
      local t = TextView(service)
      t.setText(activeWin.title)
      t.setTextSize(20)
      t.setTextColor(Color.WHITE)
      t.setPadding(10, 10, 10, 10)
      test_container.addView(t)
    elseif elem.type == "button" then
      local b = Button(service)
      b.setText(elem.label)
      b.setOnClickListener(function()
        if elem.targetId == 0 then
          if #historyStack > 0 then
            local prev = table.remove(historyStack)
            prev.func()
          else
            if dlg then dlg.dismiss() end
          end
        elseif elem.targetId then
          local targetWin = nil
          for _, w in ipairs(project.windows) do
            if w.id == elem.targetId then
              targetWin = w
              break
            end
          end
          if targetWin then
            table.insert(historyStack, {func = function() renderLiveTest(project, activeWin) end})
            renderLiveTest(project, targetWin)
          else
            showToast("Target Window ID " .. tostring(elem.targetId) .. " not found!")
          end
        else
          showToast("Clicked: " .. elem.label)
        end
      end)
      test_container.addView(b)
    elseif elem.type == "clickable" then
      local l = LinearLayout(service)
      l.setOrientation(LinearLayout.VERTICAL)
      l.setPadding(20, 20, 20, 20)
      l.setClickable(true)
      l.setFocusable(true)
      local t = TextView(service)
      t.setText(elem.label)
      t.setTextColor(Color.WHITE)
      l.addView(t)
      l.setOnClickListener(function()
        if elem.targetId == 0 then
          if #historyStack > 0 then
            local prev = table.remove(historyStack)
            prev.func()
          else
            if dlg then dlg.dismiss() end
          end
        elseif elem.targetId then
          local targetWin = nil
          for _, w in ipairs(project.windows) do
            if w.id == elem.targetId then
              targetWin = w
              break
            end
          end
          if targetWin then
            table.insert(historyStack, {func = function() renderLiveTest(project, activeWin) end})
            renderLiveTest(project, targetWin)
          else
            showToast("Target Window ID " .. tostring(elem.targetId) .. " not found!")
          end
        else
          showToast("Clicked: " .. elem.label)
        end
      end)
      test_container.addView(l)
    elseif elem.type == "edittext" then
      local e = EditText(service)
      if elem.hint and elem.hint ~= "" then
        e.setHint(elem.hint)
      end
      e.setTextColor(Color.WHITE)
      test_container.addView(e)
    elseif elem.type == "checkbox" then
      local c = CheckBox(service)
      c.setText(elem.label)
      c.setTextColor(Color.WHITE)
      test_container.addView(c)
    elseif elem.type == "textview" then
      local t = TextView(service)
      t.setText(elem.text)
      t.setTextColor(Color.WHITE)
      test_container.addView(t)
    elseif elem.type == "slider" then
      if elem.label and elem.label ~= "" then
        local t = TextView(service)
        t.setText(elem.label)
        t.setTextColor(Color.WHITE)
        test_container.addView(t)
      end
      local s = SeekBar(service)
      s.setMax(100)
      test_container.addView(s)
    elseif elem.type == "linkbutton" then
      local b = Button(service)
      b.setText(elem.label)
      b.setOnClickListener(function()
        if dlg then dlg.dismiss() end
        pcall(function()
          local intent = Intent(Intent.ACTION_VIEW, Uri.parse(elem.url))
          intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
          service.startActivity(intent)
        end)
      end)
      test_container.addView(b)
    elseif elem.type == "combobox" then
      if elem.label and elem.label ~= "" then
        local t = TextView(service)
        t.setText(elem.label)
        t.setTextColor(Color.WHITE)
        test_container.addView(t)
      end
      local s = Spinner(service)
      local opts = {}
      for opt in string.gmatch(elem.options or "", "[^,]+") do
        local trimmed = opt:match("^%s*(.-)%s*$")
        if trimmed ~= "" then table.insert(opts, trimmed) end
      end
      if #opts == 0 then table.insert(opts, "Option 1") end
      local adapter = ArrayAdapter(service, android.R.layout.simple_spinner_item, opts)
      adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
      s.setAdapter(adapter)
      test_container.addView(s)
    elseif elem.type == "togglebutton" then
      local b = Button(service)
      local opts = {}
      for opt in string.gmatch(elem.options or "", "[^,]+") do
        local trimmed = opt:match("^%s*(.-)%s*$")
        if trimmed ~= "" then table.insert(opts, trimmed) end
      end
      if #opts == 0 then table.insert(opts, "Option 1") end
      local idx = 1
      b.setText(opts[idx])
      b.setOnClickListener(function()
        idx = (idx % #opts) + 1
        b.setText(opts[idx])
      end)
      test_container.addView(b)
    end
  end

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
        else
          if dlg then dlg.dismiss() end
        end
        return true
      end
      return false
    end
  })
  dlg.show()
end

renderCreateProjectDialog = function()
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Create New Project",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "Project Name: (Required)",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_new_proj_name",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_do_create",
          text = "Create Project",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_cancel_create",
          text = "Cancel",
          layout_width = "fill",
        },
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  edt_new_proj_name.addTextChangedListener({
    onTextChanged = function(s, start, before, count)
      local text = tostring(s):match("^%s*(.-)%s*$")
      btn_do_create.setEnabled(text ~= "")
    end,
    beforeTextChanged = function() end,
    afterTextChanged = function() end
  })

  btn_do_create.setEnabled(false)

  btn_do_create.setOnClickListener(function()
    local nameStr = tostring(edt_new_proj_name.getText()):match("^%s*(.-)%s*$")
    if nameStr == "" then
      showToast("Project name cannot be empty!")
      return
    end

    local exists = false
    for _, p in ipairs(appData.projects) do
      if p.name == nameStr then
        exists = true
        break
      end
    end

    if exists then
      showToast("A project with this name already exists!")
      return
    end

    local newProj = {
      id = appData.nextProjectId,
      name = nameStr,
      windows = {},
      nextWindowId = 1
    }
    appData.nextProjectId = appData.nextProjectId + 1
    table.insert(appData.projects, newProj)
    saveData()

    local successLayout = {
      LinearLayout,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "fill",
      backgroundColor = Color.parseColor("#121212"),
      padding = "16dp",
      {
        ScrollView,
        layout_width = "fill",
        layout_height = "fill",
        fillViewport = true,
        {
          LinearLayout,
          orientation = "vertical",
          layout_width = "fill",
          layout_height = "wrap",
          {
            TextView,
            text = "Project Created Successfully!",
            textSize = "20sp",
            textColor = Color.WHITE,
            padding = "10dp",
          },
          {
            TextView,
            text = "Your project has been successfully created. You can now access, edit, and manage it anytime from 'Saved Projects'!",
            textColor = Color.LTGRAY,
            textSize = "16sp",
            padding = "10dp",
          },
          {
            Button,
            id = "btn_success_ok",
            text = "OK",
            layout_width = "fill",
          },
        }
      }
    }

    if dlg then dlg.dismiss() end
    dlg = LuaDialog(service)
    dlg.View = loadlayout(successLayout)

    btn_success_ok.setOnClickListener(function()
      renderMainMenu()
    end)

    dlg.setOnKeyListener(DialogInterface.OnKeyListener{
      onKey = function(dialog, keyCode, event)
        if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
          renderMainMenu()
          return true
        end
        return false
      end
    })
    dlg.show()
  end)

  btn_cancel_create.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    else
      renderMainMenu()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderMainMenu = function()
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "AndroLua Easy UI Builder",
          textSize = "22sp",
          textColor = Color.WHITE,
          padding = "15dp",
        },
        {
          Button,
          id = "btn_create_proj",
          text = "Create New Project",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_saved_projs",
          text = "Saved Projects (" .. tostring(#appData.projects) .. ")",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_about",
          text = "About",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_exit",
          text = "Exit",
          layout_width = "fill",
        },
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  btn_create_proj.setOnClickListener(function()
    table.insert(historyStack, {func = renderMainMenu})
    renderCreateProjectDialog()
  end)

  btn_saved_projs.setOnClickListener(function()
    table.insert(historyStack, {func = renderMainMenu})
    renderSavedProjectsList()
  end)

  btn_about.setOnClickListener(function()
    table.insert(historyStack, {func = renderMainMenu})
    aboutModule.renderAbout(service, historyStack, dlg, showToast, renderMainMenu)
  end)

  btn_exit.setOnClickListener(function()
    if dlg then dlg.dismiss() end
    historyStack = {}
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if dlg then dlg.dismiss() end
        return true
      end
      return false
    end
  })
  dlg.show()
end

renderSavedProjectsList = function()
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "0dp",
      layout_weight = 1,
      fillViewport = true,
      {
        LinearLayout,
        id = "saved_list_container",
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Your Saved Projects",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
      }
    },
    {
      Button,
      id = "btn_back_menu",
      text = "Back to Main Menu",
      layout_width = "fill",
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  if #appData.projects == 0 then
    local emptyTxt = TextView(service)
    emptyTxt.setText("No saved projects found. Create one!")
    emptyTxt.setTextColor(Color.GRAY)
    saved_list_container.addView(emptyTxt)
  else
    for _, proj in ipairs(appData.projects) do
      local pBtn = Button(service)
      pBtn.setText(proj.name .. " (" .. tostring(#proj.windows) .. " windows)")
      pBtn.setOnClickListener(function()
        table.insert(historyStack, {func = renderSavedProjectsList})
        renderProjectDashboard(proj)
      end)
      saved_list_container.addView(pBtn)
    end
  end

  btn_back_menu.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    else
      renderMainMenu()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        renderMainMenu()
        return true
      end
      return false
    end
  })
  dlg.show()
end

renderProjectDashboard = function(project)
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Project Dashboard",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "Project Name: (Required)",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_proj_name",
          text = project.name,
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_save_proj_name",
          text = "Save Project Name",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_test_proj",
          text = "Test Project (Run)",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_create_win",
          text = "Create New Window",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_manage_wins",
          text = "Manage Windows (" .. tostring(#project.windows) .. ")",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_export_code",
          text = "Generate & Export Lua Code",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_delete_proj",
          text = "Delete Project",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_back_saved",
          text = "Back to Saved Projects",
          layout_width = "fill",
        },
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  edt_proj_name.addTextChangedListener({
    onTextChanged = function(s, start, before, count)
      local text = tostring(s):match("^%s*(.-)%s*$")
      btn_save_proj_name.setEnabled(text ~= "")
    end,
    beforeTextChanged = function() end,
    afterTextChanged = function() end
  })
  btn_save_proj_name.setEnabled(tostring(edt_proj_name.getText()):match("^%s*(.-)%s*$") ~= "")

  btn_save_proj_name.setOnClickListener(function()
    local nameStr = edt_proj_name.getText().toString():match("^%s*(.-)%s*$")
    if nameStr ~= "" then
      project.name = nameStr
      saveData()
      showToast("Project name updated!")
    end
  end)

  btn_test_proj.setOnClickListener(function()
    if #project.windows == 0 then
      showToast("Please create at least one window first!")
    else
      table.insert(historyStack, {func = function() renderProjectDashboard(project) end})
      renderLiveTest(project, project.windows[1])
    end
  end)

  btn_create_win.setOnClickListener(function()
    table.insert(historyStack, {func = function() renderProjectDashboard(project) end})
    renderCreateWindow(project, {title = "Window #" .. tostring(project.nextWindowId), elements = {{type = "title"}}})
  end)

  btn_manage_wins.setOnClickListener(function()
    table.insert(historyStack, {func = function() renderProjectDashboard(project) end})
    renderManageWindows(project)
  end)

  btn_export_code.setOnClickListener(function()
    table.insert(historyStack, {func = function() renderProjectDashboard(project) end})
    renderExportCode(project)
  end)

  btn_delete_proj.setOnClickListener(function()
    local confirmLayout = {
      LinearLayout,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "fill",
      backgroundColor = Color.parseColor("#121212"),
      padding = "16dp",
      {
        ScrollView,
        layout_width = "fill",
        layout_height = "fill",
        fillViewport = true,
        {
          LinearLayout,
          orientation = "vertical",
          layout_width = "fill",
          layout_height = "wrap",
          {
            TextView,
            text = "Confirm Deletion",
            textSize = "20sp",
            textColor = Color.WHITE,
            padding = "10dp",
          },
          {
            TextView,
            text = "Are you sure you want to delete project '" .. project.name .. "'?",
            textColor = Color.LTGRAY,
            padding = "10dp",
          },
          {
            Button,
            id = "btn_confirm_del",
            text = "Yes, Delete",
            layout_width = "fill",
          },
          {
            Button,
            id = "btn_cancel_del",
            text = "Cancel",
            layout_width = "fill",
          },
        }
      }
    }
    table.insert(historyStack, {func = function() renderProjectDashboard(project) end})
    if dlg then dlg.dismiss() end
    dlg = LuaDialog(service)
    dlg.View = loadlayout(confirmLayout)

    btn_confirm_del.setOnClickListener(function()
      for i, p in ipairs(appData.projects) do
        if p.id == project.id then
          table.remove(appData.projects, i)
          break
        end
      end
      saveData()
      showToast("Project Deleted!")
      if #historyStack > 0 then table.remove(historyStack) end
      if #historyStack > 0 then table.remove(historyStack) end
      renderSavedProjectsList()
    end)

    btn_cancel_del.setOnClickListener(function()
      if #historyStack > 0 then
        local prev = table.remove(historyStack)
        prev.func()
      end
    end)

    dlg.setOnKeyListener(DialogInterface.OnKeyListener{
      onKey = function(dialog, keyCode, event)
        if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
          if #historyStack > 0 then
            local prev = table.remove(historyStack)
            prev.func()
            return true
          end
        end
        return false
      end
    })
    dlg.show()
  end)

  btn_back_saved.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    else
      renderSavedProjectsList()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        else
          renderSavedProjectsList()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderAddElementMenu = function(project, tempWindow)
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "0dp",
      layout_weight = 1,
      fillViewport = true,
      {
        LinearLayout,
        id = "add_menu_container",
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Select Element to Add",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
      }
    },
    {
      Button,
      id = "btn_add_menu_back",
      text = "Back",
      layout_width = "fill",
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  local hasTitle = false
  for _, elem in ipairs(tempWindow.elements) do
    if elem.type == "title" then
      hasTitle = true
      break
    end
  end

  if not hasTitle then
    local bTitle = Button(service)
    bTitle.setText("Add Window Title Element")
    bTitle.setOnClickListener(function()
      renderAddTitle(project, tempWindow)
    end)
    add_menu_container.addView(bTitle)
  end

  local bBtn = Button(service)
  bBtn.setText("Add Button")
  bBtn.setOnClickListener(function()
    renderAddButton(project, tempWindow)
  end)
  add_menu_container.addView(bBtn)

  local bClk = Button(service)
  bClk.setText("Add Clickable Item")
  bClk.setOnClickListener(function()
    renderAddClickable(project, tempWindow)
  end)
  add_menu_container.addView(bClk)

  local bEdt = Button(service)
  bEdt.setText("Add Input Box")
  bEdt.setOnClickListener(function()
    renderAddEditText(project, tempWindow)
  end)
  add_menu_container.addView(bEdt)

  local bChk = Button(service)
  bChk.setText("Add CheckBox")
  bChk.setOnClickListener(function()
    renderAddCheckBox(project, tempWindow)
  end)
  add_menu_container.addView(bChk)

  local bTxt = Button(service)
  bTxt.setText("Add TextView")
  bTxt.setOnClickListener(function()
    renderAddTextView(project, tempWindow)
  end)
  add_menu_container.addView(bTxt)

  local bSld = Button(service)
  bSld.setText("Add Slider")
  bSld.setOnClickListener(function()
    renderAddSlider(project, tempWindow)
  end)
  add_menu_container.addView(bSld)

  local bLnk = Button(service)
  bLnk.setText("Add Link Button")
  bLnk.setOnClickListener(function()
    renderAddLinkButton(project, tempWindow)
  end)
  add_menu_container.addView(bLnk)

  local bCmb = Button(service)
  bCmb.setText("Add ComboBox")
  bCmb.setOnClickListener(function()
    renderAddComboBox(project, tempWindow)
  end)
  add_menu_container.addView(bCmb)

  local bTgl = Button(service)
  bTgl.setText("Add Toggle Button")
  bTgl.setOnClickListener(function()
    renderAddToggleButton(project, tempWindow)
  end)
  add_menu_container.addView(bTgl)

  btn_add_menu_back.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderChangeElementTypeMenu = function(project, tempWindow, elemIndex)
  local currentElem = tempWindow.elements[elemIndex]
  if not currentElem then return end
  local currentType = currentElem.type

  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "0dp",
      layout_weight = 1,
      fillViewport = true,
      {
        LinearLayout,
        id = "change_menu_container",
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Select New Element Type",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
      }
    },
    {
      Button,
      id = "btn_change_menu_back",
      text = "Back",
      layout_width = "fill",
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  local hasTitle = false
  for _, elem in ipairs(tempWindow.elements) do
    if elem.type == "title" then
      hasTitle = true
      break
    end
  end

  if currentType ~= "title" and not hasTitle then
    local bTitle = Button(service)
    bTitle.setText("Add Window Title Element")
    bTitle.setOnClickListener(function()
      renderAddTitle(project, tempWindow, elemIndex)
    end)
    change_menu_container.addView(bTitle)
  end

  if currentType ~= "button" then
    local bBtn = Button(service)
    bBtn.setText("Add Button")
    bBtn.setOnClickListener(function()
      renderAddButton(project, tempWindow, elemIndex)
    end)
    change_menu_container.addView(bBtn)
  end

  if currentType ~= "clickable" then
    local bClk = Button(service)
    bClk.setText("Add Clickable Item")
    bClk.setOnClickListener(function()
      renderAddClickable(project, tempWindow, elemIndex)
    end)
    change_menu_container.addView(bClk)
  end

  if currentType ~= "edittext" then
    local bEdt = Button(service)
    bEdt.setText("Add Input Box")
    bEdt.setOnClickListener(function()
      renderAddEditText(project, tempWindow, elemIndex)
    end)
    change_menu_container.addView(bEdt)
  end

  if currentType ~= "checkbox" then
    local bChk = Button(service)
    bChk.setText("Add CheckBox")
    bChk.setOnClickListener(function()
      renderAddCheckBox(project, tempWindow, elemIndex)
    end)
    change_menu_container.addView(bChk)
  end

  if currentType ~= "textview" then
    local bTxt = Button(service)
    bTxt.setText("Add TextView")
    bTxt.setOnClickListener(function()
      renderAddTextView(project, tempWindow, elemIndex)
    end)
    change_menu_container.addView(bTxt)
  end

  if currentType ~= "slider" then
    local bSld = Button(service)
    bSld.setText("Add Slider")
    bSld.setOnClickListener(function()
      renderAddSlider(project, tempWindow, elemIndex)
    end)
    change_menu_container.addView(bSld)
  end

  if currentType ~= "linkbutton" then
    local bLnk = Button(service)
    bLnk.setText("Add Link Button")
    bLnk.setOnClickListener(function()
      renderAddLinkButton(project, tempWindow, elemIndex)
    end)
    change_menu_container.addView(bLnk)
  end

  if currentType ~= "combobox" then
    local bCmb = Button(service)
    bCmb.setText("Add ComboBox")
    bCmb.setOnClickListener(function()
      renderAddComboBox(project, tempWindow, elemIndex)
    end)
    change_menu_container.addView(bCmb)
  end

  if currentType ~= "togglebutton" then
    local bTgl = Button(service)
    bTgl.setText("Add Toggle Button")
    bTgl.setOnClickListener(function()
      renderAddToggleButton(project, tempWindow, elemIndex)
    end)
    change_menu_container.addView(bTgl)
  end

  btn_change_menu_back.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderCreateWindow = function(project, tempWindow)
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#1C1C1E"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "0dp",
      layout_weight = 1,
      fillViewport = true,
      {
        LinearLayout,
        id = "create_win_container",
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "New Window ID " .. tostring(project.nextWindowId),
          textSize = "18sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "Window Title: (Required)",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_title",
          text = tempWindow.title or "",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          TextView,
          text = "Elements Added (Click any to edit/move):",
          textColor = Color.GREEN,
          padding = "10dp",
        },
      }
    },
    {
      LinearLayout,
      id = "create_bottom_layout",
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "wrap",
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  if #tempWindow.elements == 0 then
    local emptyElem = TextView(service)
    emptyElem.setText("No elements yet.")
    emptyElem.setTextColor(Color.GRAY)
    create_win_container.addView(emptyElem)
  else
    for index, elem in ipairs(tempWindow.elements) do
      local eBtn = Button(service)
      if elem.type == "title" then
        eBtn.setText(tostring(index) .. ". [Window Title] (Title Bar)")
      elseif elem.type == "button" then
        local targetInfo = elem.targetId and (" -> Target: ID " .. tostring(elem.targetId)) or ""
        eBtn.setText(tostring(index) .. ". [Button] " .. tostring(elem.label) .. targetInfo)
      elseif elem.type == "clickable" then
        local targetInfo = elem.targetId and (" -> Target: ID " .. tostring(elem.targetId)) or ""
        eBtn.setText(tostring(index) .. ". [Clickable] " .. tostring(elem.label) .. targetInfo)
      elseif elem.type == "edittext" then
        eBtn.setText(tostring(index) .. ". [Input] " .. tostring(elem.hint))
      elseif elem.type == "checkbox" then
        eBtn.setText(tostring(index) .. ". [Checkbox] " .. tostring(elem.label))
      elseif elem.type == "textview" then
        eBtn.setText(tostring(index) .. ". [Text] " .. tostring(elem.text))
      elseif elem.type == "slider" then
        eBtn.setText(tostring(index) .. ". [Slider] " .. tostring(elem.label or "SeekBar"))
      elseif elem.type == "linkbutton" then
        eBtn.setText(tostring(index) .. ". [Link Button] " .. tostring(elem.label) .. " (" .. tostring(elem.url) .. ")")
      elseif elem.type == "combobox" then
        eBtn.setText(tostring(index) .. ". [ComboBox] " .. tostring((elem.label and elem.label ~= "") and elem.label or "ComboBox") .. " (" .. tostring(elem.options or "") .. ")")
      elseif elem.type == "togglebutton" then
        eBtn.setText(tostring(index) .. ". [Toggle Button] (" .. tostring(elem.options or "") .. ")")
      end
      eBtn.setOnClickListener(function()
        tempWindow.title = edt_title.getText().toString()
        table.insert(historyStack, {func = function() renderCreateWindow(project, tempWindow) end})
        renderEditElement(project, tempWindow, index)
      end)
      create_win_container.addView(eBtn)
    end
  end

  local btn_add_item = Button(service)
  btn_add_item.setText("Add New Item")
  btn_add_item.setOnClickListener(function()
    tempWindow.title = edt_title.getText().toString()
    table.insert(historyStack, {func = function() renderCreateWindow(project, tempWindow) end})
    renderAddElementMenu(project, tempWindow)
  end)
  create_bottom_layout.addView(btn_add_item)

  local btn_win_test = Button(service)
  btn_win_test.setText("Test This Window")
  btn_win_test.setOnClickListener(function()
    local titleStr = edt_title.getText().toString()
    if titleStr == "" then titleStr = "Window #" .. tostring(project.nextWindowId) end
    tempWindow.title = titleStr
    table.insert(historyStack, {func = function() renderCreateWindow(project, tempWindow) end})
    renderLiveTest(project, tempWindow)
  end)
  create_bottom_layout.addView(btn_win_test)

  local btn_save_win = Button(service)
  btn_save_win.setText("Save Window")
  btn_save_win.setOnClickListener(function()
    local titleStr = edt_title.getText().toString()
    if titleStr == "" then titleStr = "Window #" .. tostring(project.nextWindowId) end
    tempWindow.title = titleStr
    tempWindow.id = project.nextWindowId
    project.nextWindowId = project.nextWindowId + 1
    table.insert(project.windows, tempWindow)
    saveData()
    showToast("Window Saved Successfully!")
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)
  create_bottom_layout.addView(btn_save_win)

  local btn_win_back = Button(service)
  btn_win_back.setText("Back")
  btn_win_back.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)
  create_bottom_layout.addView(btn_win_back)

  local validateWinTitle = function()
    local tText = tostring(edt_title.getText()):match("^%s*(.-)%s*$")
    local isValid = (tText ~= "")
    btn_win_test.setEnabled(isValid)
    btn_save_win.setEnabled(isValid)
  end
  edt_title.addTextChangedListener({
    onTextChanged = function() validateWinTitle() end,
    beforeTextChanged = function() end,
    afterTextChanged = function() end
  })
  validateWinTitle()

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderAddTitle = function(project, tempWindow, replaceIndex)
  local newElem = {
    type = "title"
  }
  if replaceIndex then
    tempWindow.elements[replaceIndex] = newElem
    showToast("Element type changed!")
    if #historyStack > 1 then
      table.remove(historyStack)
    end
  else
    table.insert(tempWindow.elements, newElem)
    showToast("Window Title element added!")
  end
  if #historyStack > 0 then
    local prev = table.remove(historyStack)
    prev.func()
  end
end

renderAddButton = function(project, tempWindow, replaceIndex)
  local existingList = "Available Windows in Project:\n"
  if #project.windows == 0 then
    existingList = existingList .. "(None yet)\n"
  else
    for _, w in ipairs(project.windows) do
      existingList = existingList .. "ID " .. tostring(w.id) .. ": " .. tostring(w.title) .. "\n"
    end
  end
  existingList = existingList .. "(Type 0 for System Back action)"

  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Add Button",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "Button Label: (Required)",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_label",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          TextView,
          text = existingList,
          textColor = Color.GREEN,
          textSize = "12sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "Target Window ID (Optional, 0 for Back):",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_target",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_confirm",
          text = "Confirm",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_cancel",
          text = "Cancel",
          layout_width = "fill",
        },
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)
  edt_target.setInputType(InputType.TYPE_CLASS_NUMBER)

  btn_confirm.setEnabled(false)
  edt_label.addTextChangedListener({
    onTextChanged = function(s, start, before, count)
      local text = tostring(s):match("^%s*(.-)%s*$")
      btn_confirm.setEnabled(text ~= "")
    end,
    beforeTextChanged = function() end,
    afterTextChanged = function() end
  })

  btn_confirm.setOnClickListener(function()
    local text = edt_label.getText().toString()
    if text == "" then text = "Button" end
    local targetStr = edt_target.getText().toString()
    local targetIdNum = tonumber(targetStr)
    local newElem = {
      type = "button",
      label = text,
      targetId = targetIdNum
    }
    if replaceIndex then
      tempWindow.elements[replaceIndex] = newElem
      showToast("Element type changed!")
      if #historyStack > 1 then
        table.remove(historyStack)
      end
    else
      table.insert(tempWindow.elements, newElem)
      showToast("Button added!")
    end
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  btn_cancel.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderAddClickable = function(project, tempWindow, replaceIndex)
  local existingList = "Available Windows in Project:\n"
  if #project.windows == 0 then
    existingList = existingList .. "(None yet)\n"
  else
    for _, w in ipairs(project.windows) do
      existingList = existingList .. "ID " .. tostring(w.id) .. ": " .. tostring(w.title) .. "\n"
    end
  end
  existingList = existingList .. "(Type 0 for System Back action)"

  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Add Clickable Item",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "Display Label: (Required)",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_label",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          TextView,
          text = existingList,
          textColor = Color.GREEN,
          textSize = "12sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "Target Window ID (Optional, 0 for Back):",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_target",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_confirm",
          text = "Confirm",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_cancel",
          text = "Cancel",
          layout_width = "fill",
        },
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)
  edt_target.setInputType(InputType.TYPE_CLASS_NUMBER)

  btn_confirm.setEnabled(false)
  edt_label.addTextChangedListener({
    onTextChanged = function(s, start, before, count)
      local text = tostring(s):match("^%s*(.-)%s*$")
      btn_confirm.setEnabled(text ~= "")
    end,
    beforeTextChanged = function() end,
    afterTextChanged = function() end
  })

  btn_confirm.setOnClickListener(function()
    local text = edt_label.getText().toString()
    if text == "" then text = "Clickable" end
    local targetStr = edt_target.getText().toString()
    local targetIdNum = tonumber(targetStr)
    local newElem = {
      type = "clickable",
      label = text,
      targetId = targetIdNum
    }
    if replaceIndex then
      tempWindow.elements[replaceIndex] = newElem
      showToast("Element type changed!")
      if #historyStack > 1 then
        table.remove(historyStack)
      end
    else
      table.insert(tempWindow.elements, newElem)
      showToast("Clickable item added!")
    end
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  btn_cancel.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderAddEditText = function(project, tempWindow, replaceIndex)
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Add Input Box",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "Input Hint: (Optional)",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_hint",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_confirm",
          text = "Confirm",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_cancel",
          text = "Cancel",
          layout_width = "fill",
        },
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  btn_confirm.setEnabled(true)

  btn_confirm.setOnClickListener(function()
    local hintText = edt_hint.getText().toString()
    local newElem = {
      type = "edittext",
      hint = hintText
    }
    if replaceIndex then
      tempWindow.elements[replaceIndex] = newElem
      showToast("Element type changed!")
      if #historyStack > 1 then
        table.remove(historyStack)
      end
    else
      table.insert(tempWindow.elements, newElem)
      showToast("Input box added!")
    end
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  btn_cancel.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderAddCheckBox = function(project, tempWindow, replaceIndex)
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Add CheckBox",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "CheckBox Label: (Optional)",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_label",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_confirm",
          text = "Confirm",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_cancel",
          text = "Cancel",
          layout_width = "fill",
        },
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  btn_confirm.setEnabled(true)

  btn_confirm.setOnClickListener(function()
    local text = edt_label.getText().toString()
    local newElem = {
      type = "checkbox",
      label = text
    }
    if replaceIndex then
      tempWindow.elements[replaceIndex] = newElem
      showToast("Element type changed!")
      if #historyStack > 1 then
        table.remove(historyStack)
      end
    else
      table.insert(tempWindow.elements, newElem)
      showToast("CheckBox added!")
    end
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  btn_cancel.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderAddTextView = function(project, tempWindow, replaceIndex)
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Add TextView",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "Display Text: (Required)",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_text",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_confirm",
          text = "Confirm",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_cancel",
          text = "Cancel",
          layout_width = "fill",
        },
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  btn_confirm.setEnabled(false)
  edt_text.addTextChangedListener({
    onTextChanged = function(s, start, before, count)
      local text = tostring(s):match("^%s*(.-)%s*$")
      btn_confirm.setEnabled(text ~= "")
    end,
    beforeTextChanged = function() end,
    afterTextChanged = function() end
  })

  btn_confirm.setOnClickListener(function()
    local text = edt_text.getText().toString()
    if text == "" then text = "Text" end
    local newElem = {
      type = "textview",
      text = text
    }
    if replaceIndex then
      tempWindow.elements[replaceIndex] = newElem
      showToast("Element type changed!")
      if #historyStack > 1 then
        table.remove(historyStack)
      end
    else
      table.insert(tempWindow.elements, newElem)
      showToast("TextView added!")
    end
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  btn_cancel.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderAddSlider = function(project, tempWindow, replaceIndex)
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Add Slider",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "Slider Label (Optional):",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_label",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_confirm",
          text = "Confirm",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_cancel",
          text = "Cancel",
          layout_width = "fill",
        },
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  btn_confirm.setOnClickListener(function()
    local text = edt_label.getText().toString()
    local newElem = {
      type = "slider",
      label = text
    }
    if replaceIndex then
      tempWindow.elements[replaceIndex] = newElem
      showToast("Element type changed!")
      if #historyStack > 1 then
        table.remove(historyStack)
      end
    else
      table.insert(tempWindow.elements, newElem)
      showToast("Slider added!")
    end
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  btn_cancel.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderAddLinkButton = function(project, tempWindow, replaceIndex)
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Add Link Button",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "Button Label: (Required)",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_label",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          TextView,
          text = "URL / Link: (Required)",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_url",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_confirm",
          text = "Confirm",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_cancel",
          text = "Cancel",
          layout_width = "fill",
        },
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  local validateLinkBtn = function()
    local lText = tostring(edt_label.getText()):match("^%s*(.-)%s*$")
    local uText = tostring(edt_url.getText()):match("^%s*(.-)%s*$")
    btn_confirm.setEnabled(lText ~= "" and uText ~= "")
  end
  btn_confirm.setEnabled(false)
  edt_label.addTextChangedListener({
    onTextChanged = function() validateLinkBtn() end,
    beforeTextChanged = function() end,
    afterTextChanged = function() end
  })
  edt_url.addTextChangedListener({
    onTextChanged = function() validateLinkBtn() end,
    beforeTextChanged = function() end,
    afterTextChanged = function() end
  })

  btn_confirm.setOnClickListener(function()
    local text = edt_label.getText().toString()
    if text == "" then text = "Open Link" end
    local urlText = edt_url.getText().toString()
    if urlText == "" then urlText = "https://" end
    local newElem = {
      type = "linkbutton",
      label = text,
      url = urlText
    }
    if replaceIndex then
      tempWindow.elements[replaceIndex] = newElem
      showToast("Element type changed!")
      if #historyStack > 1 then
        table.remove(historyStack)
      end
    else
      table.insert(tempWindow.elements, newElem)
      showToast("Link Button added!")
    end
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  btn_cancel.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderAddComboBox = function(project, tempWindow, replaceIndex)
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Add ComboBox",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "ComboBox Label (Optional):",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_label",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          TextView,
          text = "Options (Comma Separated): (Required)",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_options",
          hint = "e.g. Option 1, Option 2, Option 3",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_confirm",
          text = "Confirm",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_cancel",
          text = "Cancel",
          layout_width = "fill",
        },
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  btn_confirm.setEnabled(false)
  edt_options.addTextChangedListener({
    onTextChanged = function(s, start, before, count)
      local text = tostring(s):match("^%s*(.-)%s*$")
      btn_confirm.setEnabled(text ~= "")
    end,
    beforeTextChanged = function() end,
    afterTextChanged = function() end
  })

  btn_confirm.setOnClickListener(function()
    local labelText = edt_label.getText().toString()
    local optionsText = edt_options.getText().toString()
    local newElem = {
      type = "combobox",
      label = labelText,
      options = optionsText
    }
    if replaceIndex then
      tempWindow.elements[replaceIndex] = newElem
      showToast("Element type changed!")
      if #historyStack > 1 then
        table.remove(historyStack)
      end
    else
      table.insert(tempWindow.elements, newElem)
      showToast("ComboBox added!")
    end
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  btn_cancel.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderAddToggleButton = function(project, tempWindow, replaceIndex)
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Add Toggle Button",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "Options (Comma Separated): (Required)",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_options",
          hint = "e.g. Option 1, Option 2, Option 3",
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_confirm",
          text = "Confirm",
          layout_width = "fill",
        },
        {
          Button,
          id = "btn_cancel",
          text = "Cancel",
          layout_width = "fill",
        },
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  btn_confirm.setEnabled(false)
  edt_options.addTextChangedListener({
    onTextChanged = function(s, start, before, count)
      local text = tostring(s):match("^%s*(.-)%s*$")
      btn_confirm.setEnabled(text ~= "")
    end,
    beforeTextChanged = function() end,
    afterTextChanged = function() end
  })

  btn_confirm.setOnClickListener(function()
    local optionsText = edt_options.getText().toString()
    local newElem = {
      type = "togglebutton",
      options = optionsText
    }
    if replaceIndex then
      tempWindow.elements[replaceIndex] = newElem
      showToast("Element type changed!")
      if #historyStack > 1 then
        table.remove(historyStack)
      end
    else
      table.insert(tempWindow.elements, newElem)
      showToast("Toggle Button added!")
    end
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  btn_cancel.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderEditElement = function(project, tempWindow, elemIndex)
  local elem = tempWindow.elements[elemIndex]
  if not elem then
    if #historyStack > 0 then local prev = table.remove(historyStack) prev.func() end
    return
  end

  local isTitle = (elem.type == "title")
  local isToggle = (elem.type == "togglebutton")
  local valLabel = "Label/Text: (Required)"
  if elem.type == "edittext" then
    valLabel = "Input Hint: (Optional)"
  elseif elem.type == "checkbox" then
    valLabel = "CheckBox Label: (Optional)"
  elseif elem.type == "textview" then
    valLabel = "Display Text: (Required)"
  elseif elem.type == "slider" then
    valLabel = "Slider Label (Optional):"
  elseif elem.type == "combobox" then
    valLabel = "ComboBox Label (Optional):"
  end

  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "fill",
      fillViewport = true,
      {
        LinearLayout,
        id = "edit_elem_container",
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Edit Element #" .. tostring(elemIndex) .. " (" .. elem.type .. ")",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
      }
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  local edt_val = nil
  if not isTitle and not isToggle then
    local tLbl = TextView(service)
    tLbl.setText(valLabel)
    tLbl.setTextColor(Color.LTGRAY)
    edit_elem_container.addView(tLbl)

    edt_val = EditText(service)
    local initialVal = (elem.type == "button" or elem.type == "clickable" or elem.type == "checkbox" or elem.type == "slider" or elem.type == "linkbutton" or elem.type == "combobox") and elem.label or (elem.type == "edittext" and elem.hint or elem.text)
    edt_val.setText(tostring(initialVal or ""))
    edt_val.setTextColor(Color.WHITE)
    edit_elem_container.addView(edt_val)
  end

  local edt_target = nil
  if elem.type == "button" or elem.type == "clickable" then
    local existingList = "Available Windows in Project:\n"
    if #project.windows == 0 then
      existingList = existingList .. "(None yet)\n"
    else
      for _, w in ipairs(project.windows) do
        existingList = existingList .. "ID " .. tostring(w.id) .. ": " .. tostring(w.title) .. "\n"
      end
    end
    existingList = existingList .. "(Type 0 for System Back action)"

    local winListLbl = TextView(service)
    winListLbl.setText(existingList)
    winListLbl.setTextColor(Color.GREEN)
    winListLbl.setTextSize(12)
    edit_elem_container.addView(winListLbl)

    local tLabel = TextView(service)
    tLabel.setText("Target Window ID (Optional, 0 for Back):")
    tLabel.setTextColor(Color.LTGRAY)
    edit_elem_container.addView(tLabel)

    edt_target = EditText(service)
    edt_target.setText(elem.targetId and tostring(elem.targetId) or "")
    edt_target.setTextColor(Color.WHITE)
    edt_target.setInputType(InputType.TYPE_CLASS_NUMBER)
    edit_elem_container.addView(edt_target)
  end

  local edt_url = nil
  if elem.type == "linkbutton" then
    local uLbl = TextView(service)
    uLbl.setText("Link / URL: (Required)")
    uLbl.setTextColor(Color.LTGRAY)
    edit_elem_container.addView(uLbl)

    edt_url = EditText(service)
    edt_url.setText(tostring(elem.url or ""))
    edt_url.setTextColor(Color.WHITE)
    edit_elem_container.addView(edt_url)
  end

  local edt_options = nil
  if elem.type == "combobox" or elem.type == "togglebutton" then
    local oLbl = TextView(service)
    oLbl.setText("Options (Comma Separated): (Required)")
    oLbl.setTextColor(Color.LTGRAY)
    edit_elem_container.addView(oLbl)

    edt_options = EditText(service)
    edt_options.setText(tostring(elem.options or ""))
    edt_options.setTextColor(Color.WHITE)
    edit_elem_container.addView(edt_options)
  end

  local btn_update = nil
  if not isTitle then
    btn_update = Button(service)
    btn_update.setText("Update Element")
    btn_update.setOnClickListener(function()
      if edt_val then
        local valStr = edt_val.getText().toString()
        if valStr == "" and elem.type ~= "slider" and elem.type ~= "edittext" and elem.type ~= "combobox" and elem.type ~= "checkbox" then valStr = "Element" end
        if elem.type == "button" or elem.type == "clickable" then
          elem.label = valStr
          local targetStr = edt_target and edt_target.getText().toString() or ""
          elem.targetId = tonumber(targetStr)
        elseif elem.type == "edittext" then
          elem.hint = valStr
        elseif elem.type == "checkbox" or elem.type == "slider" then
          elem.label = valStr
        elseif elem.type == "combobox" then
          elem.label = valStr
          if edt_options then
            elem.options = edt_options.getText().toString()
          end
        elseif elem.type == "textview" then
          elem.text = valStr
        elseif elem.type == "linkbutton" then
          elem.label = valStr
          if edt_url then
            local uStr = edt_url.getText().toString()
            if uStr == "" then uStr = "https://" end
            elem.url = uStr
          end
        end
      elseif elem.type == "togglebutton" then
        if edt_options then
          elem.options = edt_options.getText().toString()
        end
      end
      showToast("Element updated!")
      if #historyStack > 0 then
        local prev = table.remove(historyStack)
        prev.func()
      end
    end)
    edit_elem_container.addView(btn_update)
  end

  local btn_change_type = Button(service)
  btn_change_type.setText("Change Element Type")
  btn_change_type.setOnClickListener(function()
    table.insert(historyStack, {func = function() renderEditElement(project, tempWindow, elemIndex) end})
    renderChangeElementTypeMenu(project, tempWindow, elemIndex)
  end)
  edit_elem_container.addView(btn_change_type)

  if not isTitle and btn_update then
    local validateEditElem = function()
      local valStr = edt_val and tostring(edt_val.getText()):match("^%s*(.-)%s*$") or ""
      if elem.type == "slider" or elem.type == "edittext" or elem.type == "checkbox" then
        btn_update.setEnabled(true)
      elseif elem.type == "combobox" or elem.type == "togglebutton" then
        local oStr = edt_options and tostring(edt_options.getText()):match("^%s*(.-)%s*$") or ""
        btn_update.setEnabled(oStr ~= "")
      elseif elem.type == "linkbutton" then
        local uStr = edt_url and tostring(edt_url.getText()):match("^%s*(.-)%s*$") or ""
        btn_update.setEnabled(valStr ~= "" and uStr ~= "")
      else
        btn_update.setEnabled(valStr ~= "")
      end
    end

    if edt_val then
      edt_val.addTextChangedListener({
        onTextChanged = function() validateEditElem() end,
        beforeTextChanged = function() end,
        afterTextChanged = function() end
      })
    end
    if edt_url then
      edt_url.addTextChangedListener({
        onTextChanged = function() validateEditElem() end,
        beforeTextChanged = function() end,
        afterTextChanged = function() end
      })
    end
    if edt_options then
      edt_options.addTextChangedListener({
        onTextChanged = function() validateEditElem() end,
        beforeTextChanged = function() end,
        afterTextChanged = function() end
      })
    end
    validateEditElem()
  end

  if elemIndex > 1 then
    local btn_move_up = Button(service)
    btn_move_up.setText("Move Up")
    btn_move_up.setOnClickListener(function()
      local temp = tempWindow.elements[elemIndex]
      tempWindow.elements[elemIndex] = tempWindow.elements[elemIndex - 1]
      tempWindow.elements[elemIndex - 1] = temp
      showToast("Moved up!")
      if #historyStack > 0 then
        local prev = table.remove(historyStack)
        prev.func()
      end
    end)
    edit_elem_container.addView(btn_move_up)
  end

  if elemIndex < #tempWindow.elements then
    local btn_move_down = Button(service)
    btn_move_down.setText("Move Down")
    btn_move_down.setOnClickListener(function()
      local temp = tempWindow.elements[elemIndex]
      tempWindow.elements[elemIndex] = tempWindow.elements[elemIndex + 1]
      tempWindow.elements[elemIndex + 1] = temp
      showToast("Moved down!")
      if #historyStack > 0 then
        local prev = table.remove(historyStack)
        prev.func()
      end
    end)
    edit_elem_container.addView(btn_move_down)
  end

  local btn_delete_elem = Button(service)
  btn_delete_elem.setText("Delete Element")
  btn_delete_elem.setOnClickListener(function()
    local confirmLayout = {
      LinearLayout,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "fill",
      backgroundColor = Color.parseColor("#121212"),
      padding = "16dp",
      {
        ScrollView,
        layout_width = "fill",
        layout_height = "fill",
        fillViewport = true,
        {
          LinearLayout,
          orientation = "vertical",
          layout_width = "fill",
          layout_height = "wrap",
          {
            TextView,
            text = "Confirm Deletion",
            textSize = "20sp",
            textColor = Color.WHITE,
            padding = "10dp",
          },
          {
            TextView,
            text = "Are you sure you want to delete this element?",
            textColor = Color.LTGRAY,
            padding = "10dp",
          },
          {
            Button,
            id = "btn_confirm_del",
            text = "Yes, Delete",
            layout_width = "fill",
          },
          {
            Button,
            id = "btn_cancel_del",
            text = "Cancel",
            layout_width = "fill",
          },
        }
      }
    }
    table.insert(historyStack, {func = function() renderEditElement(project, tempWindow, elemIndex) end})
    if dlg then dlg.dismiss() end
    dlg = LuaDialog(service)
    dlg.View = loadlayout(confirmLayout)

    btn_confirm_del.setOnClickListener(function()
      table.remove(tempWindow.elements, elemIndex)
      showToast("Element deleted!")
      table.remove(historyStack)
      if #historyStack > 0 then
        local prev = table.remove(historyStack)
        prev.func()
      end
    end)

    btn_cancel_del.setOnClickListener(function()
      if #historyStack > 0 then
        local prev = table.remove(historyStack)
        prev.func()
      end
    end)

    dlg.setOnKeyListener(DialogInterface.OnKeyListener{
      onKey = function(dialog, keyCode, event)
        if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
          if #historyStack > 0 then
            local prev = table.remove(historyStack)
            prev.func()
            return true
          end
        end
        return false
      end
    })
    dlg.show()
  end)
  edit_elem_container.addView(btn_delete_elem)

  local btn_cancel = Button(service)
  btn_cancel.setText("Cancel")
  btn_cancel.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)
  edit_elem_container.addView(btn_cancel)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderManageWindows = function(project)
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "0dp",
      layout_weight = 1,
      fillViewport = true,
      {
        LinearLayout,
        id = "manage_container",
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Manage Windows",
          textSize = "20sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
      }
    },
    {
      Button,
      id = "btn_manage_back",
      text = "Back to Project Dashboard",
      layout_width = "fill",
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  if #project.windows == 0 then
    local emptyTxt = TextView(service)
    emptyTxt.setText("No windows created yet.")
    emptyTxt.setTextColor(Color.GRAY)
    manage_container.addView(emptyTxt)
  else
    for _, win in ipairs(project.windows) do
      local winBtn = Button(service)
      winBtn.setText("ID " .. tostring(win.id) .. ": " .. tostring(win.title) .. " (" .. tostring(#win.elements) .. " items)")
      winBtn.setOnClickListener(function()
        table.insert(historyStack, {func = function() renderManageWindows(project) end})
        renderEditWindow(project, win)
      end)
      manage_container.addView(winBtn)
    end
  end

  btn_manage_back.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    else
      renderProjectDashboard(project)
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderEditWindow = function(project, win)
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#1C1C1E"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "0dp",
      layout_weight = 1,
      fillViewport = true,
      {
        LinearLayout,
        id = "edit_win_container",
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Edit Window ID " .. tostring(win.id),
          textSize = "18sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "Window Title: (Required)",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_edit_title",
          text = win.title,
          textColor = Color.WHITE,
          layout_width = "fill",
        },
        {
          TextView,
          text = "Elements (Click any to edit/move):",
          textColor = Color.GREEN,
          padding = "10dp",
        },
      }
    },
    {
      LinearLayout,
      id = "edit_bottom_layout",
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "wrap",
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  if #win.elements == 0 then
    local emptyElem = TextView(service)
    emptyElem.setText("No elements added yet.")
    emptyElem.setTextColor(Color.GRAY)
    edit_win_container.addView(emptyElem)
  else
    for index, elem in ipairs(win.elements) do
      local eBtn = Button(service)
      if elem.type == "title" then
        eBtn.setText(tostring(index) .. ". [Window Title] (Title Bar)")
      elseif elem.type == "button" then
        local targetInfo = elem.targetId and (" -> Target: ID " .. tostring(elem.targetId)) or ""
        eBtn.setText(tostring(index) .. ". [Button] " .. tostring(elem.label) .. targetInfo)
      elseif elem.type == "clickable" then
        local targetInfo = elem.targetId and (" -> Target: ID " .. tostring(elem.targetId)) or ""
        eBtn.setText(tostring(index) .. ". [Clickable] " .. tostring(elem.label) .. targetInfo)
      elseif elem.type == "edittext" then
        eBtn.setText(tostring(index) .. ". [Input] " .. tostring(elem.hint))
      elseif elem.type == "checkbox" then
        eBtn.setText(tostring(index) .. ". [Checkbox] " .. tostring(elem.label))
      elseif elem.type == "textview" then
        eBtn.setText(tostring(index) .. ". [Text] " .. tostring(elem.text))
      elseif elem.type == "slider" then
        eBtn.setText(tostring(index) .. ". [Slider] " .. tostring(elem.label or "SeekBar"))
      elseif elem.type == "linkbutton" then
        eBtn.setText(tostring(index) .. ". [Link Button] " .. tostring(elem.label) .. " (" .. tostring(elem.url) .. ")")
      elseif elem.type == "combobox" then
        eBtn.setText(tostring(index) .. ". [ComboBox] " .. tostring((elem.label and elem.label ~= "") and elem.label or "ComboBox") .. " (" .. tostring(elem.options or "") .. ")")
      elseif elem.type == "togglebutton" then
        eBtn.setText(tostring(index) .. ". [Toggle Button] (" .. tostring(elem.options or "") .. ")")
      end
      eBtn.setOnClickListener(function()
        win.title = edt_edit_title.getText().toString()
        saveData()
        table.insert(historyStack, {func = function() renderEditWindow(project, win) end})
        renderEditElement(project, win, index)
      end)
      edit_win_container.addView(eBtn)
    end
  end

  local btn_edit_add_item = Button(service)
  btn_edit_add_item.setText("Add New Item")
  btn_edit_add_item.setOnClickListener(function()
    win.title = edt_edit_title.getText().toString()
    saveData()
    table.insert(historyStack, {func = function() renderEditWindow(project, win) end})
    renderAddElementMenu(project, win)
  end)
  edit_bottom_layout.addView(btn_edit_add_item)

  local btn_edit_test = Button(service)
  btn_edit_test.setText("Test This Window")
  btn_edit_test.setOnClickListener(function()
    win.title = edt_edit_title.getText().toString()
    saveData()
    table.insert(historyStack, {func = function() renderEditWindow(project, win) end})
    renderLiveTest(project, win)
  end)
  edit_bottom_layout.addView(btn_edit_test)

  local btn_edit_save = Button(service)
  btn_edit_save.setText("Save Changes")
  btn_edit_save.setOnClickListener(function()
    win.title = edt_edit_title.getText().toString()
    saveData()
    showToast("Window Updated!")
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)
  edit_bottom_layout.addView(btn_edit_save)

  local btn_edit_delete = Button(service)
  btn_edit_delete.setText("Delete Window")
  btn_edit_delete.setOnClickListener(function()
    local confirmLayout = {
      LinearLayout,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "fill",
      backgroundColor = Color.parseColor("#121212"),
      padding = "16dp",
      {
        ScrollView,
        layout_width = "fill",
        layout_height = "fill",
        fillViewport = true,
        {
          LinearLayout,
          orientation = "vertical",
          layout_width = "fill",
          layout_height = "wrap",
          {
            TextView,
            text = "Confirm Deletion",
            textSize = "20sp",
            textColor = Color.WHITE,
            padding = "10dp",
          },
          {
            TextView,
            text = "Are you sure you want to delete Window ID " .. tostring(win.id) .. " (" .. tostring(win.title) .. ")?",
            textColor = Color.LTGRAY,
            padding = "10dp",
          },
          {
            Button,
            id = "btn_confirm_del",
            text = "Yes, Delete",
            layout_width = "fill",
          },
          {
            Button,
            id = "btn_cancel_del",
            text = "Cancel",
            layout_width = "fill",
          },
        }
      }
    }
    table.insert(historyStack, {func = function() renderEditWindow(project, win) end})
    if dlg then dlg.dismiss() end
    dlg = LuaDialog(service)
    dlg.View = loadlayout(confirmLayout)

    btn_confirm_del.setOnClickListener(function()
      for i, w in ipairs(project.windows) do
        if w.id == win.id then
          table.remove(project.windows, i)
          break
        end
      end
      saveData()
      showToast("Window Deleted!")
      table.remove(historyStack)
      if #historyStack > 0 then
        local prev = table.remove(historyStack)
        prev.func()
      end
    end)

    btn_cancel_del.setOnClickListener(function()
      if #historyStack > 0 then
        local prev = table.remove(historyStack)
        prev.func()
      end
    end)

    dlg.setOnKeyListener(DialogInterface.OnKeyListener{
      onKey = function(dialog, keyCode, event)
        if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
          if #historyStack > 0 then
            local prev = table.remove(historyStack)
            prev.func()
            return true
          end
        end
        return false
      end
    })
    dlg.show()
  end)
  edit_bottom_layout.addView(btn_edit_delete)

  local btn_edit_back = Button(service)
  btn_edit_back.setText("Back")
  btn_edit_back.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)
  edit_bottom_layout.addView(btn_edit_back)

  local validateEditWinTitle = function()
    local tText = tostring(edt_edit_title.getText()):match("^%s*(.-)%s*$")
    local isValid = (tText ~= "")
    btn_edit_test.setEnabled(isValid)
    btn_edit_save.setEnabled(isValid)
  end
  edt_edit_title.addTextChangedListener({
    onTextChanged = function() validateEditWinTitle() end,
    beforeTextChanged = function() end,
    afterTextChanged = function() end
  })
  validateEditWinTitle()

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
          return true
        end
      end
      return false
    end
  })
  dlg.show()
end

renderExportCode = function(project)
  local generatedCodeText = generateLuaCode(project)
  local layout = {
    LinearLayout,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = Color.parseColor("#121212"),
    padding = "16dp",
    {
      ScrollView,
      layout_width = "fill",
      layout_height = "0dp",
      layout_weight = 1,
      fillViewport = true,
      {
        LinearLayout,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "Generated AndroLua Code:",
          textSize = "18sp",
          textColor = Color.GREEN,
          padding = "10dp",
        },
        {
          EditText,
          id = "edt_code_output",
          text = generatedCodeText,
          textColor = Color.WHITE,
          textSize = "12sp",
          layout_width = "fill",
        },
      }
    },
    {
      Button,
      id = "btn_copy",
      text = "Copy Code to Clipboard",
      layout_width = "fill",
    },
    {
      Button,
      id = "btn_back",
      text = "Back",
      layout_width = "fill",
    }
  }

  if dlg then dlg.dismiss() end
  dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  btn_copy.setOnClickListener(function()
    copyToClipboard(edt_code_output.getText().toString())
  end)

  btn_back.setOnClickListener(function()
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    else
      renderProjectDashboard(project)
    end
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
        end
      end
      return false
    end
  })
  dlg.show()
end

updater.checkUpdate(function()
  renderMainMenu()
end)
