# .NET / C# Workflow — Implementation Playbook

Full templates and code patterns referenced by `SKILL.md`.

---

## Template 1: Directory.Build.props (Solution Root)

```xml
<Project>
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <LangVersion>latest</LangVersion>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <Deterministic>true</Deterministic>
    <AnalysisLevel>latest-recommended</AnalysisLevel>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
  </PropertyGroup>
</Project>
```

---

## Template 2: Directory.Packages.props (Central Package Management)

```xml
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
    <CentralPackageTransitivePinningEnabled>true</CentralPackageTransitivePinningEnabled>
  </PropertyGroup>
  <ItemGroup>
    <!-- MVVM -->
    <PackageVersion Include="CommunityToolkit.Mvvm" Version="8.3.2" />
    <!-- Testing -->
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="2.8.2" />
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="17.12.0" />
    <PackageVersion Include="coverlet.collector" Version="6.0.4" />
    <PackageVersion Include="FluentAssertions" Version="7.0.0" />
    <!-- Utilities -->
    <PackageVersion Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>
</Project>
```

---

## Template 3: Core Classlib .csproj

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <!-- Inherits from Directory.Build.props -->
    <!-- Override only what differs -->
    <RootNamespace>GameToolset.Core</RootNamespace>
    <AssemblyName>GameToolset.Core</AssemblyName>
  </PropertyGroup>
</Project>
```

---

## Template 4: WPF Editor .csproj

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net9.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <ApplicationIcon>Assets\icon.ico</ApplicationIcon>
    <StartupObject>GameToolset.Editor.App</StartupObject>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="CommunityToolkit.Mvvm" />
    <ProjectReference Include="..\..\src\GameToolset.Core\GameToolset.Core.csproj" />
  </ItemGroup>
</Project>
```

---

## Template 5: Godot .csproj

```xml
<Project Sdk="Godot.NET.Sdk/4.4.0">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <EnableDynamicLoading>true</EnableDynamicLoading>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <LangVersion>latest</LangVersion>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\GameToolset.Core\GameToolset.Core.csproj" />
  </ItemGroup>
</Project>
```

---

## Template 6: Test Project .csproj

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" />
    <PackageReference Include="coverlet.collector">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="FluentAssertions" />
    <ProjectReference Include="..\..\src\GameToolset.Core\GameToolset.Core.csproj" />
  </ItemGroup>
</Project>
```

---

## Pattern 1: Shared Data Model with Source-Generated JSON

```csharp
// TileMap.cs — in GameToolset.Core
public class TileMap
{
    public required string Name { get; init; }
    public int Width { get; init; }
    public int Height { get; init; }
    public List<TileLayer> Layers { get; init; } = [];
}

public class TileLayer
{
    public required string Name { get; init; }
    public bool Visible { get; set; } = true;
    public int[] Tiles { get; init; } = [];
}
```

```csharp
// TileMapJsonContext.cs — source-generated, AOT-safe
[JsonSourceGenerationOptions(
    WriteIndented = true,
    PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull)]
[JsonSerializable(typeof(TileMap))]
[JsonSerializable(typeof(List<TileLayer>))]
public partial class TileMapJsonContext : JsonSerializerContext { }
```

```csharp
// Usage in WPF editor
var json = JsonSerializer.Serialize(map, TileMapJsonContext.Default.TileMap);
await File.WriteAllTextAsync(path, json);

var loaded = JsonSerializer.Deserialize(json, TileMapJsonContext.Default.TileMap);
```

```gdscript
# Usage in Godot
var json_text = FileAccess.get_file_as_string("res://data/map.json")
var data = JSON.parse_string(json_text)
```

---

## Pattern 2: xUnit Tests with FluentAssertions

```csharp
public class TileMapTests
{
    [Fact]
    public void NewMap_HasCorrectDimensions()
    {
        var map = new TileMap { Name = "Test", Width = 10, Height = 10 };
        map.Width.Should().Be(10);
        map.Height.Should().Be(10);
    }

    [Theory]
    [InlineData(0, 0, true)]
    [InlineData(9, 9, true)]
    [InlineData(10, 0, false)]
    [InlineData(-1, 0, false)]
    public void IsInBounds_ReturnsCorrectResult(int x, int y, bool expected)
    {
        var map = new TileMap { Name = "Test", Width = 10, Height = 10 };
        map.IsInBounds(x, y).Should().Be(expected);
    }

    [Fact]
    public async Task Serialization_RoundTrips_Correctly()
    {
        var original = new TileMap
        {
            Name = "Level1",
            Width = 20,
            Height = 15,
            Layers = [new TileLayer { Name = "Ground", Tiles = [1, 2, 3] }]
        };

        var json = JsonSerializer.Serialize(original, TileMapJsonContext.Default.TileMap);
        var loaded = JsonSerializer.Deserialize(json, TileMapJsonContext.Default.TileMap);

        loaded.Should().NotBeNull();
        loaded!.Name.Should().Be("Level1");
        loaded.Layers.Should().HaveCount(1);
        loaded.Layers[0].Tiles.Should().Equal(1, 2, 3);
    }
}
```

---

## Pattern 3: Record Types for Game Data

```csharp
// Immutable value types — great for tile definitions, config, events
public record TileDefinition(int Id, string Name, bool IsSolid, bool IsWater);

public record GameEvent(string Type, float Timestamp, Dictionary<string, object> Payload);

// With-expressions for modifications
var movedPlayer = playerState with { X = playerState.X + 1, Y = playerState.Y };

// Positional records for compact data
public record Vector2Int(int X, int Y)
{
    public Vector2Int Add(Vector2Int other) => new(X + other.X, Y + other.Y);
    public float DistanceTo(Vector2Int other) =>
        MathF.Sqrt(MathF.Pow(X - other.X, 2) + MathF.Pow(Y - other.Y, 2));
}
```

---

## Pattern 4: Pattern Matching for Game Logic

```csharp
// Damage calculation with pattern matching
public static int CalculateDamage(int baseDamage, object target) => target switch
{
    Enemy { IsShielded: true } e  => baseDamage / 2,
    Enemy { IsArmored: true } e   => Math.Max(1, baseDamage - e.ArmorValue),
    Enemy e                       => baseDamage,
    DestructibleObject { Health: <= 0 } => 0,
    DestructibleObject d          => Math.Min(baseDamage, d.Health),
    _                             => 0
};

// State machine transitions
public static GameState Transition(GameState current, GameEvent evt) =>
    (current, evt.Type) switch
    {
        (GameState.Menu, "start")        => GameState.Playing,
        (GameState.Playing, "pause")     => GameState.Paused,
        (GameState.Paused, "resume")     => GameState.Playing,
        (GameState.Playing, "game_over") => GameState.GameOver,
        (GameState.GameOver, "restart")  => GameState.Playing,
        _                                => current
    };
```

---

## Pattern 5: Primary Constructors for Services

```csharp
// C# 12 primary constructors — clean DI without boilerplate
public class SaveSystem(string savePath, ILogger<SaveSystem> logger)
{
    public async Task SaveAsync<T>(T data, string filename)
    {
        var path = Path.Combine(savePath, filename);
        var json = JsonSerializer.Serialize(data);
        await File.WriteAllTextAsync(path, json);
        logger.LogInformation("Saved {Type} to {Path}", typeof(T).Name, path);
    }

    public async Task<T?> LoadAsync<T>(string filename)
    {
        var path = Path.Combine(savePath, filename);
        if (!File.Exists(path)) return default;
        var json = await File.ReadAllTextAsync(path);
        return JsonSerializer.Deserialize<T>(json);
    }
}
```

---

## Pattern 6: Undo/Redo (Pure Logic — No Engine Dep)

```csharp
public interface IUndoableCommand
{
    void Execute();
    void Undo();
    string Description { get; }
}

public class UndoRedoStack
{
    private readonly Stack<IUndoableCommand> _undo = new();
    private readonly Stack<IUndoableCommand> _redo = new();

    public bool CanUndo => _undo.Count > 0;
    public bool CanRedo => _redo.Count > 0;
    public string? NextUndoDescription => _undo.TryPeek(out var cmd) ? cmd.Description : null;

    public void Execute(IUndoableCommand command)
    {
        command.Execute();
        _undo.Push(command);
        _redo.Clear();
    }

    public void Undo()
    {
        if (!_undo.TryPop(out var cmd)) return;
        cmd.Undo();
        _redo.Push(cmd);
    }

    public void Redo()
    {
        if (!_redo.TryPop(out var cmd)) return;
        cmd.Execute();
        _undo.Push(cmd);
    }
}

// Composite — wrap multiple commands as one undoable action
public class CompositeCommand(string description, IEnumerable<IUndoableCommand> commands)
    : IUndoableCommand
{
    private readonly List<IUndoableCommand> _commands = commands.ToList();
    public string Description { get; } = description;
    public void Execute() => _commands.ForEach(c => c.Execute());
    public void Undo() => _commands.AsEnumerable().Reverse().ToList().ForEach(c => c.Undo());
}
```

---

## CI/CD: GitHub Actions for .NET

```yaml
# .github/workflows/build.yml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '9.x'
      - run: dotnet restore --locked-mode
      - run: dotnet build --no-restore -c Release
      - run: dotnet test --no-build -c Release --collect:"XPlat Code Coverage"
```
