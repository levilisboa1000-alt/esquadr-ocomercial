enum UserRole {
  admin('admin', 'Administrador'),
  supervisor('supervisor', 'Supervisor'),
  operator('operator', 'Operador');

  final String dbValue;
  final String label;
  const UserRole(this.dbValue, this.label);

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.dbValue == value?.toLowerCase(),
      orElse: () => UserRole.operator,
    );
  }
}

enum LeadStatus {
  novo('NOVO', 'Novo'),
  distribuido('DISTRIBUIDO', 'Distribuído'),
  emAtendimento('EM_ATENDIMENTO', 'Em Atendimento'),
  ligacaoRealizada('LIGACAO_REALIZADA', 'Ligação Realizada'),
  caixaPostal('CAIXA_POSTAL', 'Caixa Postal'),
  agendado('AGENDADO', 'Agendado'),
  confirmado('CONFIRMADO', 'Confirmado'),
  atendido('ATENDIDO', 'Atendido'),
  naoInteressado('NAO_INTERESSADO', 'Não Interessado'),
  retornarParaFila('RETORNAR_PARA_FILA', 'Retornar p/ Fila'),
  finalizado('FINALIZADO', 'Finalizado'),
  cancelado('CANCELADO', 'Cancelado');

  final String dbValue;
  final String label;
  const LeadStatus(this.dbValue, this.label);

  static LeadStatus fromString(String? value) {
    return LeadStatus.values.firstWhere(
      (e) => e.dbValue == value?.toUpperCase(),
      orElse: () => LeadStatus.novo,
    );
  }
}

enum LeadPriority {
  baixa('baixa', 'Baixa'),
  normal('normal', 'Normal'),
  alta('alta', 'Alta'),
  urgente('urgente', 'Urgente');

  final String dbValue;
  final String label;
  const LeadPriority(this.dbValue, this.label);

  static LeadPriority fromString(String? value) {
    return LeadPriority.values.firstWhere(
      (e) => e.dbValue == value?.toLowerCase(),
      orElse: () => LeadPriority.normal,
    );
  }
}

enum CallResult {
  atendeu('atendeu', 'Atendeu'),
  naoAtendeu('nao_atendeu', 'Não Atendeu'),
  caixaPostal('caixa_postal', 'Caixa Postal'),
  numeroInvalido('numero_invalido', 'Número Inválido'),
  retornarDepois('retornar_depois', 'Retornar Depois'),
  interessado('interessado', 'Interessado'),
  naoInteressado('nao_interessado', 'Não Interessado'),
  agendamento('agendamento', 'Agendamento Realizado');

  final String dbValue;
  final String label;
  const CallResult(this.dbValue, this.label);

  static CallResult fromString(String? value) {
    return CallResult.values.firstWhere(
      (e) => e.dbValue == value?.toLowerCase(),
      orElse: () => CallResult.atendeu,
    );
  }
}

enum AppointmentStatus {
  agendado('AGENDADO', 'Agendado'),
  vinteQuatroHoras('24_HORAS', 'Acompanhamento 24h'),
  confirmado('CONFIRMADO', 'Confirmado'),
  emAtendimento('EM_ATENDIMENTO', 'Em Atendimento'),
  atendido('ATENDIDO', 'Atendido'),
  naoCompareceu('NAO_COMPARECEU', 'Não Compareceu'),
  cancelado('CANCELADO', 'Cancelado'),
  retornouParaLead('RETORNOU_PARA_LEAD', 'Retornou p/ Lead'),
  finalizado('FINALIZADO', 'Finalizado');

  final String dbValue;
  final String label;
  const AppointmentStatus(this.dbValue, this.label);

  static AppointmentStatus fromString(String? value) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.dbValue == value?.toUpperCase(),
      orElse: () => AppointmentStatus.agendado,
    );
  }
}

enum SwipeAction {
  callRight('LIGAR'),
  scheduleUp('AGENDAR'),
  voicemailLeft('CAIXA POSTAL'),
  rejectDown('NÃO INTERESSADO');

  final String label;
  const SwipeAction(this.label);
}
