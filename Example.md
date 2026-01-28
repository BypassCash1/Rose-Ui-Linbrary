# Rose UI Library

Load the library using the raw URL:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/coolk/Rose-ui-lib/main/ui.lua"))()
```

## Usage

### Creating a Window

```lua
local Window = Rose:CreateWindow({
    Title = "My Script",
    Name = "MyScript",
    Size = UDim2.new(0, 550, 0, 500)
})
```

### Adding Tabs

```lua
local Tab1 = Window:CreateTab("Main")
local Tab2 = Window:CreateTab("Settings")
```

### Adding Sections

```lua
local Section1 = Tab1:column():section("Features")
local Section2 = Tab1:column():section("Options")
```

### Adding Elements

#### Toggle

```lua
Section1:AddToggle({
    Name = "Enable Feature",
    Default = false,
    Callback = function(value)
        print("Toggle:", value)
    end
})
```

#### Button

```lua
Section1:AddButton({
    Name = "Click Me",
    Callback = function()
        print("Button clicked!")
    end
})
```

#### Dropdown

```lua
Section1:AddDropdown({
    Name = "Select Option",
    Options = {"Option 1", "Option 2", "Option 3"},
    Default = "Option 1",
    Callback = function(selected)
        print("Selected:", selected)
    end
})
```

#### TextBox

```lua
Section1:AddTextBox({
    Name = "Enter Text",
    Placeholder = "Type here...",
    Callback = function(text)
        print("Text entered:", text)
    end
})
```

#### Slider

```lua
Section1:AddSlider({
    Name = "Volume",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(value)
        print("Slider value:", value)
    end
})
```

#### Color Picker

```lua
Section1:AddColorPicker({
    Name = "Choose Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        print("Color selected:", color)
    end
})
```
