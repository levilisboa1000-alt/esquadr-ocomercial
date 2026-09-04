abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Ocorreu um erro no servidor. Tente novamente.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Credenciais inválidas ou erro na autenticação.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet. Verifique sua rede.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Você não possui permissão para executar esta ação.']);
}

class GoogleCalendarFailure extends Failure {
  const GoogleCalendarFailure([super.message = 'Erro ao sincronizar com Google Calendar.']);
}

class CallIntegrationFailure extends Failure {
  const CallIntegrationFailure([super.message = 'Não foi possível acionar o discador nativo.']);
}
