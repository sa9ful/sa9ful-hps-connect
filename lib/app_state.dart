import 'package:material_ui/material_ui.dart';

import 'data/backend.dart';
import 'models/user_role.dart';

/// সারা অ্যাপে ব্যাকএন্ড ও বেছে নেওয়া রোল পৌঁছে দেয়।
class AppState extends ChangeNotifier {
  AppState(this.backend);

  final Backend backend;
  UserRole? _activeRole;

  UserRole? get activeRole => _activeRole;

  void selectRole(UserRole? role) {
    _activeRole = role;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static Backend backendOf(BuildContext context) => of(context).backend;
}
