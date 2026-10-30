using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VeroEqulibraFit.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddAdminExerciseCatalog : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "exercise_catalog_items",
                columns: table => new
                {
                    Id = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Name = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    PrimaryMuscle = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    Equipment = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    Instructions = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: false),
                    IsPublished = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_exercise_catalog_items", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "exercise_catalog_media",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ExerciseId = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    AssetPath = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: false),
                    Label = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: true),
                    IsPrimary = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_exercise_catalog_media", x => x.Id);
                    table.ForeignKey(
                        name: "FK_exercise_catalog_media_exercise_catalog_items_ExerciseId",
                        column: x => x.ExerciseId,
                        principalTable: "exercise_catalog_items",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_exercise_catalog_items_IsPublished_Name",
                table: "exercise_catalog_items",
                columns: new[] { "IsPublished", "Name" });

            migrationBuilder.CreateIndex(
                name: "IX_exercise_catalog_media_AssetPath",
                table: "exercise_catalog_media",
                column: "AssetPath",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_exercise_catalog_media_ExerciseId_IsPrimary",
                table: "exercise_catalog_media",
                columns: new[] { "ExerciseId", "IsPrimary" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "exercise_catalog_media");

            migrationBuilder.DropTable(
                name: "exercise_catalog_items");
        }
    }
}
