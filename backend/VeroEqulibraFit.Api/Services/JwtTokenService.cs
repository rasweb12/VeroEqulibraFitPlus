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
    private readonly string _issuer = configuration["Jwt:Issuer"] ?? "vero-equilibrafit-api";
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
        var token = new JwtSecurityToken(_issuer, _issuer, claims, expires: expiresAt.UtcDateTime, signingCredentials: credentials);
        return (new JwtSecurityTokenHandler().WriteToken(token), expiresAt);
    }

    public static string NewRefreshToken() => Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
    public static string HashRefreshToken(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
    public string Issuer => _issuer;
    public SymmetricSecurityKey SigningKey => new(_key);

    private static byte[] ReadKey(IConfiguration configuration)
    {
        var key = configuration["Jwt:SigningKey"];
        if (string.IsNullOrWhiteSpace(key) || Encoding.UTF8.GetByteCount(key) < 32)
            throw new InvalidOperationException("Jwt:SigningKey must have at least 32 bytes and must be supplied through the environment.");
        return Encoding.UTF8.GetBytes(key);
    }
}
