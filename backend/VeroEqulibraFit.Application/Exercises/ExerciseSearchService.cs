using System.Globalization;
using System.Text;
using VeroEqulibraFit.Contracts.Exercises;
using VeroEqulibraFit.Domain.Exercises;
namespace VeroEqulibraFit.Application.Exercises;
public sealed class ExerciseSearchService
{
    private static readonly IReadOnlyList<Exercise> Catalog = new[] { new Exercise("incline-dumbbell", "Supino inclinado com halteres", "Peito", [], ["Halteres", "Banco inclinado"], true), new Exercise("squat", "Agachamento com barra", "Pernas", ["Agachamento livre"], ["Barra"], true), new Exercise("leg-press", "Leg press", "Pernas", [], ["Máquina"], true), new Exercise("lat-pulldown", "Puxada frontal", "Costas", [], ["Máquina"], true), new Exercise("biceps-curl", "Rosca direta", "Bíceps", [], ["Barra"], true) };
    public ExerciseSuggestionResponse SearchBeforeAi(ExerciseSuggestionRequest request)
    { var query = Normalize(request.Query); var match = Catalog.FirstOrDefault(e => Normalize(e.Name).Contains(query, StringComparison.Ordinal) || e.Aliases.Any(a => Normalize(a).Contains(query, StringComparison.Ordinal))); return match is null ? new("needs_clarification", null, null, [], null, [], null, null, [], [], [], [], true) : new("existing_match", match.Id, match.Name, match.Aliases, match.PrimaryMuscle, [], match.Equipment.FirstOrDefault(), null, [], [], [], [], true); }
    private static string Normalize(string value) { var d = value.Normalize(NormalizationForm.FormD); return string.Concat(d.Where(ch => CharUnicodeInfo.GetUnicodeCategory(ch) != UnicodeCategory.NonSpacingMark)).ToLowerInvariant().Trim(); }
}
