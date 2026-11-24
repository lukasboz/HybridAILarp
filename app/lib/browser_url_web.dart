import 'package:web/web.dart' as web;

/// Removes a consumed `?invite=` so reloading doesn't reopen the join dialog.
void forgetInvitationInAddressBar() {
  final location = web.window.location;
  final params =
      Map.of(Uri.splitQueryString(location.search.replaceFirst('?', '')))
        ..remove('invite')
        ..remove('friend')
        ..remove('room');
  final query = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
  web.window.history.replaceState(
    null,
    '',
    '${location.pathname}$query${location.hash}',
  );
}
