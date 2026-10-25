using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VeroEqulibraFit.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddAdminUserManagementAudit : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "RegisteredAt",
                table: "users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "admin_audit_events",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ActorUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    TargetUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    Action = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Result = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    Reason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    OccurredAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_admin_audit_events", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_users_RegisteredAt",
                table: "users",
                column: "RegisteredAt");

            migrationBuilder.CreateIndex(
                name: "IX_admin_audit_events_ActorUserId_OccurredAt",
                table: "admin_audit_events",
                columns: new[] { "ActorUserId", "OccurredAt" });

            migrationBuilder.CreateIndex(
                name: "IX_admin_audit_events_TargetUserId_OccurredAt",
                table: "admin_audit_events",
                columns: new[] { "TargetUserId", "OccurredAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "admin_audit_events");

            migrationBuilder.DropIndex(
                name: "IX_users_RegisteredAt",
                table: "users");

            migrationBuilder.DropColumn(
                name: "RegisteredAt",
                table: "users");
        }
    }
}
