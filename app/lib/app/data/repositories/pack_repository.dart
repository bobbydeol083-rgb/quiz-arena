import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/models.dart';
import '../providers/api_service.dart';

/// Game Packs repository: browse/publish community packs and keep installed
/// packs cached locally so they stay playable offline.
class PackRepository {
  final ApiService api;
  final GetStorage box;

  static const String _kInstalled = 'installed_packs';

  final RxBool offline = false.obs;

  PackRepository({required this.api, GetStorage? box})
      : box = box ?? GetStorage();

  Future<List<GamePack>> browse({
    String? search,
    String? mode,
    String sort = 'popular',
  }) async {
    try {
      final json = await api.packsBrowse(search: search, mode: mode, sort: sort);
      offline.value = false;
      final list = (json['packs'] as List?) ?? const [];
      return list
          .map((e) => GamePack.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on ApiException catch (e) {
      if (!e.isNetworkError) rethrow;
      offline.value = true;
      return installedPacks().map((d) => d as GamePack).toList();
    }
  }

  Future<GamePackDetail> detail(String id) async {
    final json = await api.packDetail(id);
    return GamePackDetail.fromJson(json);
  }

  Future<List<GamePack>> myPacks() async {
    final json = await api.packsMine();
    final list = (json['packs'] as List?) ?? const [];
    return list
        .map((e) => GamePack.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<GamePackDetail> create({
    required String title,
    String description = '',
    String label = 'Custom',
    String mode = 'quiz',
    required List<Map<String, dynamic>> questions,
  }) async {
    final json = await api.packCreate({
      'title': title,
      'description': description,
      'label': label,
      'mode': mode,
      'questions': questions,
    });
    return GamePackDetail.fromJson(json);
  }

  Future<GamePackDetail> publish(String id) async {
    final json = await api.packPublish(id);
    return GamePackDetail.fromJson(json);
  }

  Future<GamePackDetail> unpublish(String id) async {
    final json = await api.packUnpublish(id);
    return GamePackDetail.fromJson(json);
  }

  Future<void> delete(String id) => api.packDelete(id);

  /// Install = download the full pack (with answers) and cache it locally.
  Future<GamePackDetail> install(String id) async {
    final json = await api.packInstall(id);
    final detail = GamePackDetail.fromJson(json);
    final all = Map<String, dynamic>.from(box.read(_kInstalled) ?? {});
    all[detail.id] = detail.toJson();
    await box.write(_kInstalled, all);
    return detail;
  }

  List<GamePackDetail> installedPacks() {
    final all = Map<String, dynamic>.from(box.read(_kInstalled) ?? {});
    return all.values
        .map((e) => GamePackDetail.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  GamePackDetail? installedPack(String id) {
    final all = Map<String, dynamic>.from(box.read(_kInstalled) ?? {});
    final raw = all[id];
    if (raw == null) return null;
    return GamePackDetail.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> uninstall(String id) async {
    final all = Map<String, dynamic>.from(box.read(_kInstalled) ?? {});
    all.remove(id);
    await box.write(_kInstalled, all);
  }

  Future<void> markPlayed(String id) => api.packPlayed(id);
}
