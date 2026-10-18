using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VeroEqulibraFit.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddFoodProductCatalog : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "food_products",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerId = table.Column<Guid>(type: "uuid", nullable: true),
                    Name = table.Column<string>(type: "character varying(240)", maxLength: 240, nullable: false),
                    Brand = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: true),
                    Gtin = table.Column<string>(type: "character varying(14)", maxLength: 14, nullable: false),
                    ReferenceQuantity = table.Column<decimal>(type: "numeric", nullable: false),
                    ReferenceUnit = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    Calories = table.Column<decimal>(type: "numeric", nullable: true),
                    ProteinGrams = table.Column<decimal>(type: "numeric", nullable: true),
                    CarbohydrateGrams = table.Column<decimal>(type: "numeric", nullable: true),
                    FatGrams = table.Column<decimal>(type: "numeric", nullable: true),
                    FiberGrams = table.Column<decimal>(type: "numeric", nullable: true),
                    Source = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    IsApprovedCatalogItem = table.Column<bool>(type: "boolean", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_food_products", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_food_products_Gtin_IsApprovedCatalogItem",
                table: "food_products",
                columns: new[] { "Gtin", "IsApprovedCatalogItem" });

            migrationBuilder.CreateIndex(
                name: "IX_food_products_OwnerId_Gtin",
                table: "food_products",
                columns: new[] { "OwnerId", "Gtin" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "food_products");
        }
    }
}
