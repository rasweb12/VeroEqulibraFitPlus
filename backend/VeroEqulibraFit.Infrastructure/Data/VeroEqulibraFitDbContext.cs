using Microsoft.EntityFrameworkCore;
using VeroEqulibraFit.Domain.Training;

namespace VeroEqulibraFit.Infrastructure.Data;

public sealed class VeroEqulibraFitDbContext(DbContextOptions<VeroEqulibraFitDbContext> options) : DbContext(options)
{
    public DbSet<TrainingPlan> TrainingPlans => Set<TrainingPlan>();
    public DbSet<TrainingPlanExercise> TrainingPlanExercises => Set<TrainingPlanExercise>();
    public DbSet<TrainingSession> TrainingSessions => Set<TrainingSession>();
    public DbSet<SyncOperation> SyncOperations => Set<SyncOperation>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<TrainingPlan>(entity =>
        {
            entity.ToTable("training_plans");
            entity.HasKey(plan => plan.Id);
            entity.Property(plan => plan.Name).HasMaxLength(160).IsRequired();
            entity.Property(plan => plan.Objective).HasMaxLength(500).IsRequired();
            entity.HasIndex(plan => new { plan.OwnerId, plan.DeletedAt });
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
        modelBuilder.Entity<SyncOperation>(entity =>
        {
            entity.ToTable("sync_operations");
            entity.Property(operation => operation.IdempotencyKey).HasMaxLength(128).IsRequired();
            entity.Property(operation => operation.OperationType).HasMaxLength(80).IsRequired();
            entity.Property(operation => operation.PayloadHash).HasMaxLength(128).IsRequired();
            entity.HasIndex(operation => new { operation.OwnerId, operation.IdempotencyKey }).IsUnique();
        });
    }
}
