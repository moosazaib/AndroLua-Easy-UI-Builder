import "android.widget.*"
import "android.view.*"
import "android.content.Intent"
import "android.net.Uri"
import "android.graphics.Color"
import "android.content.DialogInterface"

local M = {}

M.renderAbout = function(service, historyStack, currentDlg, showToast, renderMainMenu)
  if currentDlg then currentDlg.dismiss() end
  
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
        id = "about_container",
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        {
          TextView,
          text = "About Us",
          textSize = "22sp",
          textColor = Color.WHITE,
          padding = "10dp",
        },
        {
          TextView,
          text = "Developed by Moosa Zaib",
          textSize = "16sp",
          textColor = Color.GREEN,
          padding = "5dp",
        },
        {
          Button,
          id = "btn_contact_moosa",
          text = "Contact Moosa Zaib",
          layout_width = "fill",
        },
        {
          TextView,
          text = "Comprehensive Guide & Complete Documentation",
          textSize = "18sp",
          textColor = Color.YELLOW,
          padding = "10dp",
        },
        {
          TextView,
          text = "Welcome to the AndroLua Easy UI Builder, your ultimate mobile companion designed by Moosa Zaib to make Android app development completely effortless right on your phone. If you are tired of wrestling with complex XML layout files, heavy PC IDEs, and messy Java boilerplate, this tool is your magic wand. It lets you visually design, configure, test, and export multi-window Android apps entirely using Lua and AndroLua, step by step, without needing any complicated setup.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "Important Note on UI vs. App Logic: This builder is specifically crafted to handle your app's visual User Interface (UI), multi-window structure, layout hierarchy, and navigation flow completely. However, the custom functional logic for your app needs to be added by you. Since designing manual UI layouts and XML code on mobile is a massive headache, this tool saves you from that trouble by letting you choose and build your dream UI instantly; once your UI and navigation structure are exported, you can easily use an AI to write the specific backend logic or code it yourself!",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "1. Complete Project Management: The builder allows you to create and manage multiple isolated projects right from your device storage. Each project is its own independent universe with its own unique collection of windows, element lists, and IDs. Whenever you make changes, everything is automatically serialized and saved locally to your device storage (csr_multiproject_data.lua), ensuring you never lose your hard work even if the app closes unexpectedly.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "How to use Project Management: From the main menu, tap 'Create New Project', type in a unique project name in the input box, and hit create. Your project is instantly saved. You can then tap 'Saved Projects' from the main menu to view all your creations, open any project dashboard, rename your project whenever you want, or delete obsolete projects with a built-in confirmation safety prompt so you don't accidentally wipe your masterpieces.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "2. Advanced Multi-Window Architecture: Real-world apps aren't single-screen wonders; they have multiple flows and screens. This builder gives you full control over multi-window navigation. Every project consists of one or more windows, starting automatically with Window #1 which serves as your main entry point or launcher screen.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "How to manage windows: Inside your project dashboard, tap 'Create New Window' to add secondary screens. You can customize each window's title, add unique elements, and manage all your windows using the 'Manage Windows' section where you can view every window ID, edit titles, rearrange content, test specific windows, or delete windows you no longer need.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "3. Rich Interactive UI Elements: Building a screen is super intuitive and visual. You can stack various native Android components into your windows with just a few taps. Each element serves a distinct purpose in your layout hierarchy:",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "- Window Title Bar: Displays the title of your current window at the top with clean, professional padding and styling.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "- Buttons: Standard interactive buttons where you can set custom labels and assign a Target Window ID so tapping it navigates smoothly to another screen, or set Target ID to 0 for a system back action.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "- Clickable Containers: Custom interactive layout boxes that act like list items or cards, fully clickable with text labels and navigation targets.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "- Input Boxes (EditText): Text fields allowing users to type input, complete with custom hint texts and proper text coloring.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "- CheckBoxes: Toggle options for settings, agreements, or choices with customizable text labels.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "- Static TextViews: Informational text blocks to display descriptions, headers, or notes anywhere on your screen.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "- Sliders (SeekBar): Interactive range sliders with customizable labels allowing users to adjust numerical values or settings smoothly.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "- Link Buttons: Action buttons configured with external web URLs that launch your default browser to open any link directly when tapped.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "How to edit elements: When creating or editing a window, every added element is listed with its index number. Tap any element in the list to open the element editor. From there, you can update its text or hint, change its target navigation ID, move it Up or Down in the layout order instantly with dedicated move buttons, or delete it if it's no longer needed.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "4. Navigation, Back Stack & Hardware Key Mapping: Navigation is fully automated by the builder's code generator. When you tap a button linking to another window, the screen transitions seamlessly while keeping track of history.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "Hardware Back Button Support: Both during live testing inside the builder and in your exported standalone app, the physical Android back button is fully mapped. It automatically pops the history stack to return to the previous screen naturally, exactly like a professional, production-grade Android application.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "5. Live Testing & Production Code Export: Why wait till the end to see if your design works? The builder features powerful real-time testing capabilities. Tap 'Test Project' on your dashboard to run your entire app flow starting from Window #1, or tap 'Test This Window' during editing to instantly preview how a single screen looks and behaves.",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
        {
          TextView,
          text = "Exporting your app: When your design is complete, tap 'Generate & Export Lua Code' on your project dashboard. The system compiles your entire multi-window layout hierarchy, navigation stack, and event handlers into a clean, standalone, production-ready AndroLua source code file. You can view the code right in the built-in editor and tap 'Copy Code to Clipboard' with a single click to paste it into your AndroLua workspace and run it as an independent app!",
          textColor = Color.LTGRAY,
          textSize = "14sp",
          padding = "5dp",
        },
      }
    },
    {
      Button,
      id = "btn_about_back",
      text = "Back to Main Menu",
      layout_width = "fill",
    }
  }

  local dlg = LuaDialog(service)
  dlg.View = loadlayout(layout)

  btn_contact_moosa.setOnClickListener(function()
    if dlg then dlg.dismiss() end
    historyStack = {}
    pcall(function()
      service.speak("Opening WhatsApp")
      local uri = Uri.parse("https://wa.me/923123608972")
      local intent = Intent(Intent.ACTION_VIEW, uri)
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      service.startActivity(intent)
    end)
  end)

  btn_about_back.setOnClickListener(function()
    if dlg then dlg.dismiss() end
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
        if dlg then dlg.dismiss() end
        if #historyStack > 0 then
          local prev = table.remove(historyStack)
          prev.func()
        else
          renderMainMenu()
        end
        return true
      end
      return false
    end
  })
  dlg.show()
  return dlg
end

return M