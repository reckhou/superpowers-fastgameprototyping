---
name: dotnet-csharp-workflow
description: "Use when working on any .NET or C# project — solution setup, build, test, NuGet, MSBuild config, or publishing. Covers Godot C# project structure and shared library patterns."
---

# .NET / C# Workflow

Tooling, project structure, and C# patterns for .NET 8/9 development.

For full code examples, see `resources/implementation-playbook.md`.

---

## 1. dotnet CLI — Essential Commands

```bash
# Solution & project setup
dotnet new sln -n MySolution
dotnet new classlib -n MyLib -o src/MyLib
dotnet new wpf -n MyApp -o src/MyApp
dotnet new xunit -n MyLib.Tests -o tests/MyLib.Tests
dotnet sln add src/MyLib/MyLib.csproj
dotnet add src/MyApp reference src/MyLib/MyLib.csproj
dotnet add package CommunityToolkit.Mvvm

# Build
dotnet build                          # implicit restore included
dotnet build -c Release
dotnet build -p:TreatWarningsAsErrors=true

# Run
dotnet run --project src/MyApp/MyApp.csproj
dotnet run -- --arg value             # pass args after --

# Test
dotnet test
dotnet test --filter "FullyQualifiedName~MyTests.SomeTest"
dotnet test --filter "Category=Unit"
dotnet test --collect:"XPlat Code Coverage"
dotnet test --no-build -c Release

# Publish
dotnet publish -c Release -o ./publish                              # framework-dependent
dotnet publish -c Release -r win-x64 --self-contained true         # self-contained
dotnet publish -c Release -r win-x64 -p:PublishSingleFile=true     # single exe

# Package hygiene
dotnet list package --outdated
dotnet list package --vulnerable
```

**Note:** `dotnet restore` runs implicitly inside `build`, `run`, `test`, `publish`. Use `--no-restore` in CI after an explicit restore step.

---

## 2. Solution Structure

### Standard Layout
```
MySolution/
├── MySolution.sln
├── Directory.Build.props        # shared MSBuild props — applies to all projects
├── Directory.Packages.props     # central NuGet versions (if using CPM)
├── src/
│   ├── MyLib/MyLib.csproj
│   └── MyApp/MyApp.csproj
└── tests/
    └── MyLib.Tests/MyLib.Tests.csproj
```

### Game Toolset Layout (Godot + WPF Editor + Shared Logic)
```
GameToolset/
├── GameToolset.sln
├── Directory.Build.props
├── Directory.Packages.props
├── src/
│   ├── GameToolset.Core/            # pure classlib — models, logic, serialization
│   │   └── GameToolset.Core.csproj  # net9.0, no engine deps
│   ├── GameToolset.Godot/           # Godot project
│   │   ├── GameToolset.Godot.csproj # Godot.NET.Sdk
│   │   └── project.godot
│   └── GameToolset.Editor/          # WPF editor tool
│       └── GameToolset.Editor.csproj # net9.0-windows, UseWPF=true
└── tests/
    └── GameToolset.Core.Tests/      # tests — no Godot runtime needed
```

**Key principle:** Keep game logic in `*.Core` — plain classlib with no engine dependency. Trivially testable without a running Godot instance. Godot and WPF projects add engine/UI glue on top.

---

## 3. NuGet Package Management

### Central Package Management (Recommended for Multi-Project Solutions)

**`Directory.Packages.props`** at solution root:
```xml
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="CommunityToolkit.Mvvm" Version="8.3.2" />
    <PackageVersion Include="xunit" Version="2.9.3" />
    <PackageVersion Include="coverlet.collector" Version="6.0.4" />
  </ItemGroup>
</Project>
```

Each `.csproj` omits the version:
```xml
<PackageReference Include="CommunityToolkit.Mvvm" />
```

### Lock Files for Reproducible Restores
```xml
<!-- Directory.Build.props -->
<RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>
```
```bash
dotnet restore --locked-mode   # CI: fail if lock file would change
```
Commit `packages.lock.json` to source control.

---

## 4. MSBuild Configuration

### `Directory.Build.props` — Shared Across All Projects
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
  </PropertyGroup>
</Project>
```

### Per-Project Overrides
```xml
<!-- WPF project -->
<PropertyGroup>
  <TargetFramework>net9.0-windows</TargetFramework>
  <UseWPF>true</UseWPF>
</PropertyGroup>

<!-- Godot project -->
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>  <!-- Godot 4.x targets net8.0 -->
</PropertyGroup>
```

### Key Properties

| Property | Value | Why |
|---|---|---|
| `TargetFramework` | `net9.0` or `net8.0` (LTS) | net8.0 LTS until Nov 2026 |
| `Nullable` | `enable` | Catch null errors at compile time |
| `ImplicitUsings` | `enable` | Auto-imports SDK namespaces |
| `LangVersion` | `latest` | Use newest C# features |
| `TreatWarningsAsErrors` | `true` | Nullable/analyzer issues fail build |
| `Deterministic` | `true` | Reproducible builds |

---

## 5. Nullable Reference Types

Enable in `Directory.Build.props`: `<Nullable>enable</Nullable>`

```csharp
string name = "default";           // non-nullable, must be assigned
string? maybeName = GetName();     // nullable, must check before use

// Safe patterns
int len = maybeName?.Length ?? 0;  // null-conditional + coalesce
if (maybeName is not null) { ... } // pattern check

// Null-forgiving — use sparingly, only when you know more than the compiler
string definite = GetValue()!;

// C# 11 required — forces initialization at construction site
public class Config
{
    public required string Name { get; init; }
    public string? OptionalPath { get; set; }
}
```

**Migration strategy for existing code:** Start with `<Nullable>warnings</Nullable>`, fix file by file with `#nullable enable`, then switch to full `enable`.

---

## 6. Modern C# Features Worth Using

```csharp
// Records — immutable data, value equality, with-expressions
public record TileData(int X, int Y, int TileId);
var moved = tile with { X = tile.X + 1 };

// Primary constructors (C# 12)
public class GameManager(ILogger logger, SaveSystem saves)
{
    public void Save() => saves.Save(logger);
}

// Pattern matching
string Describe(object shape) => shape switch
{
    Circle c when c.Radius > 10 => "large circle",
    Circle c => "small circle",
    Rectangle { Width: > 100 } => "wide rectangle",
    _ => "unknown"
};

// Collection expressions (C# 12)
int[] nums = [1, 2, 3, 4];
List<string> names = ["Alice", "Bob"];

// Required members (C# 11)
public class EnemyConfig
{
    public required string Name { get; init; }
    public required int MaxHealth { get; init; }
}
```

---

## 7. Testing Setup

### Framework Comparison
| Framework | Use when |
|---|---|
| **xUnit** | Default choice — modern, parallel by default, no global state |
| **NUnit** | Good with GdUnit4Net (Godot C# testing) — familiar if coming from Unity |
| **MSTest** | Legacy / enterprise requirements only |

### Test Project Setup
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="xunit" />
    <PackageReference Include="xunit.runner.visualstudio" />
    <PackageReference Include="coverlet.collector" />
    <ProjectReference Include="../../src/MyLib/MyLib.csproj" />
  </ItemGroup>
</Project>
```

### Running Tests
```bash
dotnet test                                          # all tests
dotnet test --filter "Category=Unit"                 # by category
dotnet test --filter "FullyQualifiedName~HealthTests" # by name match
dotnet test --collect:"XPlat Code Coverage"          # with coverage
```

---

## 8. Godot + .NET Project Setup

### Godot .csproj
```xml
<Project Sdk="Godot.NET.Sdk/4.4.0">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <EnableDynamicLoading>true</EnableDynamicLoading>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
    <!-- Reference shared logic — no Godot engine dep in Core -->
    <ProjectReference Include="../../src/GameToolset.Core/GameToolset.Core.csproj" />
  </ItemGroup>
</Project>
```

### Key Points
- Godot 4.x targets `net8.0` — do not change to `net9.0` in the Godot project
- `EnableDynamicLoading=true` is required by the Godot .NET SDK
- Keep game logic in `*.Core` classlib — import it into both Godot and WPF projects
- GodotSharp is automatically referenced via the `Godot.NET.Sdk`

### Godot Build Commands
```bash
dotnet build                          # build C# solution (not the Godot project)
godot --headless --import             # import Godot assets
godot --export-release "Windows Desktop" ./build/game.exe
```

---

## 9. Publishing Pitfalls

| Scenario | Pitfall | Fix |
|---|---|---|
| Self-contained + trimming | Reflection-based code broken at runtime | Use source generators, add `[DynamicallyAccessedMembers]` hints |
| Self-contained + WPF | Much larger output (~150MB+) | Expected — WPF needs the full runtime |
| Single-file + WPF | Some WPF features break | Test thoroughly; BAML resources need special handling |
| Native AOT | Most WPF features unsupported | Do not use AOT with WPF |
| Platform target mismatch | `win-x64` binary on `arm64` machine | Match RID to target, or use `win` (portable) |

---

## 10. Useful Global Tools

```bash
dotnet tool install --global dotnet-format       # code formatting
dotnet tool install --global dotnet-outdated      # check outdated packages
dotnet tool install --global BenchmarkDotNet      # micro-benchmarking
dotnet tool install --global dotnet-trace         # runtime performance tracing
dotnet tool install --global dotnet-counters      # live metrics (GC, threadpool, etc.)

# Usage
dotnet format                                     # apply formatting
dotnet outdated --upgrade                         # interactive upgrade
dotnet trace collect --process-id <PID>
dotnet counters monitor --process-id <PID> System.Runtime
```

---

## Resources

- Full project templates and code patterns: `resources/implementation-playbook.md`
- [.NET CLI docs](https://learn.microsoft.com/en-us/dotnet/core/tools/)
- [MSBuild reference](https://learn.microsoft.com/en-us/visualstudio/msbuild/msbuild-reference)
- [Nullable reference types](https://learn.microsoft.com/en-us/dotnet/csharp/nullable-references)
- [Central Package Management](https://learn.microsoft.com/en-us/nuget/consume-packages/central-package-management)
- [Godot C# basics](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html)
