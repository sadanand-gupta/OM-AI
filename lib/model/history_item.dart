class HistoryItem {
  final String id;
  final String title;
  final String description;
  final String time;

  HistoryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final first = json["first_exchange"] ?? {};

    return HistoryItem(
      id: json["session_id"] ?? "",
      title: first["user_message"] ?? "Untitled Chat",
      description: first["assistant_message"] ?? "",
      time: json["created_at"] ?? "",
    );
  }
}
