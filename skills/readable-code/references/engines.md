# Game engines

Read this along with the language reference when the project uses an engine.

[Which rule wins](../SKILL.md#which-rule-wins) stays the same. Anything an engine's tooling requires counts as **what the language requires**, because the code won't build or work without it. Everything else follows the house rules. Doc comments stay required on engine callbacks such as `Update()`, `_process()` and `BeginPlay()`, so cover what the method does in this class.

## Unity

C# with [csharp.md](languages/csharp.md). Allman is already the norm.

Engine requirements:

- Keep the exact names of Unity messages, such as `Awake`, `Start`, `Update` and `OnDestroy`. Unity finds them by name, so a typo fails silently.
- Name a `MonoBehaviour` class's file after the class, so Unity can attach it in the editor.
- Use `[SerializeField] private` for inspector fields, rather than making them public to expose them.

Unity-specific guidance:

- Compare Unity objects with `== null` or the implicit bool, because Unity overrides it. `??` and `?.` skip that override.
- Serialized field names are part of the saved data. Use `[FormerlySerializedAs]` when renaming one.

## Unreal

C++ with [cpp.md](languages/cpp.md), following the [Epic C++ coding standard](https://dev.epicgames.com/documentation/en-us/unreal-engine/epic-cplusplus-coding-standard-for-unreal-engine). Its braces already match the house style: on a new line, on every block, even a single statement. If the repo needs a formatter, use [clang-format-unreal](../assets/clang-format-unreal).

Engine requirements:

- Unreal Header Tool needs type prefixes in most cases: `U` for `UObject` classes, `A` for `AActor` classes, `S` for `SWidget` classes, `I` for interfaces, `E` for enums, `T` for templates and `F` for most other types.
- Keep `UCLASS()`, `USTRUCT()`, `UENUM()`, `UPROPERTY()`, `UFUNCTION()` and `GENERATED_BODY()` exactly where the tool expects them. Don't wrap them in namespaces.
- Mark every `UObject` pointer member with `UPROPERTY()`, so the garbage collector can see it. `TObjectPtr` alone isn't enough.
- Enums exposed to Blueprints stay based on `uint8`.

Project conventions, which replace cpp.md's naming rule, because cpp.md defers to the project's convention:

- `PascalCase` for types, functions and variables, with a `b` prefix on booleans.
- Tabs for indentation, with a width of 4.
- Unreal's containers and strings, such as `TArray`, `TMap` and `FString`, rather than the standard library.
- Put doc comments on the public declaration, as `/** */` blocks with `@param` and `@return`. Epic's standard and the house rules agree on this.

Unreal's own check macros aren't error handling. `check()` can be compiled out, so see `simple-software-design` if it's installed.

## Bevy

Rust with [rust.md](languages/rust.md).

Engine requirements:

- A system's parameters must all be types Bevy can inject, such as `Res`, `Query` and `Commands`. Taking `Res<T>` by value is required, even though clippy's pedantic set objects to it.

Bevy-specific guidance:

- Name systems for what they do, such as `apply_damage`, because they're listed by name in schedules.
- Give every component, resource and system a doc comment, including one-field marker components.

## MonoGame

C# with [csharp.md](languages/csharp.md). MonoGame's own samples follow the same style. `Game` callbacks such as `LoadContent`, `Update` and `Draw` are overrides, so they need doc comments.

## Godot

GDScript with [gdscript.md](languages/gdscript.md), or C# with [csharp.md](languages/csharp.md).

Engine requirements:

- Keep the names of virtual methods, such as `_ready` and `_process`, in both languages. C# uses `_Ready` and `_Process`.
- Name a C# script's file after its class, so Godot can attach it.

## Visual scripts

Blueprints and Unity Visual Scripting aren't text, so these rules don't reach them. Don't edit binary assets. When you report on code that depends on them, say that you didn't read them.
