import 'package:ondam_core/ondam_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/repositories/dialer_repository.dart';

class DialerRepositoryImpl implements DialerRepository {
  const DialerRepositoryImpl();

  @override
  Future<Result<void>> call(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        return const Err(UnavailableFailure('전화 앱을 열 수 없어요.'));
      }
      return const Ok(null);
    } on Object {
      return const Err(UnavailableFailure('전화 앱을 열 수 없어요.'));
    }
  }
}
