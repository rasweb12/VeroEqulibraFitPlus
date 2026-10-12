using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VeroEqulibraFit.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class InitialTrainingFoundation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "sync_operations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerId = table.Column<Guid>(type: "uuid", nullable: false),
                    IdempotencyKey = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    OperationType = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    PayloadHash = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_sync_operations", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "training_plans",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    Objective = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    DeletedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_training_plans", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "training_sessions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerId = table.Column<Guid>(type: "uuid", nullable: false),
                    TrainingPlanId = table.Column<Guid>(type: "uuid", nullable: false),
                    StartedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    FinishedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    SnapshotJson = table.Column<string>(type: "jsonb", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_training_sessions", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "training_plan_exercises",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TrainingPlanId = table.Column<Guid>(type: "uuid", nullable: false),
                    ExerciseId = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Position = table.Column<int>(type: "integer", nullable: false),
                    Sets = table.Column<int>(type: "integer", nullable: false),
                    Repetitions = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    TargetLoadKg = table.Column<decimal>(type: "numeric", nullable: true),
                    RestSeconds = table.Column<int>(type: "integer", nullable: false),
                    Notes = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_training_plan_exercises", x => x.Id);
                    table.ForeignKey(
                        name: "FK_training_plan_exercises_training_plans_TrainingPlanId",
                        column: x => x.TrainingPlanId,
                        principalTable: "training_plans",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_sync_operations_OwnerId_IdempotencyKey",
                table: "sync_operations",
                columns: new[] { "OwnerId", "IdempotencyKey" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_training_plan_exercises_TrainingPlanId_Position",
                table: "training_plan_exercises",
                columns: new[] { "TrainingPlanId", "Position" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_training_plans_OwnerId_DeletedAt",
                table: "training_plans",
                columns: new[] { "OwnerId", "DeletedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_training_sessions_OwnerId_FinishedAt",
                table: "training_sessions",
                columns: new[] { "OwnerId", "FinishedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "sync_operations");

            migrationBuilder.DropTable(
                name: "training_plan_exercises");

            migrationBuilder.DropTable(
                name: "training_sessions");

            migrationBuilder.DropTable(
                name: "training_plans");
        }
    }
}
