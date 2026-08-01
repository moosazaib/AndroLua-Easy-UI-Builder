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
    return "-- No windows defined."
  end
  local code = 'require "import"\nimport "android.widget.*"\nimport "android.view.*"\nimport "android.graphics.Color"\nimport "android.content.DialogInterface"\n\n'
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
  code = code .. '        else\n'
  code = code .. '          Toast.makeText(service, "Clicked: " .. elem.label, Toast.LENGTH_SHORT).show()\n'
  code = code .. '          service.speak("Clicked: " .. elem.label)\n'
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
  code = code .. '        else\n'
  code = code .. '          Toast.makeText(service, "Clicked: " .. elem.label, Toast.LENGTH_SHORT).show()\n'
  code = code .. '          service.speak("Clicked: " .. elem.label)\n'
  code = code .. '        end\n'
  code = code .. '      end)\n'
  code = code .. '      container.addView(l)\n'
  code = code .. '    elseif elem.type == "edittext" then\n'
  code = code .. '      local e = EditText(service)\n'
  code = code .. '      e.setHint(elem.hint)\n'
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

local renderMainMenu, renderSavedProjectsList, renderProjectDashboard, renderCreateWindow, renderAddButton, renderAddClickable, renderAddEditText, renderAddCheckBox, renderAddTextView, renderAddTitle, renderEditElement, renderManageWindows, renderEditWindow, renderExportCode, renderLiveTest, renderCreateProjectDialog

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
      e.setHint(elem.hint)
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
          text = "Project Name:",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_new_proj_name",
          hint = "Enter project name",
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
      if text == "" then
        btn_do_create.setEnabled(false)
      else
        btn_do_create.setEnabled(true)
      end
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
          text = "Project Name:",
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
      table.remove(historyStack)
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
    renderSavedProjectsList()
  end)

  dlg.setOnKeyListener(DialogInterface.OnKeyListener{
    onKey = function(dialog, keyCode, event)
      if keyCode == KeyEvent.KEYCODE_BACK and event.getAction() == KeyEvent.ACTION_UP then
        renderSavedProjectsList()
        return true
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
          text = "Window Title:",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_title",
          text = tempWindow.title or "",
          hint = "Enter Window Title",
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
      end
      eBtn.setOnClickListener(function()
        tempWindow.title = edt_title.getText().toString()
        table.insert(historyStack, {func = function() renderCreateWindow(project, tempWindow) end})
        renderEditElement(project, tempWindow, index)
      end)
      create_win_container.addView(eBtn)
    end
  end

  local hasTitle = false
  for _, elem in ipairs(tempWindow.elements) do
    if elem.type == "title" then
      hasTitle = true
      break
    end
  end

  if not hasTitle then
    local btn_add_title = Button(service)
    btn_add_title.setText("Add Window Title Element")
    btn_add_title.setOnClickListener(function()
      tempWindow.title = edt_title.getText().toString()
      table.insert(historyStack, {func = function() renderCreateWindow(project, tempWindow) end})
      renderAddTitle(project, tempWindow)
    end)
    create_bottom_layout.addView(btn_add_title)
  end

  local btn_add_btn = Button(service)
  btn_add_btn.setText("Add Button")
  btn_add_btn.setOnClickListener(function()
    tempWindow.title = edt_title.getText().toString()
    table.insert(historyStack, {func = function() renderCreateWindow(project, tempWindow) end})
    renderAddButton(project, tempWindow)
  end)
  create_bottom_layout.addView(btn_add_btn)

  local btn_add_clk = Button(service)
  btn_add_clk.setText("Add Clickable Item")
  btn_add_clk.setOnClickListener(function()
    tempWindow.title = edt_title.getText().toString()
    table.insert(historyStack, {func = function() renderCreateWindow(project, tempWindow) end})
    renderAddClickable(project, tempWindow)
  end)
  create_bottom_layout.addView(btn_add_clk)

  local btn_add_edt = Button(service)
  btn_add_edt.setText("Add Input Box")
  btn_add_edt.setOnClickListener(function()
    tempWindow.title = edt_title.getText().toString()
    table.insert(historyStack, {func = function() renderCreateWindow(project, tempWindow) end})
    renderAddEditText(project, tempWindow)
  end)
  create_bottom_layout.addView(btn_add_edt)

  local btn_add_chk = Button(service)
  btn_add_chk.setText("Add CheckBox")
  btn_add_chk.setOnClickListener(function()
    tempWindow.title = edt_title.getText().toString()
    table.insert(historyStack, {func = function() renderCreateWindow(project, tempWindow) end})
    renderAddCheckBox(project, tempWindow)
  end)
  create_bottom_layout.addView(btn_add_chk)

  local btn_add_txt = Button(service)
  btn_add_txt.setText("Add TextView")
  btn_add_txt.setOnClickListener(function()
    tempWindow.title = edt_title.getText().toString()
    table.insert(historyStack, {func = function() renderCreateWindow(project, tempWindow) end})
    renderAddTextView(project, tempWindow)
  end)
  create_bottom_layout.addView(btn_add_txt)

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

renderAddTitle = function(project, tempWindow)
  table.insert(tempWindow.elements, {
    type = "title"
  })
  showToast("Window Title element added!")
  if #historyStack > 0 then
    local prev = table.remove(historyStack)
    prev.func()
  end
end

renderAddButton = function(project, tempWindow)
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
          text = "Button Label:",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_label",
          hint = "Click Me",
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
          text = "Target Window ID (Leave empty for simple toast, 0 for Back):",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_target",
          hint = "e.g. 1, 2... or 0",
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

  btn_confirm.setOnClickListener(function()
    local text = edt_label.getText().toString()
    if text == "" then text = "Button" end
    local targetStr = edt_target.getText().toString()
    local targetIdNum = tonumber(targetStr)
    table.insert(tempWindow.elements, {
      type = "button",
      label = text,
      targetId = targetIdNum
    })
    showToast("Button added!")
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

renderAddClickable = function(project, tempWindow)
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
          text = "Display Label:",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_label",
          hint = "Clickable Item",
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
          text = "Target Window ID (Leave empty for simple toast, 0 for Back):",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_target",
          hint = "e.g. 1, 2... or 0",
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

  btn_confirm.setOnClickListener(function()
    local text = edt_label.getText().toString()
    if text == "" then text = "Clickable" end
    local targetStr = edt_target.getText().toString()
    local targetIdNum = tonumber(targetStr)
    table.insert(tempWindow.elements, {
      type = "clickable",
      label = text,
      targetId = targetIdNum
    })
    showToast("Clickable item added!")
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

renderAddEditText = function(project, tempWindow)
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
          text = "Hint Text:",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_hint",
          hint = "Enter text...",
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
    local hintText = edt_hint.getText().toString()
    if hintText == "" then hintText = "Enter value" end
    table.insert(tempWindow.elements, {
      type = "edittext",
      hint = hintText
    })
    showToast("Input box added!")
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

renderAddCheckBox = function(project, tempWindow)
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
          text = "CheckBox Label:",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_label",
          hint = "Accept terms",
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
    if text == "" then text = "CheckBox" end
    table.insert(tempWindow.elements, {
      type = "checkbox",
      label = text
    })
    showToast("CheckBox added!")
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

renderAddTextView = function(project, tempWindow)
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
          text = "Display Text:",
          textColor = Color.LTGRAY,
        },
        {
          EditText,
          id = "edt_text",
          hint = "Hello World",
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
    local text = edt_text.getText().toString()
    if text == "" then text = "Text" end
    table.insert(tempWindow.elements, {
      type = "textview",
      text = text
    })
    showToast("TextView added!")
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
  local valLabel = "Label/Text:"
  if elem.type == "edittext" then valLabel = "Hint Text:" end

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
  if not isTitle then
    local tLbl = TextView(service)
    tLbl.setText(valLabel)
    tLbl.setTextColor(Color.LTGRAY)
    edit_elem_container.addView(tLbl)

    edt_val = EditText(service)
    local initialVal = (elem.type == "button" or elem.type == "clickable") and elem.label or (elem.type == "edittext" and elem.hint or (elem.type == "checkbox" and elem.label or elem.text))
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
    tLabel.setText("Target Window ID (Leave empty for simple toast, 0 for Back):")
    tLabel.setTextColor(Color.LTGRAY)
    edit_elem_container.addView(tLabel)

    edt_target = EditText(service)
    edt_target.setText(elem.targetId and tostring(elem.targetId) or "")
    edt_target.setHint("e.g. 1, 2... or 0")
    edt_target.setTextColor(Color.WHITE)
    edt_target.setInputType(InputType.TYPE_CLASS_NUMBER)
    edit_elem_container.addView(edt_target)
  end

  local btn_update = Button(service)
  btn_update.setText("Update Element")
  btn_update.setOnClickListener(function()
    if not isTitle and edt_val then
      local valStr = edt_val.getText().toString()
      if valStr == "" then valStr = "Element" end
      if elem.type == "button" or elem.type == "clickable" then
        elem.label = valStr
        local targetStr = edt_target and edt_target.getText().toString() or ""
        elem.targetId = tonumber(targetStr)
      elseif elem.type == "edittext" then
        elem.hint = valStr
      elseif elem.type == "checkbox" then
        elem.label = valStr
      elseif elem.type == "textview" then
        elem.text = valStr
      end
    elseif isTitle and (elem.type == "button" or elem.type == "clickable") then
      local targetStr = edt_target and edt_target.getText().toString() or ""
      elem.targetId = tonumber(targetStr)
    end
    showToast("Element updated!")
    if #historyStack > 0 then
      local prev = table.remove(historyStack)
      prev.func()
    end
  end)
  edit_elem_container.addView(btn_update)

  if elemIndex > 1 then
    local btn_move_up = Button(service)
    btn_move_up.setText("Move Up ⬆️")
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
    btn_move_down.setText("Move Down ⬇️")
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
          text = "Window Title:",
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

  local hasTitle = false
  for _, elem in ipairs(win.elements) do
    if elem.type == "title" then
      hasTitle = true
      break
    end
  end

  if not hasTitle then
    local btn_edit_add_title = Button(service)
    btn_edit_add_title.setText("Add Window Title Element")
    btn_edit_add_title.setOnClickListener(function()
      win.title = edt_edit_title.getText().toString()
      saveData()
      table.insert(historyStack, {func = function() renderEditWindow(project, win) end})
      renderAddTitle(project, win)
    end)
    edit_bottom_layout.addView(btn_edit_add_title)
  end

  local btn_edit_add_btn = Button(service)
  btn_edit_add_btn.setText("Add Button")
  btn_edit_add_btn.setOnClickListener(function()
    win.title = edt_edit_title.getText().toString()
    saveData()
    table.insert(historyStack, {func = function() renderEditWindow(project, win) end})
    renderAddButton(project, win)
  end)
  edit_bottom_layout.addView(btn_edit_add_btn)

  local btn_edit_add_clk = Button(service)
  btn_edit_add_clk.setText("Add Clickable Item")
  btn_edit_add_clk.setOnClickListener(function()
    win.title = edt_edit_title.getText().toString()
    saveData()
    table.insert(historyStack, {func = function() renderEditWindow(project, win) end})
    renderAddClickable(project, win)
  end)
  edit_bottom_layout.addView(btn_edit_add_clk)

  local btn_edit_add_edt = Button(service)
  btn_edit_add_edt.setText("Add Input Box")
  btn_edit_add_edt.setOnClickListener(function()
    win.title = edt_edit_title.getText().toString()
    saveData()
    table.insert(historyStack, {func = function() renderEditWindow(project, win) end})
    renderAddEditText(project, win)
  end)
  edit_bottom_layout.addView(btn_edit_add_edt)

  local btn_edit_add_chk = Button(service)
  btn_edit_add_chk.setText("Add CheckBox")
  btn_edit_add_chk.setOnClickListener(function()
    win.title = edt_edit_title.getText().toString()
    saveData()
    table.insert(historyStack, {func = function() renderEditWindow(project, win) end})
    renderAddCheckBox(project, win)
  end)
  edit_bottom_layout.addView(btn_edit_add_chk)

  local btn_edit_add_txt = Button(service)
  btn_edit_add_txt.setText("Add TextView")
  btn_edit_add_txt.setOnClickListener(function()
    win.title = edt_edit_title.getText().toString()
    saveData()
    table.insert(historyStack, {func = function() renderEditWindow(project, win) end})
    renderAddTextView(project, win)
  end)
  edit_bottom_layout.addView(btn_edit_add_txt)

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
