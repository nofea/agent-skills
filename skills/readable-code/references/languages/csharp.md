# C#

Source: [Microsoft C# coding conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions) and the [.NET Framework Design Guidelines](https://learn.microsoft.com/en-us/dotnet/standard/design-guidelines/).

**Allman: yes.** This is already the .NET default. The formatter is `dotnet format`.

- **Naming:** `PascalCase` for types, methods, properties and public members, `camelCase` for locals and parameters, `_camelCase` for private fields, and an `I` prefix for interfaces.
- **Nulls:** enable nullable reference types and handle the warnings instead of suppressing them.
- **Async:** suffix async methods with `Async`, return `Task` rather than `async void`, await instead of blocking, and pass `CancellationToken` through.
- **Resources:** use `using` declarations for `IDisposable`.
- **Errors:** throw specific exceptions, catch only what you can handle, and rethrow with `throw;`.
- **Data:** use LINQ when it reads more clearly than a loop, and records for immutable data.
- **Types:** use `var` when the type is obvious from the right-hand side.
