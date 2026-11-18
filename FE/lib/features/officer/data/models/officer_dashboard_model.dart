class OfficerDashboardModel {
  const OfficerDashboardModel({
    required this.queue,
    required this.mine,
    required this.urgent,
    required this.overdue,
    required this.completed,
  });

  final int queue;
  final int mine;
  final int urgent;
  final int overdue;
  final int completed;

  factory OfficerDashboardModel.fromJson(Map<String, dynamic> json) {
    int value(String key) => int.tryParse('${json[key] ?? 0}') ?? 0;
    return OfficerDashboardModel(
      queue: value('queue'),
      mine: value('mine'),
      urgent: value('urgent'),
      overdue: value('overdue'),
      completed: value('completed'),
    );
  }
}
