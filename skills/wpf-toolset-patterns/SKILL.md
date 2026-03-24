---
name: wpf-toolset-patterns
description: "Use when building game toolsets or editors in WPF — MVVM, data binding, asset editors, property inspectors, undo/redo, file I/O, and WPF-to-Godot data bridge patterns."
---

# WPF Toolset Patterns

Patterns for building game editors and toolsets in WPF on .NET 8/9.

For full code implementations, see `resources/implementation-playbook.md`.

---

## 1. WPF vs Godot Editor Plugin — Which to Build

| Build in WPF when | Build as Godot Editor Plugin when |
|---|---|
| Standalone tool used outside the game | Tool is purely game-data-centric |
| Tight .NET/Windows integration needed | Tool only makes sense inside the editor |
| Tool shares logic with a C# game server or other .NET system | Quick inspector extension or custom node UI |
| You want unit-testable editor logic | No external tooling need |
| Complex UI — dockable panels, custom canvas, property grids | Simple property editing or menu additions |

For game toolsets that import/export to Godot: **WPF with a shared Core classlib**.

---

## 2. MVVM vs Code-Behind — The Pragmatic Rule

**MVVM for logic. Code-behind for UI.**

MVVM is not religion — it is about testability and maintainability as complexity grows.

### Use MVVM when
- Loading files, managing game data, undo/redo stacks — any business logic
- The same data drives multiple views
- You want unit tests on editor logic (ViewModel has no UI dependency)

### Use code-behind when (it is fine)
- Window lifecycle: `Loaded`, `Closing`, `SizeChanged`
- Animations tightly coupled to the visual tree
- Focus management, keyboard navigation
- Direct manipulation of a `Canvas` or `WriteableBitmap`
- Drag-and-drop in a `TreeView`
- Small dialogs where MVVM would be 3x the code with no payoff

### When MVVM is overkill
- Debug overlay with 3 checkboxes
- About dialog
- One-shot wizard
- Any UI with no data to bind and no commands to expose

---

## 3. CommunityToolkit.Mvvm — Use It

Install: `CommunityToolkit.Mvvm` (NuGet, current 8.3+).

**Why over manual `INotifyPropertyChanged`:** Zero boilerplate, source-generated at compile time (no reflection, no runtime overhead), built-in command wiring.

```csharp
// Class MUST be partial
public partial class MapEditorViewModel : ObservableObject
{
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(Title))]
    [NotifyCanExecuteChangedFor(nameof(SaveCommand))]
    private string? _filePath;

    [ObservableProperty]
    private bool _isDirty;

    public string Title => _filePath is null
        ? "Untitled — Map Editor"
        : $"{(_isDirty ? "* " : "")}{Path.GetFileName(_filePath)}";

    // Partial method hook — only implement when needed
    partial void OnIsDirtyChanged(bool value) { /* update title bar, etc. */ }

    [RelayCommand(CanExecute = nameof(CanSave))]
    private async Task SaveAsync() { IsDirty = false; /* serialize */ }
    private bool CanSave() => IsDirty && _filePath is not null;

    [RelayCommand]
    private async Task OpenAsync() { /* file dialog + deserialize */ }

    // Async command — AllowConcurrentExecutions=false prevents double-clicks
    [RelayCommand(AllowConcurrentExecutions = false)]
    private async Task LoadAssetAsync(string path) { /* heavy I/O */ }
}
```

Old/new value hooks (8.2+):
```csharp
partial void OnSelectedNodeChanging(SceneNodeViewModel? oldValue, SceneNodeViewModel? newValue)
{
    oldValue?.Deselect();
    newValue?.Select();
}
```

---

## 4. Data Binding Essentials

### DataContext Setup
```csharp
// In code-behind (most explicit)
public MainWindow()
{
    InitializeComponent();
    DataContext = new MainEditorViewModel();
}
```

```xml
<!-- Design-time IntelliSense -->
d:DataContext="{d:DesignInstance Type=local:MainEditorViewModel, IsDesignTimeCreatable=True}"
```

### Binding Modes
| Mode | Use case |
|---|---|
| `OneWay` | Read-only display |
| `TwoWay` | Editable fields (TextBox, CheckBox) |
| `OneTime` | Static data — improves performance |

### Common Pitfalls
- `ObservableCollection<T>` notifies on Add/Remove/Move — **not** on property changes of items. Items must also implement `INotifyPropertyChanged`.
- Never modify an `ObservableCollection<T>` from a background thread — marshal to UI dispatcher first.
- `TextBox` two-way binding only updates on focus loss by default. Add `UpdateSourceTrigger=PropertyChanged` for live validation.

---

## 5. XAML Patterns

### Implicit DataTemplate (Powerful for Game Editors)
Auto-selects the right view based on ViewModel type — no selector needed:
```xml
<Window.Resources>
    <DataTemplate DataType="{x:Type vm:TileLayerViewModel}">
        <local:TileLayerView/>
    </DataTemplate>
    <DataTemplate DataType="{x:Type vm:SpriteNodeViewModel}">
        <local:SpriteInspectorView/>
    </DataTemplate>
</Window.Resources>

<!-- Automatically picks correct template based on SelectedItem type -->
<ContentControl Content="{Binding SelectedItem}"/>
```

### Control Selection
| Control | Use when |
|---|---|
| `ItemsControl` | Custom layout, no selection (tile palette, layer list) |
| `ListBox` | Simple selection list |
| `ListView` with `GridView` | Tabular display with selection (asset browser) |
| `DataGrid` | Editable table with sorting (stats, config tables) |
| `TreeView` | Scene graph, file hierarchy |

### Always Virtualize Large Lists
```xml
<ItemsControl VirtualizingStackPanel.IsVirtualizing="True"
              VirtualizingStackPanel.VirtualizationMode="Recycling">
```

### DataTrigger for ViewModel-Driven State
```xml
<Style TargetType="TreeViewItem">
    <Style.Triggers>
        <DataTrigger Binding="{Binding IsModified}" Value="True">
            <Setter Property="Foreground" Value="Orange"/>
        </DataTrigger>
    </Style.Triggers>
</Style>
```

### Resource Dictionary Organization
```
/Themes/
    Colors.xaml
    Typography.xaml
    Controls.xaml
```
Merge in `App.xaml` via `ResourceDictionary.MergedDictionaries`.

---

## 6. Game Asset Editor Patterns

### Property Inspector — Two Approaches

**Fixed schema (recommended):** `DataTemplateSelector` per property type. Clean, fast, explicit.

**Dynamic/unknown types:** Reflection + `TypeDescriptor`. Use when inspecting arbitrary game objects at runtime.

See `resources/implementation-playbook.md` for full implementations.

### Canvas / Viewport for Tile Maps

**DrawingVisual** (retained mode — moderate element counts):
- Override `FrameworkElement`, host one `DrawingVisual`
- Call `RenderOpen()` to redraw
- Good for tile grids, scene overlays

**WriteableBitmap** (immediate mode — maximum performance, pixel manipulation):
- Lock → write pixels → `AddDirtyRect` → Unlock
- Best for large tile maps, painted terrain, pixel-level editing
- Use `WriteableBitmapEx` NuGet for convenient blit helpers
- Batch dirty updates — avoid Lock/Unlock per frame

**D3DImage** (when you need a real game renderer in-editor):
- Embeds DirectX content in WPF window
- Use when you need to preview 3D or actual Godot rendering in-tool

### Scene Tree / Node Hierarchy
```xml
<TreeView ItemsSource="{Binding RootNodes}">
    <TreeView.ItemTemplate>
        <HierarchicalDataTemplate DataType="{x:Type vm:SceneNodeViewModel}"
                                  ItemsSource="{Binding Children}">
            <StackPanel Orientation="Horizontal">
                <Image Source="{Binding Icon}" Width="16" Height="16"/>
                <TextBlock Text="{Binding Name}" Margin="4,0,0,0"/>
            </StackPanel>
        </HierarchicalDataTemplate>
    </TreeView.ItemTemplate>
</TreeView>
```
Use one `HierarchicalDataTemplate` per node ViewModel type for mixed trees — WPF picks automatically.
Drag-and-drop reparenting requires code-behind (legitimate use).

### Undo/Redo System
Classic command pattern with two stacks — `Execute`, `Undo`, `Redo`.
Every user action that modifies data creates and executes an `IUndoableCommand`.
Composite commands wrap multiple commands as one undoable action.
See `resources/implementation-playbook.md` for full implementation.

---

## 7. File I/O

```csharp
// Open dialog
var dlg = new Microsoft.Win32.OpenFileDialog
{
    Filter = "Tile Map (*.tilemap)|*.tilemap|All Files (*.*)|*.*"
};
if (dlg.ShowDialog() == true)
    await LoadFileAsync(dlg.FileName);

// Save dialog
var save = new Microsoft.Win32.SaveFileDialog
{
    FileName = Path.GetFileName(_currentPath ?? "Untitled"),
    Filter = "Tile Map (*.tilemap)|*.tilemap"
};
if (save.ShowDialog() == true)
    await SaveFileAsync(save.FileName);
```

### JSON — Prefer System.Text.Json
```csharp
var options = new JsonSerializerOptions
{
    WriteIndented = true,
    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
};
await using var stream = File.OpenWrite(path);
await JsonSerializer.SerializeAsync(stream, data, options);
```

### FileSystemWatcher for External Changes
```csharp
_watcher = new FileSystemWatcher(Path.GetDirectoryName(path)!)
{
    Filter = Path.GetFileName(path),
    NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.Size,
    EnableRaisingEvents = true
};
// FileSystemWatcher fires on a background thread — must dispatch to UI
_watcher.Changed += (_, _) =>
    Application.Current.Dispatcher.InvokeAsync(OnExternalFileChanged);
```

### Dirty Tracking
- `bool IsDirty` flag set on every undo-stack push
- `CanClose()` prompts if dirty
- Handle `Window.Closing` in code-behind to call `CanClose()`

---

## 8. WPF + Godot Data Bridge

**Architecture: shared `*.Core` classlib**

```
GameToolset.Core     ← plain net9.0 classlib (data models, serialization)
GameToolset.Editor   ← WPF, references Core
GameToolset.Godot    ← Godot project, references Core (or reads JSON)
```

Data flow:
- `Core` contains plain C# data classes — `TileMap`, `TileLayer`, `EnemyConfig`, etc.
- WPF editor loads/saves via `System.Text.Json`
- Godot reads the same JSON files via `FileAccess.get_file_as_string()` + `JSON.parse_string()`
- If using Godot C# (.NET 8), the Godot project can directly `<ProjectReference>` `*.Core`

---

## 9. Cross-Thread UI Updates

**Golden rules:**
1. Never touch UI elements from a background thread
2. Never `.Wait()` or `.Result` an async Task on the UI thread — deadlock
3. Use `async/await` all the way through

```csharp
// Correct: async event handler
private async void Button_Click(object sender, RoutedEventArgs e)
{
    var data = await LoadDataAsync();  // background work
    MyListBox.ItemsSource = data;      // back on UI thread after await
}

// Correct: background Task dispatching back to UI
private async Task ProcessAsync(string path)
{
    var result = await Task.Run(() => HeavyParsing(path));
    MyItems.Add(result);  // safe — await returns to UI thread
}

// When you lose sync context (rare): explicit dispatch
await Application.Current.Dispatcher.InvokeAsync(() => ProgressBar.Value = pct);
```

For `ObservableCollection<T>` updated from multiple threads:
```csharp
BindingOperations.EnableCollectionSynchronization(Items, _lock);
```

---

## 10. Memory Management

**#1 WPF leak: event subscriptions keeping ViewModels alive.**

```csharp
// Unsubscribe on Unloaded
private void OnLoaded(object s, RoutedEventArgs e) =>
    SomeService.Instance.DataChanged += OnDataChanged;
private void OnUnloaded(object s, RoutedEventArgs e) =>
    SomeService.Instance.DataChanged -= OnDataChanged;
```

```csharp
// WeakEventManager for long-lived subscriptions (source won't prevent GC)
WeakEventManager<EventSource, EventArgs>.AddHandler(source, nameof(source.Event), Handler);
```

```csharp
// IDisposable on ViewModels that own resources (FileSystemWatcher, etc.)
protected override void OnClosed(EventArgs e)
{
    (DataContext as IDisposable)?.Dispose();
    base.OnClosed(e);
}
```

---

## 11. DPI and Pixel-Perfect Rendering

WPF works in Device Independent Pixels (96 DIP = 1 inch). Mostly automatic — breaks for pixel-art game editors.

```csharp
// Get actual DPI scale for pixel-perfect rendering
var source = PresentationSource.FromVisual(this);
double dpiX = source.CompositionTarget.TransformToDevice.M11;
double dpiY = source.CompositionTarget.TransformToDevice.M22;

// Create WriteableBitmap at physical resolution
var bmp = new WriteableBitmap(
    (int)(logicalW * dpiX), (int)(logicalH * dpiY),
    96 * dpiX, 96 * dpiY,
    PixelFormats.Bgra32, null);
```

```xml
<!-- Pixel art / tile sprites — nearest neighbor, no blurring -->
<Image RenderOptions.BitmapScalingMode="NearestNeighbor"
       SnapsToDevicePixels="True"
       Source="{Binding TileSprite}"/>

<!-- Canvas — snap to device pixels -->
<Canvas UseLayoutRounding="True" SnapsToDevicePixels="True">
```

Handle per-monitor DPI changes:
```csharp
protected override void OnDpiChanged(DpiScale oldDpi, DpiScale newDpi)
{
    base.OnDpiChanged(oldDpi, newDpi);
    RecreateRenderBuffer(newDpi.PixelsPerInchX, newDpi.PixelsPerInchY);
}
```

---

## 12. Common Pitfalls

| Pitfall | Fix |
|---|---|
| Binding errors silently swallowed | Monitor Output window; add `PresentationTraceSources.TraceLevel=High` |
| No virtualization on 1000+ item lists | `VirtualizingStackPanel.IsVirtualizing="True"` + `VirtualizationMode="Recycling"` |
| `TextBox` binding updates on focus loss | Add `UpdateSourceTrigger=PropertyChanged` |
| `ObservableCollection` modified on background thread | Marshal to UI dispatcher or `EnableCollectionSynchronization` |
| Forgot `partial` on source-generated class | Add `partial` keyword — required for `[ObservableProperty]` |
| Static event subscriptions in singletons | Use `WeakEventManager` or explicit unsubscribe |
| `async void` outside event handlers | Use `async Task` — `async void` swallows exceptions |

---

## 13. Useful NuGet Packages for Game Toolsets

| Package | Purpose |
|---|---|
| `CommunityToolkit.Mvvm` | MVVM source generation — must-have |
| `WriteableBitmapEx` | Pixel/blit operations on `WriteableBitmap` |
| `Microsoft.Xaml.Behaviors.Wpf` | Behavior/trigger attachments without code-behind |
| `Extended.Wpf.Toolkit` | ColorPicker, NumericUpDown, PropertyGrid |
| `Ookii.Dialogs.Wpf` | Modern task dialogs, folder browser |
| `HelixToolkit.Wpf` | 3D viewport in WPF (for 3D asset preview) |
| `ScottPlot.WPF` | Fast charting (profiling/stats panels) |

---

## Resources

- Full code patterns (property inspector, DrawingVisual, WriteableBitmap, undo/redo, file I/O): `resources/implementation-playbook.md`
- [CommunityToolkit.Mvvm docs](https://learn.microsoft.com/en-us/dotnet/communitytoolkit/mvvm/)
- [WPF data binding](https://learn.microsoft.com/en-us/dotnet/desktop/wpf/data/)
- [WPF threading model](https://learn.microsoft.com/en-us/dotnet/desktop/wpf/advanced/threading-model)
- [Weak event patterns](https://learn.microsoft.com/en-us/dotnet/desktop/wpf/events/weak-event-patterns)
