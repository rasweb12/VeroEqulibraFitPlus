using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VeroEqulibraFit.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddSyncRecordVersions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Revision",
                table: "training_plans",
                type: "integer",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "UpdatedAt",
                table: "training_plans",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.AddColumn<int>(
                name: "Revision",
                table: "meal_entries",
                type: "integer",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "UpdatedAt",
                table: "meal_entries",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "CURRENT_TIMESTAMP");

            migrationBuilder.CreateIndex(
                name: "IX_training_plans_OwnerId_UpdatedAt",
                table: "training_plans",
                columns: new[] { "OwnerId", "UpdatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_meal_entries_OwnerId_UpdatedAt",
                table: "meal_entries",
                columns: new[] { "OwnerId", "UpdatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_training_plans_OwnerId_UpdatedAt",
                table: "training_plans");

            migrationBuilder.DropIndex(
                name: "IX_meal_entries_OwnerId_UpdatedAt",
                table: "meal_entries");

            migrationBuilder.DropColumn(
                name: "Revision",
                table: "training_plans");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "training_plans");

            migrationBuilder.DropColumn(
                name: "Revision",
                table: "meal_entries");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "meal_entries");
        }
    }
}
