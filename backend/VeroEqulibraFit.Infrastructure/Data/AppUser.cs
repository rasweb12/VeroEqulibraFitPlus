using Microsoft.AspNetCore.Identity;

namespace VeroEqulibraFit.Infrastructure.Data;

public sealed class AppUser : IdentityUser<Guid>
{
    public string? DisplayName { get; set; }
    // Older accounts predate this field and deliberately remain null. The
    // administration UI must show that the registration date is unavailable
    // rather than manufacture a historical timestamp.
    public DateTimeOffset? RegisteredAt { get; set; }
}

public sealed class AppRole : IdentityRole<Guid> { }
