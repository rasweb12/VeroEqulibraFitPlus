using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Api.Services;

public sealed class JwtTokenService(IConfiguration configuration)
{
    private const int AccessLifetimeMinutes = 15;
    private readonly string _issuer = ReadIssuer(configuration);
    private readonly string _audience = ReadAudience(configuration);
    private readonly byte[] _key = ReadKey(configuration);

    public (string Token, DateTimeOffset ExpiresAt) CreateAccessToken(AppUser user, IEnumerable<string> roles)
    {
        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(AccessLifetimeMinutes);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Email, user.Email ?? string.Empty),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
        };
        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));
        var credentials = new SigningCredentials(new SymmetricSecurityKey(_key), SecurityAlgorithms.HmacSha512);
        var token = new JwtSecurityToken(_issuer, _audience, claims, expires: expiresAt.UtcDateTime, signingCredentials: credentials);
        return (new JwtSecurityTokenHandler().WriteToken(token), expiresAt);
    }

    public static string NewRefreshToken() => Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
    public static string HashRefreshToken(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
    public string Issuer => _issuer;
    public string Audience => _audience;
    public SymmetricSecurityKey SigningKey => new(_key);

    public static void ValidateConfiguration(IConfiguration configuration)
    {
        _ = ReadIssuer(configuration);
        _ = ReadAudience(configuration);
        _ = ReadKey(configuration);
    }

    private static string ReadIssuer(IConfiguration configuration)
    {
        var issuer = configuration["Jwt:Issuer"];
        if (string.IsNullOrWhiteSpace(issuer))
            throw new InvalidOperationException("Jwt:Issuer must be supplied through the environment.");
        return issuer;
    }

    private static string ReadAudience(IConfiguration configuration)
    {
        var audience = configuration["Jwt:Audience"];
        if (string.IsNullOrWhiteSpace(audience))
            throw new InvalidOperationException("Jwt:Audience must be supplied through the environment.");
        return audience;
    }

    private static byte[] ReadKey(IConfiguration configuration)
    {
        var key = configuration["Jwt:SigningKey"];
        // HS512 requires a 512-bit symmetric key. Fail at startup instead of
        // accepting a key that will break only when the first token is issued.
        if (string.IsNullOrWhiteSpace(key) || Encoding.UTF8.GetByteCount(key) < 64)
            throw new InvalidOperationException("Jwt:SigningKey must have at least 64 bytes for HS512 and must be supplied through the environment.");
        return Encoding.UTF8.GetBytes(key);
    }
}
