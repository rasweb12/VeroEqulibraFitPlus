using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VeroEqulibraFit.Contracts.Nutrition;
using VeroEqulibraFit.Domain.Nutrition;
using VeroEqulibraFit.Infrastructure.Data;

namespace VeroEqulibraFit.Api.Controllers;

[ApiController, Authorize, Route("api/v1/foods")]
public sealed class FoodsController(VeroEqulibraFitDbContext database) : ControllerBase
{
    [HttpGet("barcode/{gtin}")]
    public async Task<ActionResult<FoodProductResponse>> Lookup(string gtin, CancellationToken cancellationToken)
    {
        if (!IsGtin(gtin) || GetOwnerId() is not { } ownerId) return BadRequest();
        var product = await database.FoodProducts.AsNoTracking()
            .Where(item => item.Gtin == gtin && (item.IsApprovedCatalogItem || item.OwnerId == ownerId))
            .OrderByDescending(item => item.OwnerId == ownerId)
            .FirstOrDefaultAsync(cancellationToken);
        return product is null ? NotFound() : Ok(ToResponse(product));
    }

    [HttpPost("private")]
    public async Task<ActionResult<FoodProductResponse>> CreatePrivate(CreateFoodProductRequest request, CancellationToken cancellationToken)
    {
        if (GetOwnerId() is not { } ownerId || !IsGtin(request.Gtin) || string.IsNullOrWhiteSpace(request.Name) || request.Name.Length > 240 || request.ReferenceQuantity <= 0 || string.IsNullOrWhiteSpace(request.ReferenceUnit) || string.IsNullOrWhiteSpace(request.Source) || new[] { request.Calories, request.ProteinGrams, request.CarbohydrateGrams, request.FatGrams, request.FiberGrams }.Any(value => value is < 0)) return BadRequest();
        var product = new FoodProduct { OwnerId = ownerId, Name = request.Name.Trim(), Brand = request.Brand?.Trim(), Gtin = request.Gtin, ReferenceQuantity = request.ReferenceQuantity, ReferenceUnit = request.ReferenceUnit.Trim(), Calories = request.Calories, ProteinGrams = request.ProteinGrams, CarbohydrateGrams = request.CarbohydrateGrams, FatGrams = request.FatGrams, FiberGrams = request.FiberGrams, Source = request.Source.Trim() };
        database.FoodProducts.Add(product);
        await database.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(Lookup), new { gtin = product.Gtin }, ToResponse(product));
    }

    private Guid? GetOwnerId() => Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub"), out var id) ? id : null;
    private static bool IsGtin(string value) => value.Length is 8 or 12 or 13 or 14 && value.All(char.IsDigit);
    private static FoodProductResponse ToResponse(FoodProduct value) => new(value.Id, value.Name, value.Brand, value.Gtin, value.ReferenceQuantity, value.ReferenceUnit, value.Calories, value.ProteinGrams, value.CarbohydrateGrams, value.FatGrams, value.FiberGrams, value.Source, value.UpdatedAt);
}
