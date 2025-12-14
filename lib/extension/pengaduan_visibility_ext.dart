import 'package:flutter/material.dart';
import '../../models/pengaduan.dart';



extension PengaduanVisibilityExt on PengaduanVisibility {
  String get label {
    switch (this) {
      case PengaduanVisibility.publik:
        return 'PUBLIC';
      case PengaduanVisibility.privat:
        return 'PRIVATE';
    }
  }

  Color get color {
    switch (this) {
      case PengaduanVisibility.publik:
        return Colors.green;
      case PengaduanVisibility.privat:
        return Colors.orange;
    }
  }

  String get value {
    // untuk disimpan ke Firebase
    return name; // 'public' / 'private'
  }

  static PengaduanVisibility fromString(String value) {
    return PengaduanVisibility.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PengaduanVisibility.publik,
    );
  }
}
