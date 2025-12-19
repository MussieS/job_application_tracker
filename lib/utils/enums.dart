enum AppStatus { applied, oa, interview, offer, rejected, archived }

enum TaskType { followup, interviewPrep, assessment, network, custom }

enum Priority { low, medium, high }

String enumToString(Object e) => e.toString().split('.').last;

T enumFromString<T>(List<T> values, String s, T fallback) {
  for (final v in values) {
    if (enumToString(v as Object) == s) return v;
  }
  return fallback;
}
