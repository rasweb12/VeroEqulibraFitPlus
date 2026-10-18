using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VeroEqulibraFit.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddJournalRecordSync : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "journal_records",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerId = table.Column<Guid>(type: "uuid", nullable: false),
                    Kind = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    OccurredAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    PayloadJson = table.Column<string>(type: "jsonb", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    Revision = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    DeletedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_journal_records", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_journal_records_OwnerId_Kind_OccurredAt",
                table: "journal_records",
                columns: new[] { "OwnerId", "Kind", "OccurredAt" });

            migrationBuilder.CreateIndex(
                name: "IX_journal_records_OwnerId_UpdatedAt",
                table: "journal_records",
                columns: new[] { "OwnerId", "UpdatedAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "journal_records");
        }
    }
}
