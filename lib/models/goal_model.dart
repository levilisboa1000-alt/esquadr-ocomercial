class OperatorProductivityModel {
  final String operatorId;
  final String operatorName;
  final int leadsReceived;
  final int leadsProcessed;
  final int callsMade;
  final int callsAnswered;
  final int voicemailCount;
  final int rejectedCount;
  final int appointmentsCreated;
  final double conversionRate; // (appointments / leadsProcessed) * 100
  final bool isOnline;

  OperatorProductivityModel({
    required this.operatorId,
    required this.operatorName,
    this.leadsReceived = 0,
    this.leadsProcessed = 0,
    this.callsMade = 0,
    this.callsAnswered = 0,
    this.voicemailCount = 0,
    this.rejectedCount = 0,
    this.appointmentsCreated = 0,
    this.conversionRate = 0.0,
    this.isOnline = false,
  });

  factory OperatorProductivityModel.fromCalculated({
    required String operatorId,
    required String operatorName,
    required int leadsReceived,
    required int leadsProcessed,
    required int callsMade,
    required int callsAnswered,
    required int voicemailCount,
    required int rejectedCount,
    required int appointmentsCreated,
    bool isOnline = false,
  }) {
    final rate = leadsProcessed > 0
        ? (appointmentsCreated / leadsProcessed) * 100.0
        : 0.0;
    return OperatorProductivityModel(
      operatorId: operatorId,
      operatorName: operatorName,
      leadsReceived: leadsReceived,
      leadsProcessed: leadsProcessed,
      callsMade: callsMade,
      callsAnswered: callsAnswered,
      voicemailCount: voicemailCount,
      rejectedCount: rejectedCount,
      appointmentsCreated: appointmentsCreated,
      conversionRate: double.parse(rate.toStringAsFixed(1)),
      isOnline: isOnline,
    );
  }
}
