using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VeroEqulibraFit.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddNutritionFoundation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "meal_entries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerId = table.Column<Guid>(type: "uuid", nullable: false),
                    Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    ConsumedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    EstimatedCalories = table.Column<decimal>(type: "numeric", nullable: true),
                    ProteinGrams = table.Column<decimal>(type: "numeric", nullable: true),
                    CarbohydrateGrams = table.Column<decimal>(type: "numeric", nullable: true),
                    FatGrams = table.Column<decimal>(type: "numeric", nullable: true),
                    RequiresUserReview = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_meal_entries", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "nutrition_plans",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    ContentJson = table.Column<string>(type: "jsonb", nullable: false),
                    IsAiGenerated = table.Column<bool>(type: "boolean", nullable: false),
                    IsApprovedByUser = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    ArchivedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    DeletedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_nutrition_plans", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_meal_entries_OwnerId_ConsumedAt",
                table: "meal_entries",
                columns: new[] { "OwnerId", "ConsumedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_nutrition_plans_OwnerId_DeletedAt",
                table: "nutrition_plans",
                columns: new[] { "OwnerId", "DeletedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "meal_entries");

            migrationBuilder.DropTable(
                name: "nutrition_plans");
        }
    }
}
