# WPF Toolset Patterns — Implementation Playbook

Full code patterns referenced by `SKILL.md`.

---

## Pattern 1: Minimal Main ViewModel

```csharp
public partial class MainEditorViewModel : ObservableObject, IDisposable
{
    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(Title))]
    private string? _currentFilePath;

    [ObservableProperty]
    [NotifyCanExecuteChangedFor(nameof(SaveCommand))]
    private bool _isDirty;

    [ObservableProperty]
    private SceneNodeViewModel? _selectedNode;

    public string Title => _currentFilePath is null
        ? "Untitled — My Editor"
        : $"{(_isDirty ? "* " : "")}{Path.GetFileName(_currentFilePath)} — My Editor";

    public UndoRedoStack UndoRedo { get; } = new();
    public ObservableCollection<SceneNodeViewModel> RootNodes { get; } = new();

    partial void OnSelectedNodeChanging(SceneNodeViewModel? old, SceneNodeViewModel? next)
    {
        old?.Deselect();
        next?.Select();
    }

    [RelayCommand]
    private async Task OpenAsync()
    {
        var dlg = new Microsoft.Win32.OpenFileDialog
        {
            Filter = "Map File (*.map)|*.map|All Files (*.*)|*.*"
        };
        if (dlg.ShowDialog() != true) return;

        var json = await File.ReadAllTextAsync(dlg.FileName);
        // Deserialize and populate RootNodes
        CurrentFilePath = dlg.FileName;
        IsDirty = false;
    }

    [RelayCommand(CanExecute = nameof(CanSave))]
    private async Task SaveAsync()
    {
        if (_currentFilePath is null) { await SaveAsAsync(); return; }
        var json = JsonSerializer.Serialize(BuildDataModel());
        await File.WriteAllTextAsync(_currentFilePath, json);
        IsDirty = false;
    }
    private bool CanSave() => IsDirty;

    [RelayCommand]
    private async Task SaveAsAsync()
    {
        var dlg = new Microsoft.Win32.SaveFileDialog
        {
            FileName = Path.GetFileName(_currentFilePath ?? "Untitled"),
            Filter = "Map File (*.map)|*.map"
        };
        if (dlg.ShowDialog() != true) return;
        CurrentFilePath = dlg.FileName;
        await SaveAsync();
    }

    [RelayCommand(CanExecute = nameof(CanUndo))]
    private void Undo() { UndoRedo.Undo(); NotifyCommandsCanExecuteChanged(); }
    private bool CanUndo() => UndoRedo.CanUndo;

    [RelayCommand(CanExecute = nameof(CanRedo))]
    private void Redo() { UndoRedo.Redo(); NotifyCommandsCanExecuteChanged(); }
    private bool CanRedo() => UndoRedo.CanRedo;

    private void NotifyCommandsCanExecuteChanged()
    {
        UndoCommand.NotifyCanExecuteChanged();
        RedoCommand.NotifyCanExecuteChanged();
    }

    private object BuildDataModel() => new { Nodes = RootNodes };

    public void Dispose()
    {
        // Unsubscribe FileSystemWatcher, etc.
    }
}
```

---

## Pattern 2: MainWindow Code-Behind

```csharp
public partial class MainWindow : Window
{
    private MainEditorViewModel ViewModel => (MainEditorViewModel)DataContext;

    public MainWindow()
    {
        InitializeComponent();
        DataContext = new MainEditorViewModel();
        // Wire keyboard shortcuts
        CommandBindings.Add(new CommandBinding(ApplicationCommands.Undo,
            (_, _) => ViewModel.UndoCommand.Execute(null),
            (_, e) => e.CanExecute = ViewModel.UndoCommand.CanExecute(null)));
        CommandBindings.Add(new CommandBinding(ApplicationCommands.Redo,
            (_, _) => ViewModel.RedoCommand.Execute(null),
            (_, e) => e.CanExecute = ViewModel.RedoCommand.CanExecute(null)));
    }

    protected override void OnClosing(CancelEventArgs e)
    {
        if (ViewModel.IsDirty)
        {
            var result = MessageBox.Show("Unsaved changes. Save before closing?",
                "Unsaved Changes", MessageBoxButton.YesNoCancel);
            if (result == MessageBoxResult.Cancel) { e.Cancel = true; return; }
            if (result == MessageBoxResult.Yes)
                ViewModel.SaveCommand.Execute(null);
        }
        base.OnClosing(e);
    }

    protected override void OnClosed(EventArgs e)
    {
        (DataContext as IDisposable)?.Dispose();
        base.OnClosed(e);
    }
}
```

---

## Pattern 3: Undo/Redo Stack

```csharp
public class UndoRedoStack
{
    private readonly Stack<IUndoableCommand> _undo = new();
    private readonly Stack<IUndoableCommand> _redo = new();

    public bool CanUndo => _undo.Count > 0;
    public bool CanRedo => _redo.Count > 0;
    public string? NextUndoLabel => _undo.TryPeek(out var c) ? c.Description : null;
    public string? NextRedoLabel => _redo.TryPeek(out var c) ? c.Description : null;

    public void Execute(IUndoableCommand command)
    {
        command.Execute();
        _undo.Push(command);
        _redo.Clear();
    }

    public void Undo()
    {
        if (_undo.TryPop(out var cmd)) { cmd.Undo(); _redo.Push(cmd); }
    }

    public void Redo()
    {
        if (_redo.TryPop(out var cmd)) { cmd.Execute(); _undo.Push(cmd); }
    }
}

public interface IUndoableCommand
{
    string Description { get; }
    void Execute();
    void Undo();
}

// Example: move a node
public class MoveNodeCommand(SceneNodeViewModel node, Point from, Point to)
    : IUndoableCommand
{
    public string Description => $"Move {node.Name}";
    public void Execute() => node.Position = to;
    public void Undo() => node.Position = from;
}

// Composite: paste multiple nodes at once
public class CompositeCommand(string description, IReadOnlyList<IUndoableCommand> commands)
    : IUndoableCommand
{
    public string Description { get; } = description;
    public void Execute() => commands.ToList().ForEach(c => c.Execute());
    public void Undo() => commands.Reverse().ToList().ForEach(c => c.Undo());
}
```

---

## Pattern 4: Property Inspector — Fixed Schema (DataTemplateSelector)

```csharp
public class PropertyTemplateSelector : DataTemplateSelector
{
    public DataTemplate? FloatTemplate { get; set; }
    public DataTemplate? IntTemplate { get; set; }
    public DataTemplate? BoolTemplate { get; set; }
    public DataTemplate? StringTemplate { get; set; }
    public DataTemplate? ColorTemplate { get; set; }
    public DataTemplate? EnumTemplate { get; set; }

    public override DataTemplate? SelectTemplate(object item, DependencyObject container) =>
        item switch
        {
            FloatPropertyViewModel => FloatTemplate,
            IntPropertyViewModel => IntTemplate,
            BoolPropertyViewModel => BoolTemplate,
            StringPropertyViewModel => StringTemplate,
            ColorPropertyViewModel => ColorTemplate,
            EnumPropertyViewModel => EnumTemplate,
            _ => base.SelectTemplate(item, container)
        };
}
```

```xml
<!-- In XAML Resources -->
<local:PropertyTemplateSelector x:Key="PropSelector"
    FloatTemplate="{StaticResource FloatRowTemplate}"
    BoolTemplate="{StaticResource BoolRowTemplate}"
    StringTemplate="{StaticResource StringRowTemplate}"/>

<ItemsControl ItemsSource="{Binding Properties}"
              ItemTemplateSelector="{StaticResource PropSelector}"/>
```

---

## Pattern 5: Property Inspector — Dynamic (Reflection)

```csharp
public partial class InspectorViewModel : ObservableObject
{
    [ObservableProperty]
    private ObservableCollection<PropertyRowViewModel> _properties = new();

    public void Inspect(object? target)
    {
        Properties.Clear();
        if (target is null) return;

        foreach (PropertyDescriptor prop in TypeDescriptor.GetProperties(target))
        {
            if (!prop.IsBrowsable) continue;
            Properties.Add(new PropertyRowViewModel(target, prop));
        }
    }
}

public partial class PropertyRowViewModel(object target, PropertyDescriptor descriptor)
    : ObservableObject
{
    public string Name => descriptor.DisplayName;
    public string TypeName => descriptor.PropertyType.Name;

    public object? Value
    {
        get => descriptor.GetValue(target);
        set
        {
            descriptor.SetValue(target, value);
            OnPropertyChanged();
        }
    }
}
```

---

## Pattern 6: DrawingVisual Tile Map Renderer

```csharp
public class TileMapVisual : FrameworkElement
{
    private readonly DrawingVisual _visual = new();

    public TileMapVisual() => AddVisualChild(_visual);

    protected override int VisualChildrenCount => 1;
    protected override Visual GetVisualChild(int index) => _visual;

    public void Render(TileMap map, ImageSource[] tileSet, int tileSize)
    {
        using var dc = _visual.RenderOpen();
        for (int y = 0; y < map.Height; y++)
        for (int x = 0; x < map.Width; x++)
        {
            var tileId = map.GetTile(x, y);
            if (tileId <= 0) continue;
            var img = tileSet[tileId - 1];
            dc.DrawImage(img, new Rect(x * tileSize, y * tileSize, tileSize, tileSize));
        }
    }

    // Selection overlay
    public void DrawSelection(Int32Rect selection, int tileSize)
    {
        using var dc = _visual.RenderOpen();
        var pen = new Pen(Brushes.White, 2);
        dc.DrawRectangle(
            new SolidColorBrush(Color.FromArgb(60, 255, 255, 255)),
            pen,
            new Rect(
                selection.X * tileSize,
                selection.Y * tileSize,
                selection.Width * tileSize,
                selection.Height * tileSize));
    }
}
```

---

## Pattern 7: WriteableBitmap Renderer (High-Performance)

```csharp
public class TileMapBitmapRenderer
{
    private WriteableBitmap? _buffer;
    private int _tileSize;
    private int _widthInTiles;

    public WriteableBitmap Initialize(int widthTiles, int heightTiles, int tileSize, double dpiX, double dpiY)
    {
        _tileSize = tileSize;
        _widthInTiles = widthTiles;
        _buffer = new WriteableBitmap(
            widthTiles * tileSize, heightTiles * tileSize,
            dpiX, dpiY,
            PixelFormats.Bgra32, null);
        return _buffer;
    }

    public void BlitTile(int tileX, int tileY, byte[] pixelData)
    {
        if (_buffer is null) return;
        var rect = new Int32Rect(tileX * _tileSize, tileY * _tileSize, _tileSize, _tileSize);
        _buffer.Lock();
        try
        {
            _buffer.WritePixels(rect, pixelData, _tileSize * 4, 0);
            _buffer.AddDirtyRect(rect);
        }
        finally
        {
            _buffer.Unlock();
        }
    }
}
```

---

## Pattern 8: HierarchicalDataTemplate for Mixed Node Types

```xml
<TreeView ItemsSource="{Binding RootNodes}"
          SelectedItemChanged="OnSelectedItemChanged">
    <TreeView.Resources>
        <HierarchicalDataTemplate DataType="{x:Type vm:FolderNodeViewModel}"
                                  ItemsSource="{Binding Children}">
            <StackPanel Orientation="Horizontal">
                <Image Source="/Assets/folder.png" Width="16" Height="16"/>
                <TextBlock Text="{Binding Name}" Margin="4,0,0,0" FontWeight="Bold"/>
            </StackPanel>
        </HierarchicalDataTemplate>

        <HierarchicalDataTemplate DataType="{x:Type vm:SpriteNodeViewModel}"
                                  ItemsSource="{Binding Children}">
            <StackPanel Orientation="Horizontal">
                <Image Source="/Assets/sprite.png" Width="16" Height="16"/>
                <TextBlock Text="{Binding Name}" Margin="4,0,0,0"/>
            </StackPanel>
        </HierarchicalDataTemplate>

        <HierarchicalDataTemplate DataType="{x:Type vm:AudioNodeViewModel}"
                                  ItemsSource="{Binding Children}">
            <StackPanel Orientation="Horizontal">
                <Image Source="/Assets/audio.png" Width="16" Height="16"/>
                <TextBlock Text="{Binding Name}" Margin="4,0,0,0" Foreground="CadetBlue"/>
            </StackPanel>
        </HierarchicalDataTemplate>
    </TreeView.Resources>
</TreeView>
```

---

## Pattern 9: FileSystemWatcher with Dirty Prompt

```csharp
public partial class MapEditorViewModel : ObservableObject, IDisposable
{
    private FileSystemWatcher? _watcher;
    private bool _suppressReloadPrompt;

    private void WatchFile(string path)
    {
        _watcher?.Dispose();
        _watcher = new FileSystemWatcher(Path.GetDirectoryName(path)!)
        {
            Filter = Path.GetFileName(path),
            NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.Size,
            EnableRaisingEvents = true
        };
        _watcher.Changed += (_, _) =>
            Application.Current.Dispatcher.InvokeAsync(PromptExternalReload);
    }

    private async Task PromptExternalReload()
    {
        if (_suppressReloadPrompt) return;
        var result = MessageBox.Show(
            "File changed externally. Reload?", "Reload",
            MessageBoxButton.YesNo, MessageBoxImage.Question);
        if (result == MessageBoxResult.Yes)
        {
            _suppressReloadPrompt = true;
            await LoadFileAsync(_currentFilePath!);
            _suppressReloadPrompt = false;
        }
    }

    public void Dispose()
    {
        _watcher?.Dispose();
    }
}
```

---

## Pattern 10: Toolbar XAML with Commands

```xml
<ToolBar>
    <Button Command="{Binding NewCommand}" ToolTip="New">
        <Image Source="/Assets/new.png" Width="16" Height="16"/>
    </Button>
    <Button Command="{Binding OpenCommand}" ToolTip="Open">
        <Image Source="/Assets/open.png" Width="16" Height="16"/>
    </Button>
    <Button Command="{Binding SaveCommand}" ToolTip="Save (Ctrl+S)">
        <Image Source="/Assets/save.png" Width="16" Height="16"/>
    </Button>
    <Separator/>
    <Button Command="{Binding UndoCommand}"
            ToolTip="{Binding UndoRedo.NextUndoLabel, StringFormat='Undo: {0}'}">
        <Image Source="/Assets/undo.png" Width="16" Height="16"/>
    </Button>
    <Button Command="{Binding RedoCommand}"
            ToolTip="{Binding UndoRedo.NextRedoLabel, StringFormat='Redo: {0}'}">
        <Image Source="/Assets/redo.png" Width="16" Height="16"/>
    </Button>
    <Separator/>
    <ComboBox ItemsSource="{Binding AvailableTools}"
              SelectedItem="{Binding ActiveTool}"
              DisplayMemberPath="Name"
              Width="120"/>
</ToolBar>
```
