using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using ApartmentRental.Api.Models;
using Microsoft.IdentityModel.Tokens;

namespace ApartmentRental.Api.Services;

public class TokenService(IConfiguration configuration)
{
    public string CreateToken(AppUser user)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Name, user.Email),
            new(ClaimTypes.Email, user.Email),
            new("display_name", user.DisplayName),
            new(ClaimTypes.Role, user.Role.ToString())
        };
        if (user.TenantId.HasValue) claims.Add(new Claim("tenant_id", user.TenantId.Value.ToString()));
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(configuration["Jwt:Key"] ?? "development-only-change-this-secret-please"));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: configuration["Jwt:Issuer"] ?? "ApartmentRental.Api",
            audience: configuration["Jwt:Audience"] ?? "ApartmentRental.Client",
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: credentials);
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
