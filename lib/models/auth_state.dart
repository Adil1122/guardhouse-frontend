enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating,
}

class AuthState {
  final AuthStatus status;
  final String? error;

  AuthState({required this.status, this.error});

  factory AuthState.uninitialized() =>
      AuthState(status: AuthStatus.uninitialized);

  factory AuthState.authenticated() =>
      AuthState(status: AuthStatus.authenticated);

  factory AuthState.unauthenticated() =>
      AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.authenticating() =>
      AuthState(status: AuthStatus.authenticating);

  AuthState copyWith({AuthStatus? status, String? error}) {
    return AuthState(status: status ?? this.status, error: error ?? this.error);
  }
}
