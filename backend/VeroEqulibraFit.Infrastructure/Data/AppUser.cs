using Microsoft.AspNetCore.Identity;

namespace VeroEqulibraFit.Infrastructure.Data;

public sealed class AppUser : IdentityUser<Guid>
{
    public string? DisplayName { get; set; }
}

public sealed class AppRole : IdentityRole<Guid> { }
