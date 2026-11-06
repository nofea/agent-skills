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

## Doc comments

Use `///` XML comments with `<summary>`, `<param>`, `<returns>` and `<exception>`. Doxygen reads them, and so do the compiler and IDEs.

```csharp
/// <summary>Applies a percentage discount to an order total.</summary>
/// <param name="total">Order total in cents.</param>
/// <param name="percent">Discount from 0 to 100.</param>
/// <returns>The discounted total in cents.</returns>
/// <exception cref="ArgumentOutOfRangeException">If percent is out of range.</exception>
public int ApplyDiscount(int total, int percent)
```
