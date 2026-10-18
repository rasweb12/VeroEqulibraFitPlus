using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.DataProtection.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using VeroEqulibraFit.Domain.Training;
using VeroEqulibraFit.Domain.Nutrition;

namespace VeroEqulibraFit.Infrastructure.Data;

public sealed class VeroEqulibraFitDbContext(DbContextOptions<VeroEqulibraFitDbContext> options) : IdentityDbContext<AppUser, AppRole, Guid>(options), IDataProtectionKeyContext
{
    public DbSet<DataProtectionKey> DataProtectionKeys { get; set; } = null!;
    public DbSet<TrainingPlan> TrainingPlans => Set<TrainingPlan>();
    public DbSet<TrainingPlanExercise> TrainingPlanExercises => Set<TrainingPlanExercise>();
    public DbSet<TrainingSession> TrainingSessions => Set<TrainingSession>();
    public DbSet<CustomExercise> CustomExercises => Set<CustomExercise>();
    public DbSet<SyncOperation> SyncOperations => Set<SyncOperation>();
    public DbSet<MealEntry> MealEntries => Set<MealEntry>();
    public DbSet<NutritionPlan> NutritionPlans => Set<NutritionPlan>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.Entity<DataProtectionKey>().ToTable("data_protection_keys");
        modelBuilder.Entity<AppUser>(entity =>
        {
            entity.ToTable("users");
            entity.Property(user => user.DisplayName).HasMaxLength(120);
        });
        modelBuilder.Entity<AppRole>().ToTable("roles");
        modelBuilder.Entity<Microsoft.AspNetCore.Identity.IdentityUserRole<Guid>>().ToTable("user_roles");
        modelBuilder.Entity<Microsoft.AspNetCore.Identity.IdentityUserClaim<Guid>>().ToTable("user_claims");
        modelBuilder.Entity<Microsoft.AspNetCore.Identity.IdentityUserLogin<Guid>>().ToTable("user_logins");
        modelBuilder.Entity<Microsoft.AspNetCore.Identity.IdentityUserToken<Guid>>().ToTable("user_tokens");
        modelBuilder.Entity<Microsoft.AspNetCore.Identity.IdentityRoleClaim<Guid>>().ToTable("role_claims");
        modelBuilder.Entity<RefreshToken>(entity =>
        {
            entity.ToTable("refresh_tokens");
            entity.HasKey(token => token.Id);
            entity.Property(token => token.TokenHash).HasMaxLength(128).IsRequired();
            entity.HasIndex(token => token.TokenHash).IsUnique();
            entity.HasIndex(token => new { token.UserId, token.ExpiresAt });
        });
        modelBuilder.Entity<TrainingPlan>(entity =>
        {
            entity.ToTable("training_plans");
            entity.HasKey(plan => plan.Id);
            entity.Property(plan => plan.Name).HasMaxLength(160).IsRequired();
            entity.Property(plan => plan.Objective).HasMaxLength(500).IsRequired();
            entity.Property(plan => plan.Revision).HasDefaultValue(1);
            entity.Property(plan => plan.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.HasIndex(plan => new { plan.OwnerId, plan.DeletedAt });
            entity.HasIndex(plan => new { plan.OwnerId, plan.UpdatedAt });
            entity.HasQueryFilter(plan => plan.DeletedAt == null);
            entity.HasMany(plan => plan.Exercises).WithOne().HasForeignKey(exercise => exercise.TrainingPlanId).OnDelete(DeleteBehavior.Cascade);
        });
        modelBuilder.Entity<TrainingPlanExercise>(entity =>
        {
            entity.ToTable("training_plan_exercises");
            entity.Property(exercise => exercise.ExerciseId).HasMaxLength(120).IsRequired();
            entity.Property(exercise => exercise.Repetitions).HasMaxLength(32).IsRequired();
            entity.Property(exercise => exercise.Notes).HasMaxLength(2000);
            entity.HasIndex(exercise => new { exercise.TrainingPlanId, exercise.Position }).IsUnique();
        });
        modelBuilder.Entity<TrainingSession>(entity =>
        {
            entity.ToTable("training_sessions");
            entity.Property(session => session.SnapshotJson).HasColumnType("jsonb").IsRequired();
            entity.HasIndex(session => new { session.OwnerId, session.FinishedAt });
        });
        modelBuilder.Entity<CustomExercise>(entity =>
        {
            entity.ToTable("custom_exercises");
            entity.Property(exercise => exercise.Name).HasMaxLength(160).IsRequired();
            entity.Property(exercise => exercise.PrimaryMuscle).HasMaxLength(80).IsRequired();
            entity.Property(exercise => exercise.Equipment).HasMaxLength(80).IsRequired();
            entity.Property(exercise => exercise.Revision).HasDefaultValue(1);
            entity.Property(exercise => exercise.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.HasIndex(exercise => new { exercise.OwnerId, exercise.UpdatedAt });
            entity.HasQueryFilter(exercise => exercise.DeletedAt == null);
        });
        modelBuilder.Entity<SyncOperation>(entity =>
        {
            entity.ToTable("sync_operations");
            entity.Property(operation => operation.IdempotencyKey).HasMaxLength(128).IsRequired();
            entity.Property(operation => operation.OperationType).HasMaxLength(80).IsRequired();
            entity.Property(operation => operation.PayloadHash).HasMaxLength(128).IsRequired();
            entity.HasIndex(operation => new { operation.OwnerId, operation.IdempotencyKey }).IsUnique();
        });
        modelBuilder.Entity<MealEntry>(entity =>
        {
            entity.ToTable("meal_entries");
            entity.Property(meal => meal.Description).HasMaxLength(1000).IsRequired();
            entity.Property(meal => meal.Revision).HasDefaultValue(1);
            entity.Property(meal => meal.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.HasIndex(meal => new { meal.OwnerId, meal.ConsumedAt });
            entity.HasIndex(meal => new { meal.OwnerId, meal.UpdatedAt });
            entity.HasQueryFilter(meal => meal.DeletedAt == null);
        });
        modelBuilder.Entity<NutritionPlan>(entity =>
        {
            entity.ToTable("nutrition_plans");
            entity.Property(plan => plan.Name).HasMaxLength(160).IsRequired();
            entity.Property(plan => plan.ContentJson).HasColumnType("jsonb").IsRequired();
            entity.HasIndex(plan => new { plan.OwnerId, plan.DeletedAt });
            entity.HasQueryFilter(plan => plan.DeletedAt == null);
        });
    }
}
